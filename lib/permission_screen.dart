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
