import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

/// PermissionService é a autoridade central para todas as verificações de permissão.
/// Ele é instanciado com um AuthProvider para acessar dinamicamente o usuário atual.
class PermissionService {
  final AuthProvider _authProvider;

  PermissionService({required AuthProvider authProvider}) : _authProvider = authProvider;

  /// Getter privado para acessar de forma segura o usuário logado.
  User? get _currentUser => _authProvider.currentUser;

  // ===================================================================
  // MÉTODOS EXISTENTES (JÁ ESTAVAM CORRETOS)
  // ===================================================================

  /// Verifica se o usuário pode gerenciar um clã específico (editar, etc.).
  bool canManageClan(Clan clan) {
    final user = _currentUser;
    if (user == null) return false;
    if (user.role == Role.admMaster) return true;
    return user.clanRole == Role.leader && user.clanId == clan.id;
  }

  /// Verifica se o usuário pode gerenciar uma federação específica.
  bool canManageFederation(Federation federation) {
    final user = _currentUser;
    if (user == null) return false;
    if (user.role == Role.admMaster) return true;
    return user.federationRole == Role.leader && user.federationId == federation.id;
  }

  /// Verifica se o usuário tem permissão para ver o painel de administração.
  bool canAccessAdminPanel() {
    final user = _currentUser;
    if (user == null) return false;
    return user.role == Role.admMaster;
  }

  /// Verifica se o usuário pode declarar guerra a partir de um clã.
  bool canDeclareWar(Clan fromClan) {
    final user = _currentUser;
    if (user == null) return false;
    return user.role == Role.admMaster || (user.clanRole == Role.leader && user.clanId == fromClan.id);
  }

  // ===================================================================
  // NOVOS MÉTODOS (ADICIONADOS PARA CORRIGIR OS ERROS)
  // A LÓGICA INTERNA É UM EXEMPLO E PRECISA SER AJUSTADA.
  // ===================================================================

  /// Verifica se o usuário pode criar um clã.
  bool canCreateClan() {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: Apenas ADM_MASTER ou líderes de federação podem criar clãs.
    return user.role == Role.admMaster || user.federationRole == Role.leader;
  }

  /// Verifica se o usuário pode criar uma federação.
  bool canCreateFederation() {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: Apenas ADM_MASTER pode criar federações.
    return user.role == Role.admMaster;
  }

  /// Verifica se o usuário pode convidar alguém para um clã.
  bool canInviteToClan(Clan clan) {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: ADM_MASTER, Líderes ou Oficiais do clã podem convidar.
    if (user.role == Role.admMaster) return true;
    if (user.clanId != clan.id) return false;
    return user.clanRole == Role.leader || user.clanRole == Role.officer;
  }

  /// Verifica se o usuário pode moderar o chat.
  bool canModerateChat() {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: Apenas ADM_MASTER pode moderar.
    return user.role == Role.admMaster;
  }

  /// Verifica se o usuário pode ver estatísticas globais.
  bool canViewGlobalStats() {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: Todos podem ver estatísticas globais. Mude se necessário.
    return true;
  }

  /// Verifica se o usuário pode criar uma sala de voz.
  bool canCreateVoiceRoom() {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: Todos os usuários logados podem criar salas de voz.
    return true;
  }

  /// Verifica se o usuário pode entrar em uma sala de voz.
  bool canJoinVoiceRoom() {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: Todos os usuários logados podem entrar em salas de voz.
    return true;
  }

  /// Verifica se o usuário pode encerrar a sala de voz de outros.
  bool canEndOthersVoiceRoom() {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: Apenas ADM_MASTER pode.
    return user.role == Role.admMaster;
  }

  /// Verifica se o usuário pode enviar mensagens.
  bool canSendMessage() {
    final user = _currentUser;
    if (user == null) return false;
    // Exemplo: Todos os usuários logados podem enviar mensagens.
    return true;
  }
  
  /// Método genérico para futuras permissões baseadas em strings.
  bool hasAction(String actionName) {
      final user = _currentUser;
      if (user == null) return false;
      // Exemplo: Apenas ADM_MASTER tem ações genéricas.
      // Você pode expandir isso com um switch(actionName) para mais ações.
      return user.role == Role.admMaster;
  }
}