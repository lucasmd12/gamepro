import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Import Role and roleToString

class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<bool> updateUserStatus(String userId, String status) async {
    try {
      final response = await _apiService.put(
        '/api/users/$userId/status',
        {'status': status},
        requireAuth: true,
      );
      return response != null && (response is Map<String, dynamic> && response['success'] == true);
    } catch (e) {
      Logger.error('Erro ao atualizar status do usuário $userId', error: e);
      return false;
    }
  }
  Future<User?> getUserByUsername(String username) async {
    try {
      final response = await _apiService.get("/api/users/by-username?username=$username");
      if (response['success'] == true && response['data'] != null) {
        return User.fromJson(response['data']);
      } else {
        Logger.warning("Usuário com username $username não encontrado: ${response["msg"]}");
        return null;
      }
    } catch (e) {
      Logger.error("Erro ao buscar usuário por username", error: e);
      return null;
    }
  }

  Future<List<User>> getAllUsers({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get('/api/users?page=$page&limit=$limit', requireAuth: true);

      if (response != null && response is Map && response.containsKey('users') && response['users'] is List) {
        final List<dynamic> userData = response['users'];
        Logger.info('getAllUsers: Received ${userData.length} users from paginated response.');
        return userData.map((json) => User.fromJson(json)).toList();
      }
      Logger.warning('getAllUsers: Unexpected response format for paginated users: ${response.runtimeType}');
      return [];
    } catch (e) {
      Logger.error('Erro ao buscar todos os usuários (paginado)', error: e);
      return [];
    }
  }

  Future<bool> updateUserRole(String userId, Role newRole, {String? clanId, String? federationId}) async {
    try {
      final Map<String, dynamic> requestBody = {
        'role': roleToString(newRole),
      };
      if (clanId != null) requestBody['clanId'] = clanId;
      if (federationId != null) requestBody['federationId'] = federationId;

      final response = await _apiService.put(
        '/api/users/$userId/role',
 requestBody, requireAuth: true,
      );
      // API PUT requests might return 200 (OK) or 204 (No Content) on success
      return response != null && (response is Map<String, dynamic> && response['success'] == true);
    } catch (e) {
      Logger.error('Erro ao atualizar papel do usuário $userId', error: e);
      return false;
    }
  }

  Future<bool> assignClanToUser(String userId, String? clanId) async {
    try {
      final response = await _apiService.put(
        '/api/admin/users/$userId/assign-clan',
        {'clanId': clanId},
        requireAuth: true,
      );
      return response != null && response['success'] == true;
    } catch (e) {
      Logger.error('Erro ao atribuir clã ao usuário $userId', error: e);
      return false;
    }
  }

  Future<User?> updateUserProfile(String userId, {String? username, String? avatar}) async {
    try {
      final Map<String, dynamic> dataToUpdate = {};
      if (username != null) dataToUpdate['username'] = username;
      if (avatar != null) dataToUpdate['avatar'] = avatar;

      if (dataToUpdate.isEmpty) {
        Logger.info('No profile data provided to update for user $userId.');
        return null; // Or return current user if no changes
      }

      final response = await _apiService.put(
        '/api/users/$userId',
        dataToUpdate,
        requireAuth: true,
      );

      if (response != null && response['success'] == true && response['data'] != null) {
        return User.fromJson(response['data']);
      } else {
        Logger.warning('Failed to update user profile for $userId. Response: $response');
        return null;
      }
    } catch (e, st) {
      Logger.error('Error updating user profile for $userId', error: e, stackTrace: st);
      return null;
    }
  }
}


