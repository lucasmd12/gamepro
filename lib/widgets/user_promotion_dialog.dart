import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';

class UserPromotionDialog extends StatefulWidget {
  final Function(String username, Role role) onPromote;

  const UserPromotionDialog({
    super.key,
    required this.onPromote,
  });

  @override
  State<UserPromotionDialog> createState() => _UserPromotionDialogState();
}

class _UserPromotionDialogState extends State<UserPromotionDialog> {
  final TextEditingController _usernameController = TextEditingController();
  Role _selectedRole = Role.member;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Promover Usuário'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Nome de usuário',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Role>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Novo cargo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.admin_panel_settings),
            ),
            items: [
              DropdownMenuItem(
                value: Role.member,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Membro'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: Role.clanLeader,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Líder de Clã'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: Role.admMaster,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8), // Adicionado 'const' aqui
                    const Text('Administrador'),
                  ],
                ),
              ),
            ],
            onChanged: (Role? newRole) {
              if (newRole != null) {
                setState(() {
                  _selectedRole = newRole;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRoleWarning(_selectedRole),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _usernameController.text.isEmpty ? null : () {
            widget.onPromote(_usernameController.text, _selectedRole);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _getRoleColor(_selectedRole),
          ),
          child: const Text('Promover'),
        ),
      ],
    );
  }

  String _getRoleWarning(Role role) {
    switch (role) {
      case Role.member:
        return 'Usuário terá permissões básicas de membro.';
      case Role.clanLeader:
        return 'Usuário poderá gerenciar um clã e seus membros.';
      case Role.admMaster:
        return 'ATENÇÃO: Usuário terá acesso total ao sistema!';
      default:
        return ''; // Aviso vazio para outros papéis
    }
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.member:
        return Colors.grey;
      case Role.clanLeader:
        return Colors.blue;
      case Role.admMaster:
        return Colors.red;
      default:
        return Colors.grey; // Cor padrão
    }
  }
}


