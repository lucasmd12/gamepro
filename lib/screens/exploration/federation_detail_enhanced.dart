import 'package:flutter/material.dart';

class FederationDetailEnhancedScreen extends StatelessWidget {
  final String federationId;

  const FederationDetailEnhancedScreen({super.key, required this.federationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Federação'),
      ),
      body: Center(
        child: Text('Detalhes aprimorados da Federação: $federationId'),
      ),
    );
  }
}


