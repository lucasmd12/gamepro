import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/mission_model.dart';
import 'package:lucasbeatsfederacao/services/mission_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class MissionProvider extends ChangeNotifier {
  final MissionService _missionService;
  
  List<Mission> _clanMissions = [];
  
  bool _isLoading = false;
  String? _error;

  MissionProvider(this._missionService);

  // Getters
  List<Mission> get clanMissions => _clanMissions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Carregar todas as missões
  Future<void> loadAllMissions(String userId, String? clanId) async {
    _setLoading(true);
    _error = null;

    try {
      _clanMissions = await _missionService.getClanMissions(clanId ?? '');
      Logger.info('Missões do clã carregadas: ${_clanMissions.length}');
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar missões: ${e.toString()}';
      Logger.error('Erro ao carregar missões', error: e);
    } finally {
      _setLoading(false);
    }
  }

  // Carregar apenas missões do clã (QRR)
  Future<void> loadClanMissions(String clanId) async {
    try {
      _clanMissions = await _missionService.getClanMissions(clanId);
      notifyListeners();
    } catch (e) {
      Logger.error('Erro ao carregar missões do clã', error: e);
    }
  }

  // Confirmar presença em missão QRR
  Future<bool> confirmPresence(String missionId, String userId) async {
    try {
      final success = await _missionService.confirmPresence(missionId, userId);
      if (success) {
        _addConfirmedMember(missionId, userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      Logger.error('Erro ao confirmar presença', error: e);
      return false;
    }
  }

  // Adicionar estratégia (imagem) em missão QRR
  Future<bool> addStrategyMedia(String missionId, String mediaUrl) async {
    try {
      final success = await _missionService.addStrategyMedia(missionId, mediaUrl);
      if (success) {
        _addStrategyMediaLocal(missionId, mediaUrl);
        notifyListeners();
      }
      return success;
    } catch (e) {
      Logger.error('Erro ao adicionar estratégia', error: e);
      return false;
    }
  }

  // Cancelar missão QRR
  Future<bool> cancelMission(String missionId) async {
    try {
      final success = await _missionService.cancelMission(missionId);
      if (success) {
        _updateMissionStatus(missionId, 'cancelled');
        notifyListeners();
      }
      return success;
    } catch (e) {
      Logger.error('Erro ao cancelar missão', error: e);
      return false;
    }
  }

  // Métodos privados para atualização local (simplificados para operar apenas em _clanMissions)
  // Nota: Em um cenário real, a atualização do estado local após confirmação/cancelamento
  // dependeria da resposta do backend. Esta é uma simplificação baseada nos métodos existentes.
  
  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _addConfirmedMember(String missionId, String userId) {
    for (var mission in _clanMissions) { 
      if (mission.id == missionId && !mission.confirmedMembers.contains(userId)) {
        mission.confirmedMembers.add(userId);
      }
    }
  }

  void _addStrategyMediaLocal(String missionId, String mediaUrl) {
    for (var mission in _clanMissions) {
      if (mission.id == missionId) {
        mission.strategyMediaUrls.add(mediaUrl);
      }
    }
  }

  void _updateMissionStatus(String missionId, String status) {
    _updateMissionInList(_clanMissions, missionId, status: status);
  }

  void _updateMissionInList(List<Mission> missions, String missionId, {String? status, int? currentProgress}) {
    final index = missions.indexWhere((mission) => mission.id == missionId);
    if (index != -1) {
      final mission = missions[index];
      missions[index] = mission.copyWith(
        status: status ?? mission.status,
        currentProgress: currentProgress ?? mission.currentProgress,
      );
    }
  }

  // Estatísticas
  int get totalCompletedMissions {
    return _clanMissions.where((m) => m.status == 'completed').length;
  }

  int get totalMissions {
    return _clanMissions.length;
  }

  double get completionPercentage {
    if (totalMissions == 0) return 0.0;
    return totalCompletedMissions / totalMissions;
  }

  // Limpar dados
  void clear() {
    _clanMissions.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

