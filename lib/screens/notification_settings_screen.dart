import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Notificação'),
      ),
      body: const Center(
        child: Text('Conteúdo da Tela de Configurações de Notificação'),
      ),
    );
  }
}