import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/member_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart' show User;
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/screens/call_screen.dart';

class MemberListItem extends StatelessWidget {
  final Member member;
  final User currentUser;
  final Function(Member, String) onMemberAction;
  final bool canManage;
  final String? clanFlagUrl; // Adicionado

  const MemberListItem({
    super.key,
    required this.member,
    required this.currentUser, 
    required this.onMemberAction,
    this.canManage = false,
    this.clanFlagUrl, // Adicionado
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade800.withOpacity(0.8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _getRoleColor(member.role),
              backgroundImage: member.avatarUrl.isNotEmpty 
                ? NetworkImage(member.avatarUrl)
                : null,
              child: member.avatarUrl.isEmpty
                ? Text(
                    member.username.isNotEmpty ? member.username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            ),
            if (member.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            if (clanFlagUrl != null && clanFlagUrl!.isNotEmpty) // Exibe a bandeira se a URL existir
              Padding(
                padding: const EdgeInsets.only(right: 8.0), // Espaço à direita da bandeira
                child: Image.network(
                  clanFlagUrl!,
                  width: 24, // Ajuste o tamanho conforme necessário
                  height: 24, // Ajuste o tamanho conforme necessário
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.flag, color: Colors.grey), // Ícone de placeholder em caso de erro
                ),
              ),
            Expanded(
              child: Text(
                member.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (member.federationTag != null && member.federationTag!.isNotEmpty) // Exibe a tag da federação se existir
              Padding(
                padding: const EdgeInsets.only(left: 8.0), // Espaço à esquerda da tag
                child: Text(
                  '[${member.federationTag}]',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12, // Ajuste o tamanho conforme necessário
                  ),
                ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getRoleDisplayName(member.role),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          member.isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            color: member.isOnline ? Colors.green : Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (member.isOnline && member.id != currentUser.id)
              IconButton(
                icon: const Icon(Icons.call, color: Colors.green, size: 20),
                onPressed: () => _initiateCall(context),
                tooltip: 'Fazer chamada',
              ),
            
            if (canManage && member.id != currentUser.id)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (action) => onMemberAction(member, action),
                itemBuilder: (context) => _buildMenuItems(),
              ),
          ],
        ),
      ),
    );
  }

  void _initiateCall(BuildContext context) async {
    final voipService = Provider.of<VoIPService>(context, listen: false);
    
    if (voipService.isInCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já está em uma chamada.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Fazer Chamada',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja fazer uma chamada para ${member.username}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Chamar'),
          ),
        ],
      ),
    );

    if (shouldCall == true) {
      
 await voipService.initiateCall(targetId: member.id, displayName: member.username);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              roomId: voipService.currentCall!.roomName ?? '',
 isIncoming: false,
            ),
          ),
        );
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];
    
    if (member.role == Role.member) {
      items.add(const PopupMenuItem(
        value: 'promote',
        child: Row(
          children: [
            Icon(Icons.arrow_upward, color: Colors.green),
            SizedBox(width: 8),
            Text('Promover'),
          ],
        ),
      ));
    }
    
    if (member.role == Role.subLeader) {
      items.add(const PopupMenuItem(
        value: 'demote',
        child: Row(
          children: [
            Icon(Icons.arrow_downward, color: Colors.orange),
            SizedBox(width: 8),
            Text('Rebaixar'),
          ],
        ),
      ));
    }
    
    items.add(const PopupMenuItem(
      value: 'remove',
      child: Row(
        children: [
          Icon(Icons.person_remove, color: Colors.red),
          SizedBox(width: 8),
          Text('Remover'),
        ],
      ),
    ));
    
    items.add(const PopupMenuItem(
      value: 'message',
      child: Row(
        children: [
          Icon(Icons.message, color: Colors.blue),
          SizedBox(width: 8),
          Text('Mensagem'),
        ],
      ),
    ));
    
    return items;
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.admMaster:
        return Colors.red;
      case Role.leader:
        return Colors.orange;
      case Role.subLeader:
        return Colors.yellow.shade600;
      case Role.member:
        return Colors.blue;
      case Role.guest:
        return Colors.grey;
      case Role.user:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(Role role) {
    switch (role) {
 case Role.leader:
 return 'LÍDER';
 case Role.subLeader:
 return 'SUB-LÍDER';
 case Role.member:
 return 'MEMBRO';
      case Role.guest:
        return 'CONVIDADO';
 case Role.admMaster:
 return 'ADMINISTRADOR MASTER';
      case Role.user:
        return 'USUÁRIO';
      default:
        return role.toString().split('.').last.toUpperCase();
    }
  }
}


