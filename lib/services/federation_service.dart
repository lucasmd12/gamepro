import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class FederationService extends ChangeNotifier {
  final ApiService _apiService;
  
  List<Federation> _federations = [];
  bool _isLoading = false;

  FederationService(this._apiService);

  List<Federation> get federations => _federations;
  bool get isLoading => _isLoading;

  // ==================== INÍCIO DA CORREÇÃO 1 ====================
  Future<List<Federation>> getAllFederations({int page = 1, int limit = 10}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Adicionando os parâmetros de paginação na URL da API
      final endpoint = '/api/federations?page=$page&limit=$limit';
      final response = await _apiService.get(endpoint, requireAuth: true);

      if (response != null && response['success'] == true && response['data'] is List) {
        final List<dynamic> federationsData = response['data'];
        final newFederations = federationsData.map((json) => Federation.fromJson(json)).toList();
        
        // A tela gerencia a adição de itens, o serviço apenas retorna o que foi buscado.
        // Atualizamos a lista interna do serviço se for a primeira página.
        if (page == 1) {
          _federations = newFederations;
        }
        
        return newFederations;
      }
    } catch (e) {
      debugPrint('Error fetching all federations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return []; // Retorna lista vazia em caso de erro
  }
  // ===================== FIM DA CORREÇÃO DE PAGINAÇÃO ======================

  Future<Federation?> getFederationDetails(String federationId) async {
    try {
      final response = await _apiService.get('/api/federations/$federationId', requireAuth: false);
      if (response != null && response['success'] == true && response['data'] != null) {
        return Federation.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error fetching federation details: $e');
    }
    return null;
  }

  // ==================== INÍCIO DA CORREÇÃO 2 ====================
  Future<Federation?> createFederation(String name, String? description) async {
    // Construindo o mapa de dados aqui dentro do método
    final Map<String, dynamic> federationData = {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    };

    try {
      final response = await _apiService.post('/api/federations', federationData, requireAuth: true);
      if (response != null && response["success"] == true && response["data"] != null) {
        final newFederation = Federation.fromJson(response["data"]);
        // Não precisa notificar listeners aqui, a tela vai recarregar a lista
        return newFederation;
      } else {
        Logger.error('Failed to create federation. Response: $response');
      }
    } catch (e) {
      debugPrint("Error creating federation: $e");
    }
    return null;
  }
  // ===================== FIM DA CORREÇÃO DE CRIAÇÃO ======================

  Future<bool> deleteFederation(String federationId) async {
    Logger.info("Attempting to delete federation with ID: $federationId");
    try {
      final response = await _apiService.delete("/api/federations/$federationId", requireAuth: true);
      if (response != null && response["success"] == true) {
        Logger.info("Federation with ID $federationId deleted successfully.");
        _federations.removeWhere((fed) => fed.id == federationId); // Remove da lista local
        notifyListeners();
        return true;
      } else {
        Logger.warning("Failed to delete federation with ID $federationId. Response: $response");
        return false;
      }
    } catch (e, s) {
      Logger.error("Error deleting federation with ID $federationId:", error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> updateFederation(String federationId, Map<String, dynamic> updateData) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId", updateData, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error updating federation: $e");
    }
    return false;
  }

  Future<bool> addClanToFederation(String federationId, String clanId) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId/add-clan/$clanId", {}, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error adding clan to federation: $e");
    }
    return false;
  }

  Future<bool> removeClanFromFederation(String federationId, String clanId) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId/remove-clan/$clanId", {}, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error removing clan from federation: $e");
    }
    return false;
  }

  Future<bool> promoteToSubLeader(String federationId, String userId) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId/promote-subleader/$userId", {}, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error promoting user to sub-leader: $e");
    }
    return false;
  }

  Future<bool> demoteSubLeader(String federationId, String userId) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId/demote-subleader/$userId", {}, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error demoting sub-leader: $e");
    }
    return false;
  }

  Future<bool> transferFederationLeadership(String federationId, String newLeaderUserId) async {
    try {
      final response = await _apiService.put('/api/federations/$federationId/leader', {'newLeaderId': newLeaderUserId}, requireAuth: true);
      if (response != null && (response is Map<String, dynamic> && response.containsKey('success') && response['success'] == true || response == '')) {
        Logger.info('Federation $federationId leadership transferred successfully to $newLeaderUserId.');
        return true;
      } else {
        Logger.warning('Failed to transfer leadership for federation $federationId: ${response["msg"] ?? "Unknown error"}');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error transferring federation leadership:', error: e, stackTrace: s);
      return false;
    }
  }
  Future<bool> addAlly(String federationId, String allyId) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId/ally/$allyId", {}, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error adding ally: $e");
    }
    return false;
  }

  Future<bool> addEnemy(String federationId, String enemyId) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId/enemy/$enemyId", {}, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error adding enemy: $e");
    }
    return false;
  }

  Future<bool> updateFederationBanner(String federationId, String bannerPath) async {
    try {
      debugPrint("Banner update for federation $federationId with path $bannerPath");
      // TODO: Implementar upload de arquivo multipart/form-data
      return false;
    } catch (e) {
      debugPrint("Error updating federation banner: $e");
      return false;
    }
  }

  Future<bool> removeAlly(String federationId, String allyId) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId/remove-ally/$allyId", {}, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error removing ally: $e");
    }
    return false;
  }

  Future<bool> removeEnemy(String federationId, String enemyId) async {
    try {
      final response = await _apiService.put("/api/federations/$federationId/remove-enemy/$enemyId", {}, requireAuth: true);
      if (response != null && response["success"] == true) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error removing enemy: $e");
    }
    return false;
  }
}
