import 'package:flutter/material.dart';

class ProfilePictureManagerScreen extends StatelessWidget {
  const ProfilePictureManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Foto de Perfil'),
      ),
      body: const Center(
        child: Text('Conteúdo do Gerenciador de Foto de Perfil'),
      ),
    );
  }
}


