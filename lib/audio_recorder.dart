import 'dart:io';
import 'dart:convert';
import 'package:avaguard/resources/firestore_methods.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AudioRecord {
  final _recorder = AudioRecorder();
  bool isRecording = false;
  final FirebaseStorageService _storageService = FirebaseStorageService();
  String? _recordingId;

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
        print("Gravação iniciada no backend com ID: $_recordingId");

        final Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          print("Erro ao obter o diretório externo.");
          return;
        }

        final String filePath =
            '${externalDir.path}/audios/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
        isRecording = true;
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
    if (!isRecording) {
      print("Nenhuma gravação em andamento.");
      return null;
    }

    final String? path = await _recorder.stop();
    isRecording = false;

    if (path != null) {
      print("Gravação salva em: $path");

      // Envia o arquivo para o Firebase Storage
      final downloadUrl = await _storageService.uploadFile(path, 'audios');
      if (downloadUrl != null && _recordingId != null) {
        print("Áudio enviado para o Firebase Storage com URL: $downloadUrl");

        // Fazer a chamada POST para finalizar a gravação no backend
        final finishResponse = await http.post(
          Uri.parse('https://avaguard-api.vercel.app/finishEmployeesRecording'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'employeesRecordingId': _recordingId,
            'url': downloadUrl,
            'description': 'aidento'
          }),
        );

        if (finishResponse.statusCode == 201) {
          print("Gravação finalizada com sucesso no backend.");
        } else {
          print(
              "Erro ao finalizar a gravação no backend: ${finishResponse.body}");
        }
      } else {
        print("Erro: URL do Firebase ou ID da gravação ausente.");
      }
    }
    return path;
  }

  Future<void> toggleRecording(String userId) async {
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording(userId);
    }
  }
}
