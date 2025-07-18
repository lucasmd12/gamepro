import 'package:flutter/material.dart';

class ClanDetailEnhancedScreen extends StatelessWidget {
  final String clanId;

  const ClanDetailEnhancedScreen({super.key, required this.clanId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Clã'),
      ),
      body: Center(
        child: Text('Detalhes aprimorados do Clã: $clanId'),
      ),
    );
  }
}


