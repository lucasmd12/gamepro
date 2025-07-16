import 'package:flutter/foundation.dart';
import 'package:lucasbeatsfederacao/models/qrr_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class QRRService extends ChangeNotifier {
  final ApiService _apiService;

  QRRService(this._apiService);

  Future<QRRModel?> createQRR(Map<String, dynamic> qrrData) async {
    try {
      final response = await _apiService.post('/api/qrrs', qrrData, requireAuth: true);
      if (response != null && response['success'] == true && response['data'] != null) {
        notifyListeners();
        return QRRModel.fromJson(response['data']);
      }
      // Log a resposta do backend se 'success' não for true ou 'data' for nulo
      Logger.error(
          'Failed to create QRR. Backend response: ${response != null ? response : 'null'}');

    } catch (e) {
      Logger.error('Error creating QRR', error: e);
    }
    return null;
  }

  Future<List<QRRModel>> getAllQRRs() async {
    try {
      final response = await _apiService.get('/api/qrrs', requireAuth: true);
      if (response != null && response['success'] == true && response['data'] is List) {
        final List<dynamic> qrrsData = response['data'];
        return qrrsData.map((json) => QRRModel.fromJson(json)).toList();
      }
    } catch (e) {
      Logger.error('Error fetching all QRRs', error: e);
    }
    return [];
  }

  Future<QRRModel?> getQRRById(String qrrId) async {
    try {
      final response = await _apiService.get('/api/qrrs/$qrrId', requireAuth: true);
      if (response != null && response['success'] == true && response['data'] != null) {
        return QRRModel.fromJson(response['data']);
      }
    } catch (e) {
      Logger.error('Error fetching QRR by ID', error: e);
    }
    return null;
  }

  Future<QRRModel?> updateQRR(String qrrId, Map<String, dynamic> updateData) async {
    try {
      final response = await _apiService.put('/api/qrrs/$qrrId', updateData, requireAuth: true);
      if (response != null && response['success'] == true && response['data'] != null) {
        notifyListeners();
        return QRRModel.fromJson(response['data']);
      }
    } catch (e) {
      Logger.error('Error updating QRR', error: e);
    }
    return null;
  }

  Future<bool> deleteQRR(String qrrId) async {
    try {
      final response = await _apiService.delete('/api/qrrs/$qrrId', requireAuth: true);
      if (response != null && response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      Logger.error('Error deleting QRR', error: e);
    }
    return false;
  }

  Future<bool> joinQRR(String qrrId, String userId) async {
    try {
      final response = await _apiService.post('/api/qrrs/$qrrId/join', {'userId': userId}, requireAuth: true);
      if (response != null && response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      Logger.error('Error joining QRR', error: e);
    }
    return false;
  }

  Future<bool> leaveQRR(String qrrId, String userId) async {
    try {
      final response = await _apiService.post('/api/qrrs/$qrrId/leave', {'userId': userId}, requireAuth: true);
      if (response != null && response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      Logger.error('Error leaving QRR', error: e);
    }
    return false;
  }

  Future<bool> markParticipantPresent(String qrrId, String userId, bool isPresent) async {
    try {
      final response = await _apiService.post("/api/qrrs/$qrrId/mark-present", {"userId": userId, "isPresent": isPresent}, requireAuth: true);
      if (response != null && response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      Logger.error('Error marking participant present', error: e);
    }
    return false;
  }

  Future<bool> updateParticipantPerformance(String qrrId, String userId, Map<String, dynamic> performanceData) async {
    try {
      final response = await _apiService.put('/api/qrrs/$qrrId/participant/$userId/performance', performanceData, requireAuth: true);
      if (response != null && response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      Logger.error('Error updating participant performance', error: e);
    }
    return false;
  }

  Future<bool> completeQRR(String qrrId, Map<String, dynamic> resultData) async {
    try {
      final response = await _apiService.post('/api/qrrs/$qrrId/complete', resultData, requireAuth: true);
      if (response != null && response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      Logger.error('Error completing QRR', error: e);
    }
    return false;
  }

  Future<bool> cancelQRR(String qrrId) async {
    try {
      final response = await _apiService.post('/api/qrrs/$qrrId/cancel', {}, requireAuth: true);
      if (response != null && response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      Logger.error('Error canceling QRR', error: e);
    }
    return false;
  }

  // Método vital para atualização de status
  Future<bool> updateQRRStatus(String qrrId, QRRStatus newStatus) async {
    try {
      final response = await _apiService.put('/api/qrrs/$qrrId/status', 
        {'status': newStatus.name}, 
        requireAuth: true
      );
      if (response != null && response['success'] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      Logger.error('Error updating QRR status', error: e);
    }
    return false;
  }

  Future<List<QRRModel>> getQRRsByClan(String clanId) async {
    try {
      final response = await _apiService.get("/api/qrrs/clan/$clanId", requireAuth: true);
      if (response != null && response['success'] == true && response['data'] is List) {
        final List<dynamic> qrrsData = response['data'];
        return qrrsData.map((json) => QRRModel.fromJson(json)).toList();
      }
    } catch (e) {
      Logger.error("Error fetching QRRs by clan", error: e);
    }
    return [];
  }
}


