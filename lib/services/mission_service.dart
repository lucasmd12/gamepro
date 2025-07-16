import 'package:lucasbeatsfederacao/models/mission_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';

class MissionService {
  final ApiService _apiService;

  MissionService(this._apiService);

  Future<Mission> createMission({
    required String name,
    required String description,
    required String clanId,
    required DateTime scheduledTime,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/clan-missions',
        {
          'name': name,
          'description': description,
          'clanId': clanId,
          'scheduledTime': scheduledTime.toIso8601String(),
        },
        requireAuth: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        Logger.info("Mission created successfully: ${response['name']}");
        return Mission.fromMap(response);
      } else {
        throw Exception("Failed to create mission: Invalid response");
      }
    } catch (e) {
      Logger.error('Error creating mission', error: e);
      rethrow;
    }
  }

  Future<List<Mission>> getClanMissions(String clanId) async {
    if (clanId.isEmpty) return [];
    try {
      final response = await _apiService.get('/api/clan-missions/clan/$clanId', requireAuth: true);
      if (response != null && response is List) {
        return response.map((data) => Mission.fromMap(data)).toList();
      } else {
        throw Exception("Failed to get clan missions: Invalid response");
      }
    } catch (e) {
      Logger.error('Error fetching clan missions', error: e);
      rethrow;
    }
  }

  Future<Mission> getMissionById(String missionId) async {
    try {
      final response = await _apiService.get('/api/clan-missions/$missionId', requireAuth: true);
      if (response != null && response is Map<String, dynamic>) {
        return Mission.fromMap(response);
      } else {
        throw Exception("Failed to get mission by ID: Invalid response");
      }
    } catch (e) {
      Logger.error('Error fetching mission by ID', error: e);
      rethrow;
    }
  }

  Future<bool> confirmPresence(String missionId, String userId) async {
    try {
      final response = await _apiService.post(
        '/api/clan-missions/$missionId/confirm',
        {
          'userId': userId,
        },
        requireAuth: true,
      );
      return response != null;
    } catch (e) {
      Logger.error('Error confirming presence', error: e);
      return false;
    }
  }

  Future<bool> addStrategyMedia(String missionId, String mediaUrl) async {
    try {
      // NOTE: The backend API expects multipart/form-data for strategyImage.
      // This service method currently sends a JSON with 'mediaUrl'.
      // A proper implementation would require handling file upload (e.g., using Dio for multipart requests).
      // For now, this assumes 'mediaUrl' is a string that the backend can process, or it's a placeholder.
      final response = await _apiService.post(
        '/api/clan-missions/$missionId/strategy',
        {
          'strategyImage': mediaUrl, // This should be a file, not a URL string for multipart
        },
        requireAuth: true,
      );
      return response != null;
    } catch (e) {
      Logger.error('Error adding strategy media', error: e);
      return false;
    }
  }

  Future<bool> cancelMission(String missionId) async {
    try {
      final response = await _apiService.post('/api/clan-missions/$missionId/cancel', {}, requireAuth: true);
      return response != null;
    } catch (e) {
      Logger.error('Error canceling mission', error: e);
      return false;
    }
  }
}


