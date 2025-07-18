import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
// Import adicionado

class FederationLeaderPanelScreen extends StatelessWidget {
  final Federation federation;

  const FederationLeaderPanelScreen({super.key, required this.federation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel do Líder da Federação: ${federation.name ?? 'N/A'}'),
        backgroundColor: const Color(0xFFB71C1C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo, Líder da Federação ${federation.name ?? 'N/A'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Seção de Chat para Líderes de Federação e Clãs
            Expanded(
              child: Card(
                color: const Color(0xFF424242),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chat de Líderes (Federação e Clãs)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          color: const Color(0xFF212121),
                          child: const Center(
                            child: Text(
                              'Funcionalidade de Chat em desenvolvimento...', // Placeholder para o chat
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Campo de entrada de mensagem e botão de envio
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Digite sua mensagem...',
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF616161),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blueAccent),
                            onPressed: () {
                              // Lógica para enviar mensagem
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Seção de Canal de Voz
            Card(
              color: const Color(0xFF424242),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Canal de Voz de Líderes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Lógica para entrar no canal de voz
                        },
                        icon: const Icon(Icons.mic, color: Colors.white),
                        label: const Text('Entrar no Canal de Voz', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


