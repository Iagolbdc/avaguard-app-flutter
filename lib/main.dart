import 'package:avaguard/audio_handler.dart';
import 'package:avaguard/permission_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'incident_report_page.dart';
import 'login_screen.dart';

late final AvaguardAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

  await audioHandler.startService();

  runApp(MyApp());
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

          if (userId != null) {
            return IncidentReportPage(userId: userId);
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
