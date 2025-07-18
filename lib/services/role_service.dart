// Removed Firestore import
import '../models/user_model.dart'; // Import User for type reference
import '../services/api_service.dart'; // Import ApiService
import '../utils/logger.dart'; // Use Logger
import '../models/role_model.dart'; // Import Role enum

class RoleService {
  final ApiService _apiService; // Inject ApiService

  RoleService(this._apiService);

  // Obter todos os usuários (GET /api/users)
  // This might be better placed in a UserService or AdminService
  Future<List<User>> getAllUsers() async {
    try {
      // Adjust endpoint and query parameters as needed (e.g., for sorting, pagination)
      final response = await _apiService.get('/api/users?sortBy=joinDate&order=desc');
      if (response != null && response is List) {
        final users = response.map((data) => User.fromJson(data)).toList();
        Logger.info('Buscou ${users.length} usuários via API.');
        return users;
      } else {
        Logger.warning('API não retornou lista de usuários ou formato inválido.');
        return [];
      }
    } catch (e, s) {
      Logger.error('Erro ao buscar todos os usuários via API', error: e, stackTrace: s);
      return []; // Return empty list on error
    }
  }

  // Atualizar função do usuário (PUT /api/users/{userId}/role or PATCH /api/users/{userId})
  Future<bool> updateUserRole(String userId, Role newRole) async {
    try {
      // Use PATCH if only updating the role
      final response = await _apiService.patch('/api/users/$userId', {'role': newRole.name}); // Send enum name as string
      final success = response != null;
      if (success) {
        Logger.info('Função do usuário $userId atualizada para ${newRole.name} via API.');
      } else {
        Logger.warning('Falha ao atualizar função do usuário $userId via API.');
      }
      return success;
    } catch (e, s) {
      Logger.error('Erro ao atualizar função do usuário $userId via API', error: e, stackTrace: s);
      return false;
    }
  }

  // Verificar se o usuário tem permissão para gerenciar funções
  // This logic should ideally live within the AuthService or be based on the current user's role
  // fetched during authentication.
  // This method might require fetching the user's profile first.
  Future<bool> canManageRoles(String userId) async {
    try {
      // Fetch user details first (assuming an endpoint exists)
      final response = await _apiService.get('/api/users/$userId');
      if (response != null) {
        final user = User.fromJson(response);
        // Check role based on the fetched user data
        final canManage = user.role == Role.admMaster || user.role == Role.leader; // Example roles
        Logger.info('User $userId can manage roles: $canManage');
        return canManage;
      } else {
        Logger.warning('Não foi possível buscar dados do usuário $userId para verificar permissões.');
        return false;
      }
    } catch (e, s) {
      Logger.error('Erro ao verificar permissões de gerenciamento de roles para $userId', error: e, stackTrace: s);
      return false;
    }
  }

  // Verificar se o usuário é o dono (Federation Admin)
  // Similar to canManageRoles, this relies on fetching user data.
  Future<bool> isOwner(String userId) async {
     try {
      final response = await _apiService.get('/api/users/$userId');
      if (response != null) {
        final user = User.fromJson(response);        final isOwner = user.role == Role.admMaster; // Assuming federationAdmin is the 'owner'
        Logger.info('User $userId is owner: $isOwner');
        return isOwner;
      } else {
        Logger.warning('Não foi possível buscar dados do usuário $userId para verificar se é owner.');
        return false;
      }
    } catch (e, s) {
      Logger.error('Erro ao verificar se usuário $userId é owner', error: e, stackTrace: s);
      return false;
    }
  }
}