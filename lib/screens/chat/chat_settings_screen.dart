import 'package:flutter/material.dart';

class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Chat'),
      ),
      body: const Center(
        child: Text('Conteúdo das Configurações de Chat'),
      ),
    );
  }
}


