import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/models/invite_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class InviteService {
  final ApiService _apiService = ApiService();

  Future<List<InviteModel>> getMyInvites() async {
    try {
      final response = await _apiService.get('/api/invites/me');
      if (response['success'] == true) {
        return (response['invites'] as List)
            .map((inviteJson) => InviteModel.fromJson(inviteJson))
            .toList();
      } else {
        throw Exception(response['msg'] ?? 'Falha ao carregar convites');
      }
    } catch (e) {
      Logger.error('Erro ao obter meus convites', error: e);
      rethrow;
    }
  }

  Future<void> createInvite(String recipientId, String type, String targetId) async {
    try {
      final response = await _apiService.post('/api/invites', {
        'recipientId': recipientId,
        'type': type,
        'targetId': targetId,
      });
      if (response['success'] != true) {
        throw Exception(response['msg'] ?? 'Falha ao enviar convite');
      }
    } catch (e) {
      Logger.error('Erro ao criar convite', error: e);
      rethrow;
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    try {
      final response = await _apiService.put('/api/invites/$inviteId/accept', {});
      if (response['success'] != true) {
        throw Exception(response['msg'] ?? 'Falha ao aceitar convite');
      }
    } catch (e) {
      Logger.error('Erro ao aceitar convite', error: e);
      rethrow;
    }
  }

  Future<void> rejectInvite(String inviteId) async {
    try {
      final response = await _apiService.put('/api/invites/$inviteId/reject', {});
      if (response['success'] != true) {
        throw Exception(response['msg'] ?? 'Falha ao rejeitar convite');
      }
    } catch (e) {
      Logger.error('Erro ao rejeitar convite', error: e);
      rethrow;
    }
  }
}


