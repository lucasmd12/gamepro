import 'package:flutter/material.dart';

class UserManagementCard extends StatelessWidget {
  final String username;
  final String role;
  final VoidCallback onPromote;
  final VoidCallback onTransfer;
  final VoidCallback onBan;

  const UserManagementCard({
    super.key,
    required this.username,
    required this.role,
    required this.onPromote,
    required this.onTransfer,
    required this.onBan,
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
              username,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(role),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: onPromote,
                  icon: const Icon(Icons.star),
                  label: const Text("Promover"),
                ),
                ElevatedButton.icon(
                  onPressed: onTransfer,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text("Transferir"),
                ),
                ElevatedButton.icon(
                  onPressed: onBan,
                  icon: const Icon(Icons.block),
                  label: const Text("Banir"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


