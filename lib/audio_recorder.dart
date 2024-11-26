import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecord {
  final _recorder = AudioRecorder();
  bool isRecording = false;

  // Inicia a gravação
  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
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
      print("Gravação iniciada: $filePath");
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
    print("Gravação salva em: $path");
    return path;
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }
}
