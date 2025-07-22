import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/channel_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/member_model.dart';
import 'package:lucasbeatsfederacao/models/clan_war_model.dart';
import 'package:flutter/material.dart'; // Import for ChangeNotifier


class ClanService with ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  List<Clan> _clans = [];
  bool _isLoading = false;

  ClanService(this._apiService, this._authService);
  List<Clan> get clans => _clans;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ==================== INÍCIO DA CORREÇÃO 1 ====================
  Future<List<Clan>> fetchClansByFederation(String federationId, {int page = 1, int limit = 10}) async {
    _setLoading(true);
    try {
      // Adicionando os parâmetros de paginação na URL da API
      final endpoint = '/api/federations/$federationId/clans?page=$page&limit=$limit';
      final response = await _apiService.get(endpoint, requireAuth: true);
      
      if (response != null && response['success'] == true && response['data'] is List) {
        // Se for a primeira página, substitui a lista. Se não, adiciona.
        // A tela já gerencia isso, então o serviço pode apenas retornar a nova lista.
        final newClans = (response['data'] as List).map((json) => Clan.fromMap(json)).toList();
        Logger.info('Fetched ${newClans.length} clans for federation $federationId on page $page.');
        _clans = newClans; // Atualiza a lista interna do serviço
        return newClans;
      } else {
        Logger.warning('Unexpected response format when fetching clans for federation $federationId: $response');
        return [];
      }
    } catch (e, s) {
      Logger.error('Error fetching clans for federation $federationId', error: e, stackTrace: s);
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // ==================== INÍCIO DA CORREÇÃO 2 ====================
  Future<List<Clan>> getAllClans({int page = 1, int limit = 10}) async {
    _setLoading(true);
    try {
      // Adicionando os parâmetros de paginação na URL da API
      final endpoint = '/api/clans?page=$page&limit=$limit';
      final response = await _apiService.get(endpoint, requireAuth: true);

      if (response != null && response['success'] == true && response['data'] is List) {
        final clansData = (response['data'] as List);
        final newClans = clansData.map((json) => Clan.fromMap(json)).toList();
        Logger.info('Fetched ${newClans.length} total clans on page $page.');
        _clans = newClans; // Atualiza a lista interna do serviço
        return newClans;
      } else {
        Logger.warning('Unexpected response format when fetching all clans: $response');
        return [];
      }
    } catch (e, s) {
      Logger.error('Error fetching all clans', error: e, stackTrace: s);
      return [];
    } finally {
      _setLoading(false);
    }
  }
  // ===================== FIM DAS CORREÇÕES DE PAGINAÇÃO ======================

  Future<Clan?> getClanDetails(String clanId) async {
    try {
      final response = await _apiService.get('/api/clans/$clanId', requireAuth: true);
      if (response != null) {
        return Clan.fromMap(response);
      }
    } catch (e) {
      Logger.error('Error fetching clan details for $clanId: $e');
    }
    return null;
  }

  Future<List<Member>> getClanMembers(String clanId) async {
    try {
      final response = await _apiService.get('/api/clans/$clanId/members', requireAuth: true);
      if (response != null && response is Map<String, dynamic> && response.containsKey('members') && response['members'] is List) {
        final membersData = response['members'] as List;
        List<Member> members = [];
        for (var memberJson in membersData) {
          members.add(Member.fromJson(memberJson));
        }
        Logger.info('Fetched ${members.length} members for clan $clanId.');
        return members;
      } else {
        Logger.warning('Unexpected response format when fetching members for clan $clanId: $response');
      }
    } catch (e, s) {
      Logger.error('Error fetching members for clan $clanId', error: e, stackTrace: s);
    }
    return [];
  }

  Future<List<Channel>> getClanChannels(String clanId) async {
    try {
      final endpoint = '/api/voice-channels/clan/$clanId';
      final response = await _apiService.get(endpoint, requireAuth: true);
      if (response != null && response is Map<String, dynamic> && response.containsKey('clanVoiceChannels') && response['clanVoiceChannels'] is List) {
        final channels = (response['clanVoiceChannels'] as List).map((data) => Channel.fromMap(data)).toList();
        Logger.info('Fetched ${channels.length} voice channels for clan $clanId.');
        return channels;
      } else {
        Logger.warning('Unexpected response format when fetching voice channels for clan $clanId: $response');
      }
    } catch (e, s) {
      Logger.error('Error fetching voice channels for clan $clanId', error: e, stackTrace: s);
    }
    return [];
  }

  Future<bool> addMember(String clanId, String userIdToAdd) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null) return false;

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    bool isLeader = currentUser.id == clan.leaderId;
    bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);

    if (!(isLeader || isSubLeader || currentUser.role == Role.admMaster)) {
      Logger.warning('Permission Denied [Add Member]: Only Leader/SubLeader can add members.');
      return false;
    }

    try {
      final response = await _apiService.post('/api/clans/$clanId/members', {'userId': userIdToAdd}, requireAuth: true);
      return response != null;
    } catch (e) {
      Logger.error('Error adding member $userIdToAdd to clan $clanId: $e');
      return false;
    }
  }

  Future<bool> removeMember(String userIdToRemove) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(currentUser?.clanId ?? '');
    if (currentUser == null || clan == null) {
      Logger.warning("Permission Denied [Remove Member]: Current user or clan not found.");
      return false;
    }

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    final clanId = currentUser.clanId!;

    try {
      await _apiService.delete('/api/clans/$clanId/members/$userIdToRemove', requireAuth: true);
      return true;
    } catch (e) {
      Logger.error('Error removing member $userIdToRemove from clan $clanId: $e');
      rethrow;
    }
  }

  Future<bool> promoteMember(String userIdToPromote) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(currentUser?.clanId ?? '');
    if (currentUser == null || clan == null) {
      Logger.warning("Permission Denied [Promote Member]: Current user or clan not found.");
      return false;
    }

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    final clanId = currentUser.clanId!;

    try {
      final response = await _apiService.put('/api/clans/$clanId/members/$userIdToPromote/promote', {}, requireAuth: true);
      if (response != null && response['success'] == true) {
        return true;
      } else {
        Logger.error('Failed to promote member $userIdToPromote in clan $clanId. Response: $response');
        return false;
      }
    } catch (e) {
      Logger.error('Error promoting member $userIdToPromote in clan $clanId: $e');
      rethrow;
    }
  }

  Future<bool> demoteMember(String userIdToDemote) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(currentUser?.clanId ?? '');
    if (currentUser == null || clan == null) {
      Logger.warning("Permission Denied [Demote Member]: Current user or clan not found.");
      return false;
    }

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }
    final clanId = currentUser.clanId!;

    bool isLeader = currentUser.id == clan.leaderId;
    bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);

    if (!(isLeader || isSubLeader || currentUser.role == Role.admMaster)) {
      Logger.warning('Permission Denied [Demote Member]: Only Leader/SubLeader can demote members.');
      return false;
    }

    try {
      final response = await _apiService.put('/api/clans/$clanId/members/$userIdToDemote/demote', {}, requireAuth: true);
      return response != null;
    } catch (e) {
      Logger.error('Error demoting member $userIdToDemote in clan $clanId: $e');
      rethrow;
    }
  }

  Future<Clan?> getClanById(String clanId) async {
    return await getClanDetails(clanId);
  }

  Future<Clan?> updateClanDetails(String clanId, {String? name, String? bannerImageUrl, String? tag}) async {
    final currentUser = _authService.currentUser;
    final clan = await getClanDetails(clanId);
    if (currentUser == null || clan == null) return null;

    String? currentUserRoleInClan;
    if (clan.memberRoles != null) {
      for (var roleMap in clan.memberRoles!) {
        if (roleMap['user'] == currentUser.id) {
          currentUserRoleInClan = roleMap['role'];
          break;
        }
      }
    }

    bool isLeader = currentUser.id == clan.leaderId;
    bool isSubLeader = currentUserRoleInClan == roleToString(Role.subLeader);

    if (!(isLeader || isSubLeader || currentUser.role == Role.admMaster)) {
      Logger.warning('Permission Denied [Update Clan Details]: Only Leader/SubLeader can update details.');
      return null;
    }

    Map<String, dynamic> dataToUpdate = {};
    if (name != null) dataToUpdate['name'] = name;
    if (bannerImageUrl != null) dataToUpdate['bannerImageUrl'] = bannerImageUrl;
    if (tag != null) dataToUpdate['tag'] = tag;

    if (dataToUpdate.isEmpty) {
      Logger.info('No details provided to update for clan $clanId.');
      return clan;
    }

    try {
      final response = await _apiService.put('/api/clans/$clanId', dataToUpdate, requireAuth: true);
      if (response != null) {
        return Clan.fromMap(response);
      }
    } catch (e) {
      Logger.error('Error updating details for clan $clanId: $e');
    }
    return null;
  }

  // ==================== INÍCIO DA CORREÇÃO 3 ====================
  Future<Clan?> createClan(String name, String? tag) async {
    // Construindo o mapa de dados aqui dentro do método
    final Map<String, dynamic> clanData = {
      'name': name,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
    };

    Logger.info('Attempting to create clan with data: $clanData');
    try {
      final response = await _apiService.post('/api/clans', clanData, requireAuth: true);
      if (response != null && response['success'] == true && response['data'] is Map<String, dynamic>) {
        Logger.info('Clan created successfully: ${response['data']['name']}');
        return Clan.fromMap(response['data']);
      } else {
         Logger.warning('Failed to create clan. Response: $response');
         return null;
      }
    } catch (e, s) {
      Logger.error('Error creating clan:', error: e, stackTrace: s);
      return null;
    }
  }
  // ===================== FIM DA CORREÇÃO DE CRIAÇÃO ======================

  Future<bool> deleteClan(String clanId) async {
    Logger.info('Attempting to delete clan with ID: $clanId');
    try {
      final response = await _apiService.delete('/api/clans/$clanId', requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Clan with ID $clanId deleted successfully.');
        return true;
      } else {
        Logger.warning('Failed to delete clan with ID $clanId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error deleting clan with ID $clanId:', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> transferClanLeadership(String clanId, String newLeaderUserId) async {
    Logger.info('Attempting to transfer leadership for clan ID: $clanId to user ID: $newLeaderUserId');
    try {
      final response = await _apiService.put('/api/clans/$clanId/leader', {'newLeaderId': newLeaderUserId}, requireAuth: true);
      if (response != null && (response is Map<String, dynamic> && response.containsKey('success') && response['success'] == true || response == '')) {
        Logger.info('Clan ID $clanId leadership transferred successfully to user ID $newLeaderUserId.');
        return true;
      } else {
        Logger.warning('Failed to transfer leadership for clan ID $clanId. Response: $response');
        return false;
      }
    } catch (e, s) {
      Logger.error('Error transferring clan leadership for clan ID $clanId:', error: e, stackTrace: s);
      return false;
    }
  }

  Future<ClanWarModel?> declareWar(String challengedClanId, String rules) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.clanId == null) return null;

    final response = await _apiService.post(
      '/api/clan-wars/declare',
      {'challengerClanId': currentUser.clanId, 'challengedClanId': challengedClanId, 'rules': rules},
      requireAuth: true,
    );

    if (response != null && response['success'] == true) {
      return ClanWarModel.fromMap(response['data']);
    }
    return null;
  }

  Future<ClanWarModel?> acceptWar(String warId) async {
    final response = await _apiService.put('/api/clan-wars/$warId/accept', {}, requireAuth: true);
    if (response != null && response['success'] == true) {
      return ClanWarModel.fromMap(response['data']);
    }
    return null;
  }

  Future<ClanWarModel?> rejectWar(String warId) async {
    final response = await _apiService.put('/api/clan-wars/$warId/reject', {}, requireAuth: true);
    if (response != null && response['success'] == true) {
      return ClanWarModel.fromMap(response['data']);
    }
    return null;
  }

  Future<ClanWarModel?> reportWarResult(String warId, String winnerClanId, String loserClanId, Map<String, int> score) async {
    final response = await _apiService.post(
      '/api/clan-wars/$warId/report',
      {'winnerClanId': winnerClanId, 'loserClanId': loserClanId, 'score': score},
      requireAuth: true,
    );

    if (response != null && response['success'] == true && response['data'] is Map<String, dynamic>) {
      return ClanWarModel.fromMap(response['data']);
    }
    return null;
  }

  Future<ClanWarModel?> cancelWar(String warId, String reason) async {
    final response = await _apiService.post('/api/clan-wars/$warId/cancel', {'reason': reason}, requireAuth: true);
    if (response != null && response['success'] == true) {
      return ClanWarModel.fromMap(response['data']);
    }
    return null;
  }

  Future<List<ClanWarModel>> getActiveWars() async {
    final response = await _apiService.get('/api/clan-wars/active', requireAuth: true);
    if (response != null && response['success'] == true && response['data'] is List) {
      return (response['data'] as List).map((json) => ClanWarModel.fromMap(json)).toList();
    }
    return [];
  }
}
