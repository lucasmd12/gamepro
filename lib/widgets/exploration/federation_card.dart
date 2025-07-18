import 'package:flutter/material.dart';

class FederationCard extends StatelessWidget {
  final String federationName;
  final String? federationTag;
  final int memberCount;
  final VoidCallback onInfoPressed;
  final VoidCallback onChatPressed;
  final VoidCallback onJoinPressed;

  const FederationCard({
    super.key,
    required this.federationName,
    this.federationTag,
    required this.memberCount,
    required this.onInfoPressed,
    required this.onChatPressed,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              federationName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (federationTag != null)
              Text(
                'Tag: [$federationTag]',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text('👥 $memberCount membros'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: onJoinPressed,
                  icon: const Icon(Icons.call),
                  label: const Text('Entrar'),
                ),
                ElevatedButton.icon(
                  onPressed: onChatPressed,
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                ),
                ElevatedButton.icon(
                  onPressed: onInfoPressed,
                  icon: const Icon(Icons.info),
                  label: const Text('Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


