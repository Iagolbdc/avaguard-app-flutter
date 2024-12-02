import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequester extends StatefulWidget {
  final Widget child;

  const PermissionRequester({required this.child, super.key});

  @override
  State<PermissionRequester> createState() => _PermissionRequesterState();
}

class _PermissionRequesterState extends State<PermissionRequester> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermissions(context); // Solicita permissões com acesso ao contexto
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<void> requestPermissions(BuildContext context) async {
  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      print("Permissão para notificações já concedida.");
      return;
    }

    final status = await Permission.notification.request();

    if (status.isGranted) {
      print("Permissão para notificações concedida.");
    } else if (status.isDenied) {
      print("Permissão para notificações negada.");
    } else if (status.isPermanentlyDenied) {
      print("Permissão permanentemente negada. Direcionar para configurações.");
      await openAppSettings();
    }
  }

  // Lista de permissões necessárias
  final permissions = [
    Permission.microphone,
    Permission.storage,
    Permission.bluetooth,
  ];

  bool hasDeniedPermission = false;

  // Solicitar permissões
  for (var permission in permissions) {
    final status = await permission.request();
    await requestNotificationPermission();
    if (status.isDenied || status.isPermanentlyDenied) {
      hasDeniedPermission = true;
    }
  }

  // Se alguma permissão foi negada, exibe um aviso
  if (hasDeniedPermission) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Permissões negadas. Algumas funcionalidades podem não funcionar.',
        ),
        action: SnackBarAction(
          label: 'Configurações',
          onPressed: () async {
            await openAppSettings(); // Redireciona para as configurações do dispositivo
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
