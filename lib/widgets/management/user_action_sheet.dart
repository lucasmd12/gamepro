import 'package:flutter/material.dart';

class UserActionSheet extends StatelessWidget {
  final String userId;
  final String username;
  final VoidCallback onPromote;
  final VoidCallback onTransfer;
  final VoidCallback onBan;

  const UserActionSheet({
    super.key,
    required this.userId,
    required this.username,
    required this.onPromote,
    required this.onTransfer,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Ações para $username',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Promover Usuário'),
                onTap: () {
                  Navigator.pop(context);
                  onPromote();
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Transferir para Outro Clã/Federação'),
                onTap: () {
                  Navigator.pop(context);
                  onTransfer();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Banir Usuário', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onBan();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


