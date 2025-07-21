import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart'; // Importar AuthProvider
import 'package:lucasbeatsfederacao/services/permission_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart'; // Importar Clan
import 'package:lucasbeatsfederacao/models/federation_model.dart'; // Importar Federation


class PermissionWidget extends StatelessWidget {
  final String requiredAction;
  final Widget child;
  final Widget? fallback;
  final String? clanId;
  final String? federationId;
  final String? creatorId;
  final String? roomType;
  // Adicionar parâmetros opcionais para Clan e Federation
  final Clan? clan;
  final Federation? federation;


  const PermissionWidget({
    super.key,
    required this.requiredAction,
    required this.child,
    this.fallback,
    this.clanId,
    this.federationId,
    this.creatorId,
    this.roomType,
    this.clan,
    this.federation,
  });

  @override
  Widget build(BuildContext context) {
    // Usar o AuthProvider para obter o usuário
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    // Criar uma instância do PermissionService
    final permissionService = PermissionService(authProvider: authProvider);

    bool hasPermission = false;

    // Verificar permissões específicas baseadas na ação
    switch (requiredAction) {
      case 'create_clan_voice_room':
        hasPermission = permissionService.canCreateVoiceRoom(); // Sem parâmetro user e tipo de sala, se a lógica estiver no service
        break;
      case 'create_federation_voice_room':
        hasPermission = permissionService.canCreateVoiceRoom(); // Sem parâmetro user e tipo de sala, se a lógica estiver no service
        break;
      case 'create_global_voice_room':
        hasPermission = permissionService.canCreateVoiceRoom(); // Sem parâmetro user e tipo de sala, se a lógica estiver no service
        break;
      case 'create_admin_voice_room':
        hasPermission = permissionService.canCreateVoiceRoom(); // Sem parâmetro user e tipo de sala, se a lógica estiver no service
        break;
      case 'join_clan_voice_room':
        hasPermission = permissionService.canJoinVoiceRoom(); // Sem parâmetro user e detalhes da sala, se a lógica estiver no service
        break;
      case 'join_federation_voice_room':
        hasPermission = permissionService.canJoinVoiceRoom(); // Sem parâmetro user e detalhes da sala, se a lógica estiver no service
        break;
      case 'join_global_voice_room':
        hasPermission = permissionService.canJoinVoiceRoom(); // Sem parâmetro user e detalhes da sala, se a lógica estiver no service
        break;
      case 'join_admin_voice_room':
        hasPermission = permissionService.canJoinVoiceRoom(); // Sem parâmetro user e detalhes da sala, se a lógica estiver no service
        break;
      case 'send_clan_message':
        hasPermission = permissionService.canSendMessage(); // Sem parâmetro user e detalhes da sala, se a lógica estiver no service
        break;
      case 'send_federation_message':
        hasPermission = permissionService.canSendMessage(); // Sem parâmetro user e detalhes da sala, se a lógica estiver no service
        break;
      case 'send_global_message':
        hasPermission = permissionService.canSendMessage(); // Sem parâmetro user e detalhes da sala, se a lógica estiver no service
        break;
      case 'manage_clan':
        // Passar o objeto Clan, se disponível
        if (clan != null) {
           hasPermission = permissionService.canManageClan(clan!);
        } else {
           // Lidar com o caso onde clan não é fornecido, se necessário
           // Dependendo da sua lógica, talvez devesse ser false ou lançar um erro.
           // Por agora, manter como false se o objeto clan não estiver disponível.
           hasPermission = false;
        }
        break;
      case 'manage_federation':
        // Passar o objeto Federation, se disponível
        if (federation != null) {
           hasPermission = permissionService.canManageFederation(federation!);
        } else {
           // Lidar com o caso onde federation não é fornecido, se necessário
           hasPermission = false;
        }
        break;
      case 'access_admin_panel':
        hasPermission = permissionService.canAccessAdminPanel();
        break;
      case 'create_clan':
        hasPermission = permissionService.canCreateClan();
        break;
      case 'create_federation':
        hasPermission = permissionService.canCreateFederation();
        break;
      case 'invite_to_clan':
         // Assumindo que canInviteToClan precise do clan
         if (clan != null) {
            hasPermission = permissionService.canInviteToClan(clan!);
         } else {
            hasPermission = false;
         }
        break;
      case 'view_global_stats':
        hasPermission = permissionService.canViewGlobalStats();
        break;
      case 'moderate_clan_chat':
        hasPermission = permissionService.canModerateChat(); // Sem parâmetros de tipo ou ID, se a lógica estiver no service
        break;
      case 'moderate_federation_chat':
        hasPermission = permissionService.canModerateChat(); // Sem parâmetros de tipo ou ID, se a lógica estiver no service
        break;
      case 'moderate_global_chat':
        hasPermission = permissionService.canModerateChat(); // Sem parâmetros de tipo ou ID, se a lógica estiver no service
        break;
      case 'end_voice_room':
        // Assumindo que canEndOthersVoiceRoom precise do creatorId, clanId e federationId
        if (creatorId != null) { // roomType não é mais necessário como parâmetro se a lógica estiver no service
             hasPermission = permissionService.canEndOthersVoiceRoom(); // Sem parâmetros de tipo ou ID, se a lógica estiver no service
        } else {
             hasPermission = false;
        }
        break;
      default:
        // Usar verificação genérica de ações
        hasPermission = permissionService.hasAction(requiredAction);
        break;
    }

    return hasPermission ? child : (fallback ?? const SizedBox.shrink());
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
    return Consumer<AuthProvider>( // Mudar para AuthProvider
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
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
