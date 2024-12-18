import 'package:avaguard/audio_handler.dart';
import 'package:avaguard/permission_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'incident_report_page.dart';
import 'login_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

late final AvaguardAudioHandler audioHandler;

Future<void> showNotification(String title, String body) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'status_sending', // ID do canal
    'Status Sending', // Nome do canal
    channelDescription: 'Notificação de Envio do Áudio',
    importance: Importance.high,
    priority: Priority.high,
    ongoing: false,
    autoCancel: false,
    fullScreenIntent: true,
  );

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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await configureNotifications();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print(prefs.getString('userId'));
  // Inicializando o AudioService
  audioHandler = await AudioService.init(
    builder: () => AvaguardAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.avaguard',
      androidNotificationChannelName: 'avaguard',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  Future.microtask(() => audioHandler.startService());

  runApp(MyApp());
}

Future<void> configureNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'audio_focus_channel', // ID único do canal
    'Áudio Focus', // Nome do canal
    description: 'Notificações de foco de áudio',
    importance: Importance.high, // Certifique-se de que é alta prioridade
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Configurar o canal de notificação
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Configuração inicial
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Avaguard',
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = snapshot.data;

          print(userId);

          if (userId != null && userId.isNotEmpty) {
            return PermissionRequester(
                child: IncidentReportPage(userId: userId));
          } else {
            return PermissionRequester(child: LoginScreen());
          }
        },
      ),
      routes: {
        '/incident_report': (context) => IncidentReportPage(
              userId: ModalRoute.of(context)?.settings.arguments as String,
            ),
      },
    );
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}
