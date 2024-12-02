import 'package:audio_service/audio_service.dart';
import 'package:avaguard/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:avaguard/audio_recorder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_session/audio_session.dart';

class AvaguardAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final AudioRecord _recorder = AudioRecord();  
  AudioSession? _audioSession;
  String? userId;
  String? recordingId;
  String? localFilePath;

  AvaguardAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    mediaItem.add(_mediaItem);
    _player.setAudioSource(AudioSource.uri(Uri.parse(_mediaItem.id)));

    init();
  }

  Future<void> init() async {
    _audioSession = await AudioSession.instance;
    await _audioSession?.configure(AudioSessionConfiguration.speech());

    _audioSession?.interruptionEventStream.listen((event) async {
      if (event.type == AudioInterruptionType.pause) {
        print("aconteceu alguma coisa aqui3");
        await showNotification(
          'Foco de Áudio Perdido',
          'Outro aplicativo tomou o controle do áudio.',
        );
        print('1: ${AudioInterruptionType.unknown}');
      } else if (event.type == AudioInterruptionType.duck) {
        _player.setVolume(0.5);
      } else if (event.type == AudioInterruptionType.values.last) {
        await showNotification(
          'Foco de Áudio Perdido',
          'Outro aplicativo tomou o controle do áudio.',
        );
      }
    });

    _audioSession?.becomingNoisyEventStream.listen((_) async {
      print("aconteceu alguma coisa aqu seriai");
      await showNotification(
        'Foco de Áudio Perdido',
        'Fones de ouvido desconectados ou outro áudio começou.',
      );
    });

    _player.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.ready &&
          _player.playing) {
        await cancelNotification();
      }
    });
  }

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

  @override
  Future<void> pause() async {
    await initPrefs();
    print("//////////////////////");
    print("$recordingId - $localFilePath");
    print("Parando");
    _player.pause();
    await _recorder.stopRecording(
        await initPrefs(), recordingId, localFilePath);
    return _player.pause();
  }

  @override
  Future<void> play() async {
    print("/////// USER ID ///////////////");
    print(userId);
    if (_player.playerState.playing) {
      print("Parando");
      if (userId?.isNotEmpty ?? false) {
        await _recorder.toggleRecording(
            userId!, recordingId!, localFilePath!, await initPrefs());
      }
      return _player.pause();
    }

    if (userId?.isNotEmpty ?? false) {
      await _recorder.startRecording(userId!, await initPrefs());
    }
    print("Tocando");

    return _player.play();
  }

  Future<void> startService() async {
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(_mediaItem.id)),
          preload: true);

      if (await _recorder.hasPermission()) {
        play();
        await Future.delayed(const Duration(seconds: 5));
        await pause(); // Pausa o áudio
        print('Serviço de áudio iniciado.');
      } else {
        print('Permissões de gravação não concedidas.');
      }
    } catch (e) {
      print("Erro ao iniciar o serviço $e");
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

  Future<void> showNotification(String title, String body) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'audio_focus_channel', // ID do canal
            'Áudio Focus', // Nome do canal
            channelDescription: 'Notificações de foco de áudio',
            importance: Importance.high,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
            fullScreenIntent: true,
            styleInformation: BigTextStyleInformation(
                "O aplicativo pode não funcionar como o esperado sem o foco do áudio."));

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: 'retomar_audio',
    );
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }
}
