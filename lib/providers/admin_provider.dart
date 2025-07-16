import 'package:flutter/foundation.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/services/admin_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;

  List<User> _users = [];
  List<Clan> _clans = [];
  List<Federation> _federations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  List<Clan> get clans => _clans;
  List<Federation> get federations => _federations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AdminProvider(this._adminService);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Gerenciamento de Usuários
  Future<void> fetchAllUsers() async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      _users = await _adminService.getAllUsers();
      Logger.info('AdminProvider: Usuários carregados com sucesso.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao carregar usuários: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao carregar usuários', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final updatedUser = await _adminService.updateUserRole(userId, newRole);
      _users = _users.map((user) => user.id == userId ? updatedUser : user).toList();
      Logger.info('AdminProvider: Papel do usuário $userId atualizado para $newRole.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao atualizar papel do usuário: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao atualizar papel do usuário', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> banUser(String userId) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await _adminService.banUser(userId);
      _users.removeWhere((user) => user.id == userId); // Ou atualize o status do usuário
      Logger.info('AdminProvider: Usuário $userId banido.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao banir usuário: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao banir usuário', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unbanUser(String userId) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await _adminService.unbanUser(userId);
      // Re-fetch users or update user status locally if your API returns the updated user
      await fetchAllUsers(); 
      Logger.info('AdminProvider: Usuário $userId desbanido.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao desbanir usuário: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao desbanir usuário', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  // Gerenciamento de Clãs
  Future<void> fetchAllClans() async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      _clans = await _adminService.getAllClans();
      Logger.info('AdminProvider: Clãs carregados com sucesso.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao carregar clãs: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao carregar clãs', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createClan(Map<String, dynamic> clanData) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final newClan = await _adminService.createClan(clanData);
      _clans.add(newClan);
      Logger.info('AdminProvider: Clã criado com sucesso: ${newClan.name}.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao criar clã: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao criar clã', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateClan(String clanId, Map<String, dynamic> clanData) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final updatedClan = await _adminService.updateClan(clanId, clanData);
      _clans = _clans.map((clan) => clan.id == clanId ? updatedClan : clan).toList();
      Logger.info('AdminProvider: Clã $clanId atualizado.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao atualizar clã: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao atualizar clã', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteClan(String clanId) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await _adminService.deleteClan(clanId);
      _clans.removeWhere((clan) => clan.id == clanId);
      Logger.info('AdminProvider: Clã $clanId deletado.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao deletar clã: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao deletar clã', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  // Gerenciamento de Federações
  Future<void> fetchAllFederations() async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      _federations = await _adminService.getAllFederations();
      Logger.info('AdminProvider: Federações carregadas com sucesso.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao carregar federações: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao carregar federações', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createFederation(Map<String, dynamic> federationData) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final newFederation = await _adminService.createFederation(federationData);
      _federations.add(newFederation);
      Logger.info('AdminProvider: Federação criada com sucesso: ${newFederation.name}.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao criar federação: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao criar federação', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateFederation(String federationId, Map<String, dynamic> federationData) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final updatedFederation = await _adminService.updateFederation(federationId, federationData);
      _federations = _federations.map((federation) => federation.id == federationId ? updatedFederation : federation).toList();
      Logger.info('AdminProvider: Federação $federationId atualizada.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao atualizar federação: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao atualizar federação', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteFederation(String federationId) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      await _adminService.deleteFederation(federationId);
      _federations.removeWhere((federation) => federation.id == federationId);
      Logger.info('AdminProvider: Federação $federationId deletada.');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao deletar federação: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao deletar federação', error: e, stackTrace: stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  // Outras funcionalidades administrativas (estatísticas, atividades)
  Future<Map<String, dynamic>> getSystemStats() async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final stats = await _adminService.getSystemStats();
      Logger.info('AdminProvider: Estatísticas do sistema carregadas.');
      return stats;
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao carregar estatísticas do sistema: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao carregar estatísticas do sistema', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final activities = await _adminService.getRecentActivities();
      Logger.info('AdminProvider: Atividades recentes carregadas.');
      return activities;
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao carregar atividades recentes: ${e.toString()}');
      Logger.error('AdminProvider: Erro ao carregar atividades recentes', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}


