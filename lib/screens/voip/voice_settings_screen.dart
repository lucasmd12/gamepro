import 'package:flutter/material.dart';

class VoiceSettingsScreen extends StatelessWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Voz'),
      ),
      body: const Center(
        child: Text('Conteúdo das Configurações de Voz'),
      ),
    );
  }
}


