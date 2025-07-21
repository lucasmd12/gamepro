import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

/// PermissionService agora é uma classe de instância que depende do AuthProvider.
/// Isso permite que ele acesse dinamicamente o usuário atual sem precisar
/// passá-lo como parâmetro em cada chamada de método.
class PermissionService {
  final AuthProvider _authProvider;

  PermissionService({required AuthProvider authProvider}) : _authProvider = authProvider;

  /// Getter privado para acessar de forma segura o usuário logado.
  User? get _currentUser => _authProvider.currentUser;

  /// Verifica se o usuário pode gerenciar um clã específico.
  /// Gerenciar inclui editar detalhes, gerenciar membros, etc.
  bool canManageClan(Clan clan) {
    final user = _currentUser;
    if (user == null) return false;

    // 1. O ADM Master pode gerenciar qualquer clã.
    if (user.role == Role.admMaster) {
      Logger.info("[Permission] Granted: User is ADM_MASTER, can manage clan '${clan.name}'.");
      return true;
    }
    
    // 2. O Líder do clã pode gerenciar seu próprio clã.
    if (user.clanRole == Role.leader && user.clanId == clan.id) {
      Logger.info("[Permission] Granted: User is the leader of clan '${clan.name}'.");
      return true;
    }

    Logger.info("[Permission] Denied: User '${user.username}' cannot manage clan '${clan.name}'.");
    return false;
  }

  /// Verifica se o usuário pode gerenciar uma federação específica.
  bool canManageFederation(Federation federation) {
    final user = _currentUser;
    if (user == null) return false;

    // 1. O ADM Master pode gerenciar qualquer federação.
    if (user.role == Role.admMaster) {
      Logger.info("[Permission] Granted: User is ADM_MASTER, can manage federation '${federation.name}'.");
      return true;
    }
    
    // 2. O Líder da federação pode gerenciar sua própria federação.
    if (user.federationRole == Role.leader && user.federationId == federation.id) {
      Logger.info("[Permission] Granted: User is the leader of federation '${federation.name}'.");
      return true;
    }

    Logger.info("[Permission] Denied: User '${user.username}' cannot manage federation '${federation.name}'.");
    return false;
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

    // Apenas o ADM Master ou o líder do clã de origem podem declarar guerra.
    return user.role == Role.admMaster || (user.clanRole == Role.leader && user.clanId == fromClan.id);
  }

  // Futuramente, outros métodos de permissão podem ser adicionados aqui
  // seguindo o mesmo padrão. Ex:
  // bool canManageVoipChannel(Channel channel) { ... }
  // bool canModerateChat(String contextId) { ... }
}
