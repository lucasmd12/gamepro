import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/services/permission_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';

class PermissionWidget extends StatelessWidget {
  final String requiredAction;
  final Widget child;
  final Widget? fallback;
  final String? clanId;
  final String? federationId;
  final String? creatorId;
  final String? roomType;

  const PermissionWidget({
    super.key,
    required this.requiredAction,
    required this.child,
    this.fallback,
    this.clanId,
    this.federationId,
    this.creatorId,
    this.roomType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser;
        if (user == null) {
          return fallback ?? const SizedBox.shrink();
        }

        bool hasPermission = false;

        // Verificar permissões específicas baseadas na ação
        switch (requiredAction) {
          case 'create_clan_voice_room':
            hasPermission = PermissionService.canCreateVoiceRoom(user, 'clan');
            break;
          case 'create_federation_voice_room':
            hasPermission = PermissionService.canCreateVoiceRoom(user, 'federation');
            break;
          case 'create_global_voice_room':
            hasPermission = PermissionService.canCreateVoiceRoom(user, 'global');
            break;
          case 'create_admin_voice_room':
            hasPermission = PermissionService.canCreateVoiceRoom(user, 'admin');
            break;
          case 'join_clan_voice_room':
            hasPermission = PermissionService.canJoinVoiceRoom(user, 'clan', clanId: clanId);
            break;
          case 'join_federation_voice_room':
            hasPermission = PermissionService.canJoinVoiceRoom(user, 'federation', federationId: federationId);
            break;
          case 'join_global_voice_room':
            hasPermission = PermissionService.canJoinVoiceRoom(user, 'global');
            break;
          case 'join_admin_voice_room':
            hasPermission = PermissionService.canJoinVoiceRoom(user, 'admin');
            break;
          case 'send_clan_message':
            hasPermission = PermissionService.canSendMessage(user, 'clan', clanId: clanId);
            break;
          case 'send_federation_message':
            hasPermission = PermissionService.canSendMessage(user, 'federation', federationId: federationId);
            break;
          case 'send_global_message':
            hasPermission = PermissionService.canSendMessage(user, 'global');
            break;
          case 'manage_clan':
            hasPermission = PermissionService.canManageClan(user, clanId);
            break;
          case 'manage_federation':
            hasPermission = PermissionService.canManageFederation(user, federationId);
            break;
          case 'access_admin_panel':
            hasPermission = PermissionService.canAccessAdminPanel(user);
            break;
          case 'create_clan':
            hasPermission = PermissionService.canCreateClan(user);
            break;
          case 'create_federation':
            hasPermission = PermissionService.canCreateFederation(user);
            break;
          case 'invite_to_clan':
            hasPermission = PermissionService.canInviteToClan(user, clanId);
            break;
          case 'view_global_stats':
            hasPermission = PermissionService.canViewGlobalStats(user);
            break;
          case 'moderate_clan_chat':
            hasPermission = PermissionService.canModerateChat(user, 'clan', clanId: clanId);
            break;
          case 'moderate_federation_chat':
            hasPermission = PermissionService.canModerateChat(user, 'federation', federationId: federationId);
            break;
          case 'moderate_global_chat':
            hasPermission = PermissionService.canModerateChat(user, 'global');
            break;
          case 'end_voice_room':
            if (roomType != null && creatorId != null) {
              hasPermission = PermissionService.canEndOthersVoiceRoom(
                user, 
                roomType!, 
                creatorId!, 
                clanId: clanId, 
                federationId: federationId
              );
            }
            break;
          default:
            // Usar verificação genérica de ações
            hasPermission = PermissionService.hasAction(user, requiredAction);
            break;
        }

        return hasPermission ? child : (fallback ?? const SizedBox.shrink());
      },
    );
  }
}

// Widget para mostrar informações baseadas no role do usuário
class RoleBasedWidget extends StatelessWidget {
  final Widget? adminWidget;
  final Widget? leaderWidget;
  final Widget? memberWidget;
  final Widget? fallback;

  const RoleBasedWidget({
    super.key,
    this.adminWidget,
    this.leaderWidget,
    this.memberWidget,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser;
        if (user == null) {
          return fallback ?? const SizedBox.shrink();
        }

        switch (user.role) {
          case Role.admMaster:
            return adminWidget ?? fallback ?? const SizedBox.shrink();
          case Role.leader:
            return leaderWidget ?? fallback ?? const SizedBox.shrink();
          case Role.user:
            return memberWidget ?? fallback ?? const SizedBox.shrink();
          default:
            return fallback ?? const SizedBox.shrink();
        }
      },
    );
  }
}

// Widget para mostrar badge do role do usuário
class RoleBadge extends StatelessWidget {
  final User? user;
  final bool showText;

  const RoleBadge({
    super.key,
    this.user,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    Color badgeColor;
    IconData badgeIcon;
    String roleText;

    switch (user!.role) {
      case Role.admMaster:
        badgeColor = Colors.red;
        badgeIcon = Icons.admin_panel_settings;
        roleText = 'ADM';
        break;
      case Role.leader:
        badgeColor = Colors.orange;
        badgeIcon = Icons.star;
        roleText = 'Líder';
        break;
      case Role.user:
        badgeColor = Colors.blue;
        badgeIcon = Icons.person;
        roleText = 'Membro';
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.help;
        roleText = 'Desconhecido';
        break;
    }

    if (!showText) {
      return Icon(
        badgeIcon,
        color: badgeColor,
        size: 16,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            roleText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


