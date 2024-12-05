import 'dart:io';
import 'dart:convert';
import 'package:avaguard/main.dart';
import 'package:avaguard/resources/firestore_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AudioRecord {
  final _recorder = AudioRecorder();
  static final ValueNotifier<bool> isRecording = ValueNotifier<bool>(false);
  //static final ValueNotifier<bool> hasPendingAudio = ValueNotifier<bool>(false);
  final FirebaseStorageService _storageService = FirebaseStorageService();

  // Inicia a gravação
  Future<void> startRecording(String userId, SharedPreferences prefs) async {
    if (!await _recorder.hasPermission()) {
      print("Permissão negada!");
      return;
    }

    try {
      if (userId.isNotEmpty) {
        final path = await _prepareRecordingFile(userId, prefs);
        if (path == null) return;

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 44100,
            bitRate: 128000,
          ),
          path: path,
        );

        isRecording.value = true;

        final response = await _initiateBackendRecording(userId, prefs);
        if (response == null) return;

        print("Gravação iniciada no arquivo: $path");
      }
    } catch (e) {
      print("Erro ao iniciar gravação: $e");
    }
  }

  Future<String?> _prepareRecordingFile(
      String userId, SharedPreferences prefs) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception("Erro ao acessar o diretório externo.");
      final path =
          '${dir.path}/audios/audio_${DateTime.now().millisecondsSinceEpoch}_$userId.wav';
      await Directory('${dir.path}/audios').create(recursive: true);
      prefs.setString('filePath', path);
      return path;
    } catch (e) {
      print("Erro ao criar arquivo de gravação: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _initiateBackendRecording(
      String userId, SharedPreferences prefs) async {
    try {
      final response = await http.post(
        Uri.parse(initAudioRecording),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        prefs.setString(
            'recordingId', body['employeesRecording']['employeesRecordingId']);
        return body;
      } else {
        print("Erro ao iniciar gravação no backend: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erro na requisição ao backend: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _finishBackendRecording(
      String recordingId, String url, SharedPreferences prefs) async {
    try {
      final response = await http.post(
        Uri.parse(finishAudioRecording),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': url,
          'employeesRecordingId': recordingId,
        }),
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        await clearPrefs(prefs);
        await showNotification("Áudio enviado com sucesso",
            "Seu áudio foi enviado e será analisado.");
        return body;
      } else {
        print("Erro enviar gravação ao backend: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erro na requisição ao backend: $e");
      return null;
    }
  }

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  // Para a gravação
  Future<String?> stopRecording(SharedPreferences prefs,
      [String? recordingId, String? localFilePath]) async {
    if (!isRecording.value) {
      print("Nenhuma gravação em andamento.");
      return null;
    }
    try {
      final path = await _recorder.stop();
      isRecording.value = false;
      if (recordingId == null || localFilePath == null) {
        print("Nenhuma gravação em andamento.");
        return null;
      }

      await showNotification("Enviando...", "Áudio está sendo enviado.");

      await sendRecording(recordingId, localFilePath, prefs);
      return path;
    } catch (e) {
      print("Erro ao parar gravação: $e");
      return null;
    }
  }

  Future<String?> getUrlFirebase(
      String? recordingId, String? localFilePath) async {
    try {
      final downloadUrl =
          await _storageService.uploadFile(localFilePath!, 'audio-files');
      if (downloadUrl != null) {
        print("Áudio enviado para o Firebase Storage com URL: $downloadUrl");
        return downloadUrl;
      } else {
        return null;
      }
    } catch (e) {
      print("Erro na requisição ao firebase: $e");
      return null;
    }
  }

  // Envia os dados da gravação para o backend
  Future<void> sendRecording(String? recordingId, String? localFilePath,
      SharedPreferences prefs) async {
    print(recordingId);

    String? url;
    try {
      url = await getUrlFirebase(recordingId, localFilePath);
      if (url == null) throw Exception("URL do Firebase não obtida.");
    } catch (e) {
      print("Erro ao enviar gravação: $e");
      return;
    }

    try {
      var response = _finishBackendRecording(recordingId!, url, prefs);

      print(response.toString());

      isRecording.value = false;

      if (localFilePath != null) {
        final file = File(localFilePath);
        if (await file.exists()) {
          try {
            await file.delete();
            print("Arquivo local deletado: $localFilePath");
          } catch (e) {
            print("Erro ao deletar o arquivo: $e");
          }
        } else {
          print("Arquivo não encontrado para deletar: $localFilePath");
        }
      }
    } catch (e) {
      print("Erro ao finalizar gravação no backend: $e");
    }

    await clearPrefs(prefs);
  }

  Future<void> cancelRecording(SharedPreferences prefs) async {
    String? recordingId = prefs.getString('recordingId');

    if (recordingId == null) {
      print("Nenhuma gravação pendente para cancelar.");
      return;
    }

    try {
      await clearPrefs(prefs);

      audioHandler.pause();

      final response = await http.post(
        Uri.parse(cancelAudioRecording),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'employeesRecordingId': recordingId}),
      );

      if (response.statusCode == 201) {
        print("Gravação cancelada com sucesso no backend.");
      } else {
        print("Erro ao cancelar a gravação no backend: ${response.body}");
      }
    } catch (e) {
      print("Erro ao cancelar a gravação: $e");
    }
  }

  Future<bool> toggleRecording(String userId, String recordingId,
      String filePath, SharedPreferences prefs) async {
    if (isRecording.value) {
      print(await stopRecording(prefs, recordingId, filePath));
      return false;
    } else {
      await startRecording(userId, prefs);
      return true;
    }
  }

  Future<void> clearPrefs(SharedPreferences prefs) async {
    await prefs.remove('recordingId');
    await prefs.remove('filePath');
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }
}
