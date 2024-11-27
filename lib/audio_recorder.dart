import 'dart:io';
import 'dart:convert';
import 'package:avaguard/resources/firestore_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AudioRecord {
  final _recorder = AudioRecorder();
  static final ValueNotifier<bool> isRecording = ValueNotifier<bool>(false);
  final FirebaseStorageService _storageService = FirebaseStorageService();
  String? _recordingId;
  String? _firebaseUrl;

  // Inicia a gravação
  Future<void> startRecording(String userId) async {
    if (await _recorder.hasPermission() && userId.isNotEmpty) {
      final initResponse = await http.post(
        Uri.parse('https://avaguard-api.vercel.app/initEmployeesRecording'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (initResponse.statusCode == 201) {
        final responseBody = jsonDecode(initResponse.body);
        _recordingId =
            responseBody['employeesRecording']['employeesRecordingId'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.remove('recordingId');
        prefs.setString('recordingId', _recordingId!);
        print("Gravação iniciada no backend com ID: $_recordingId");

        final Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          print("Erro ao obter o diretório externo.");
          return;
        }

        final String filePath =
            '${externalDir.path}/audios/audio_${DateTime.now().millisecondsSinceEpoch}_$userId.m4a';

        // Certifique-se de que o diretório existe
        await Directory('${externalDir.path}/audios').create(recursive: true);

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 44100,
            bitRate: 128000,
          ),
          path: filePath,
        );
        prefs.remove('filePath');
        prefs.setString('filePath', filePath);
        isRecording.value = true;
        print("Gravação local iniciada: $filePath");
      } else {
        print("Erro ao iniciar a gravação no backend: ${initResponse.body}");
      }
    } else {
      print("Permissão para gravar negada!");
    }
  }

  @override
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  // Para a gravação
  Future<String?> stopRecording() async {
    if (!isRecording.value) {
      print("Nenhuma gravação em andamento.");
      return null;
    }

    final String? path = await _recorder.stop();
    isRecording.value = false;
    print(_recordingId);
    if (path != null) {
      print("Gravação salva em: $path");
    }
    return path;
  }

  // Envia os dados da gravação para o backend
  Future<void> sendRecording(
      String description, String? recordingId, String? localFilePath) async {
    print(recordingId);
    if (recordingId != null) {
      final downloadUrl =
          await _storageService.uploadFile(localFilePath!, 'audio-files');
      if (downloadUrl != null) {
        _firebaseUrl = downloadUrl;
        print("Áudio enviado para o Firebase Storage com URL: $downloadUrl");
      } else {
        print("Erro: URL do Firebase ou ID da gravação ausente.");
        return;
      }
      final finishResponse = await http.post(
        Uri.parse('https://avaguard-api.vercel.app/finishEmployeesRecording'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeesRecordingId': recordingId,
          'url': _firebaseUrl,
          'description': description,
        }),
      );

      if (finishResponse.statusCode == 201) {
        print("Gravação enviada com sucesso para o backend.");
      } else {
        print(
            "Erro ao enviar a gravação para o backend: ${finishResponse.body}");
      }
    }

    if (recordingId == null || _firebaseUrl == null) {
      print("Erro: ID da gravação ou URL do áudio ausente.");
      return;
    }
  }

  Future<bool> toggleRecording(String userId) async {
    if (isRecording.value) {
      await stopRecording();
      return false; // Parou a gravação
    } else {
      await startRecording(userId);
      return true; // Começou a gravação
    }
  }
}
