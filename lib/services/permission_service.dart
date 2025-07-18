import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class PermissionService {
  // Verificar se o usuário pode criar salas de voz
  static bool canCreateVoiceRoom(User user, String roomType) {
    switch (roomType) {
      case 'clan':
        // Líder de clã (Role.leader) ou ADM MASTER global pode criar sala de clã
        return user.clanRole == Role.leader || user.role == Role.admMaster;
      case 'federation':
        // Líder de federação (Role.leader) ou ADM MASTER global pode criar sala de federação
        return user.federationRole == Role.leader || user.role == Role.admMaster;
      case 'global':
        // Qualquer usuário pode criar salas globais
        return true;
      case 'admin':
        // Apenas ADM MASTER global pode criar salas de admin
        return user.role == Role.admMaster;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode entrar em salas de voz
  static bool canJoinVoiceRoom(User user, String roomType, {String? clanId, String? federationId}) {
    switch (roomType) {
      case 'clan':
        // Deve estar no mesmo clã OU ser ADM MASTER global
        return (user.clanId != null && user.clanId == clanId) || user.role == Role.admMaster;
      case 'federation':
        // Deve estar na mesma federação OU ser ADM MASTER global
        return (user.federationId != null && user.federationId == federationId) || user.role == Role.admMaster;
      case 'global':
        // Qualquer usuário logado pode entrar (verificação no getAvailableActions)
        return user.role != Role.guest; // Apenas usuários logados
      case 'admin':
        // Apenas ADM global pode entrar
        return user.role == Role.admMaster;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode enviar mensagens em um chat
  static bool canSendMessage(User user, String chatType, {String? clanId, String? federationId}) {
    switch (chatType) {
      case 'clan':
        // Deve estar no mesmo clã (Role.member ou superior) OU ser ADM MASTER global
        return (user.clanId != null && user.clanId == clanId && user.clanRole != Role.guest) || user.role == Role.admMaster;
      case 'federation':
        // Deve estar na mesma federação (Role.member ou superior) OU ser ADM MASTER global
        return (user.federationId != null && user.federationId == federationId && user.federationRole != Role.guest) || user.role == Role.admMaster;
      case 'global':
        // Qualquer usuário pode enviar mensagens globais
        return true;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode gerenciar um clã
  static bool canManageClan(User user, String? clanId) {
    // ADM MASTER global pode gerenciar qualquer clã
    if (user.role == Role.admMaster) return true;
    // Líder do clã pode gerenciar seu próprio clã
    if (user.clanRole == Role.leader && user.clanId == clanId) return true;
    return false;
  }

  // Verificar se o usuário pode gerenciar uma federação
  static bool canManageFederation(User user, String? federationId) {
    // Apenas ADM MASTER global pode gerenciar federações
    if (user.role == Role.admMaster) return true;
     // Lider de federação pode gerenciar sua propria federação
    if (user.federationRole == Role.leader && user.federationId == federationId) return true; // Líder da federação também pode gerenciar
    return false;
  }

  // Verificar se o usuário pode promover outros usuários (papel global)
  // Este método pode precisar ser renomeado ou ajustado dependendo se é promoção global, de clã ou federação.
  // Assumindo promoção GLOBAL:
  static bool canPromoteUserGlobal(User promoter, User target, Role newRole) {
    // Apenas ADM MASTER global pode promover globalmente, e não pode promover para um papel superior ao seu (Role.admMaster)
    if (promoter.role != Role.admMaster || newRole == Role.admMaster) return false;

    // Não pode promover a si mesmo
    if (promoter.id == target.id) return false;

    // Apenas ADM MASTER global pode promover, e não para ADM MASTER

    return true;
  }

   // Verificar se o usuário pode remover outros usuários (global)
  static bool canRemoveUserGlobal(User remover, User target) {
    // Apenas ADM global pode remover globalmente
    if (remover.role != Role.admMaster) return false; // Apenas ADM MASTER pode remover globalmente

    // Não pode remover a si mesmo
    if (remover.id == target.id) return false;

    // ADM MASTER não pode remover outro ADM MASTER (regra comum, ajustar se necessário)
    if (target.role == Role.admMaster && remover.id != target.id) return false;


    return true;
  }


  // Verificar se o usuário pode acessar o painel administrativo
  static bool canAccessAdminPanel(User user) {
    return user.role == Role.admMaster;
  }

  // Verificar se o usuário pode criar clãs
  static bool canCreateClan(User user) {
    // Apenas ADM MASTER pode criar clãs
    return user.role == Role.admMaster;
  }

  // Verificar se o usuário pode criar federações
  static bool canCreateFederation(User user) {
    // Apenas ADM MASTER pode criar federações (conforme as regras unificadas)
    return user.role == Role.admMaster;
  }

  // Verificar se o usuário pode convidar outros para o clã
  static bool canInviteToClan(User user, String? clanId) {
    // ADM global ou Líder de Clã (no clã correto) pode convidar
    if (user.role == Role.admMaster) return true;
    if (user.clanRole == Role.leader && user.clanId == clanId) return true; // Líder do clã pode convidar
    return false;
  }

  // Verificar se o usuário pode expulsar membros do clã
  static bool canKickFromClan(User kicker, User target, String? clanId) {
    // ADM MASTER global pode expulsar qualquer one
    if (kicker.role == Role.admMaster) return true;
    // Líder de Clã (no clã correto) pode expulsar membros do seu clã
    if (kicker.clanRole == Role.leader && kicker.clanId == clanId && target.clanId == clanId) {
      // Líder não pode expulsar outro Líder do clã
      return target.clanRole != Role.leader;
    }
    return false;
  }

  // Verificar se o usuário pode ver estatísticas globais
  static bool canViewGlobalStats(User user) {
    return user.role == Role.admMaster;
  }

  // Verificar se o usuário pode moderar chats
  static bool canModerateChat(User user, String chatType, {String? clanId, String? federationId}) {
     // ADM MASTER global pode moderar qualquer chat
    if (user.role == Role.admMaster) return true;

    switch (chatType) {
      case 'clan':
        // Líder de Clã (no clã correto) pode moderar chat de clã
        return user.clanRole == Role.leader && user.clanId == clanId;
      case 'federation':
        // Líder de Federação (na federação correta) pode moderar chat de federação
        return user.federationRole == Role.leader && user.federationId == federationId;
      case 'global':
        // Apenas ADM global pode moderar chat global
        return user.role == Role.admMaster;
      default:
        return false;
    }
  }

  // Verificar se o usuário pode encerrar salas de voz (próprias ou de outros)
  static bool canEndOthersVoiceRoom(User user, String roomType, String creatorId, {String? clanId, String? federationId}) {
    // ADM MASTER global pode encerrar qualquer sala
    if (user.role == Role.admMaster) return true; // ADM MASTER tem permissão total

    // Criador pode encerrar sua própria sala
    if (user.id == creatorId) return true;

    // Líder de Clã pode encerrar salas do seu clã
    if (roomType == 'clan' && user.clanRole == Role.leader && user.clanId == clanId) return true;

    // Líder de Federação pode encerrar salas da sua federação
     if (roomType == 'federation' && user.federationRole == Role.leader && user.federationId == federationId) return true;


    return false; // Caso contrário, não pode encerrar
  }


  // Obter lista de ações disponíveis para o usuário
  static List<String> getAvailableActions(User user) {
    List<String> actions = [];

    // Ações básicas para todos os usuários logados (Role.user ou superior)
    if(user.role != Role.guest) { // Assumindo que Role.guest é para não logados
       actions.addAll([
        'send_global_message',
        'join_global_voice_room',
        'create_global_voice_room', // Se qualquer usuário logado pode criar global
       ]);
    }


    // Ações para membros de clã (qualquer papel de clã ou ADM MASTER global)
    if (user.clanId != null && user.clanRole != Role.guest || user.role == Role.admMaster) { // Membros de clã logados ou ADM MASTER
       actions.addAll([
        'send_clan_message',
        'join_clan_voice_room',
       ]);
    }

    // Ações para membros de federação (qualquer papel de federação ou ADM MASTER global) - precisa verificar se o usuário está na federação e não é guest
    if (user.federationId != null || user.role == Role.admMaster) {
       actions.addAll([
        'send_federation_message',
       ]);
    }

    // Ações específicas para Líderes de Clã
    if (user.clanRole == Role.leader) {
       actions.addAll([
        'create_clan_voice_room',
        'manage_clan', // Gerenciar o próprio clã
        'invite_to_clan', // Líder pode convidar
        'kick_from_clan', // Líder pode expulsar
        'moderate_clan_chat', // Líder pode moderar chat
      ]);
    }

     // Ações específicas para Sub-Líderes de Clã
    if (user.clanRole == Role.subLeader) {
       actions.addAll([
         'manage_clan', // Sub-Líderes também podem gerenciar o clã? Ajustar lógica
         'kick_from_clan', // Sub-Líderes podem expulsar? (Conforme sua regra)
         'moderate_clan_chat', // Sub-Líderes podem moderar chat? (Conforme sua regra)
       ]);
    }


    // Ações específicas para Líderes de Federação
    if (user.federationRole == Role.leader) {
       actions.addAll([
         'manage_federation', // Gerenciar a própria federação (Role.leader)
         'invite_to_federation', // Se houver convites para federação
         'kick_from_federation', // Se houver expulsão de federação
         'moderate_federation_chat', // Moderar chat de federação
         'add_clan_to_federation', // Gerenciamento de clãs na federação
         'remove_clan_from_federation', // Gerenciamento de clãs na federação
         'promote_to_subleader_federation', // Gerenciamento de membros da federação
         'demote_subleader_federation', // Gerenciamento de membros da federação
         'transfer_leadership_federation', // Transferência de liderança
         'add_ally', // Gerenciamento de relações diplomáticas
         'add_enemy', // Gerenciamento de relações diplomáticas
         'remove_ally', // Gerenciamento de relações diplomáticas
         'remove_enemy', // Gerenciamento de relações diplomáticas
         'update_federation_banner', // Customização da federação
       ]);
    }

    // Ações específicas para Sub-Líderes de Federação
     if (user.federationRole == Role.subLeader) {
        actions.addAll([
          'manage_federation', // Sub-Líderes também podem gerenciar a federação?
          'moderate_federation_chat', // Sub-Líderes podem moderar chat?
        ]);
     }


    // Ações específicas para ADM Geral
    if (user.role == Role.admMaster) { // ADM MASTER tem acesso a todas as ações administrativas e de gerenciamento
      actions.addAll([
        'access_admin_panel',
        'create_clan', // ADM MASTER pode criar clãs
        'create_federation', // ADM MASTER pode criar federações
        'manage_any_clan', // ADM pode gerenciar qualquer clã
        'manage_any_federation', // ADM pode gerenciar qualquer federação
        'promote_user_global', // ADM MASTER pode promover globalmente
        'remove_user_global', // ADM MASTER pode remover globalmente
        'view_global_stats', // ADM MASTER pode ver estatísticas globais
        'moderate_global_chat', // ADM MASTER pode moderar chat global
        'create_admin_voice_room', // ADM MASTER pode criar salas de admin
        'join_admin_voice_room', // ADM MASTER pode entrar em salas de admin
        'end_any_voice_room', // ADM MASTER pode encerrar qualquer sala de voz
         // Não é necessário duplicar as ações de Líder/SubLíder aqui, pois as verificações já tratam Role.admMaster.
      ]);
    }


    Logger.info('Available actions for user ${user.username} (Global: ${user.role}, Clan: ${user.clanRole}, Federation: ${user.federationRole}): $actions');
    return actions;
  }

  // Verificar se o usuário tem uma ação específica
  static bool hasAction(User user, String action) {
    return getAvailableActions(user).contains(action);
  }
}
