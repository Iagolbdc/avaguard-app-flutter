import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:avaguard/audio_recorder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvaguardAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final AudioRecord _recorder = AudioRecord();
  String? userId;
  String? recordingId;
  String? localFilePath;

  Future<SharedPreferences> initPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    recordingId = prefs.getString('recordingId');
    localFilePath = prefs.getString('filePath');

    return prefs;
  }

  static const MediaItem _mediaItem = MediaItem(
    id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    title: 'Gravação Avaguard',
    artist: 'Usuário',
    duration: Duration(milliseconds: 5739820),
  );

  AvaguardAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    mediaItem.add(_mediaItem);
    _player.setAudioSource(AudioSource.uri(Uri.parse(_mediaItem.id)));
  }

  @override
  Future<void> pause() async {
    await initPrefs();
    print("//////////////////////");
    print("$recordingId - $localFilePath");
    // if (recordingId != null && localFilePath != null) _recorder.sendRecording(recordingId, localFilePath);
    print("Parando");
    if (recordingId == null || localFilePath == null) {
      print("Erro: Nenhuma gravação ativa para pausar.");
      return;
    }
    await _recorder.stopRecording(
        recordingId!, localFilePath!, await initPrefs());
    return _player.pause();
  }

  @override
  Future<void> play() async {
    if (_player.playerState.playing) {
      print("Parando");
      if (userId?.isNotEmpty ?? false) {
        await _recorder.toggleRecording(
            userId!, recordingId!, localFilePath!, await initPrefs());
      }
      return _player.pause();
    }

    if (userId?.isNotEmpty ?? false) {
      await _recorder.toggleRecording(
          userId!, recordingId!, localFilePath!, await initPrefs());
    }
    print("Tocando");

    return _player.play();
  }

  Future<void> startService() async {
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(_mediaItem.id)),
    );

    if (await _recorder.hasPermission()) {
      await play();
      print('Serviço de áudio iniciado.');
    } else {
      print('Permissões de gravação não concedidas.');
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
