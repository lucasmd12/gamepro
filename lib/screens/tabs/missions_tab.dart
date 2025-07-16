import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/screens/qrr_list_screen.dart'; // Importar a nova tela

class MissionsTab extends StatelessWidget {
  const MissionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const QRRListScreen(); // Redirecionar para a QRRListScreen
  }
}


