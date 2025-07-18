import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/models/clan_war_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class ClanWarService {
  final ApiService _apiService;

  ClanWarService(this._apiService);

  Future<ClanWarModel?> createClanWar(Map<String, dynamic> clanWarData) async {
    try {
      final response = await _apiService.post('clan-wars', clanWarData);
      // A API parece retornar o objeto diretamente na resposta
      if (response != null) {
        // CORREÇÃO: Usando fromMap
        return ClanWarModel.fromMap(response);
      } else {
        Logger.error('Failed to create clan war: Response was null');
        return null;
      }
    } catch (e, st) {
      Logger.error('Error creating clan war', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<ClanWarModel>> getClanWars({String? clanId, String? federationId}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (clanId != null) queryParams['clanId'] = clanId;
      if (federationId != null) queryParams['federationId'] = federationId;

      final response = await _apiService.get('clan-wars', queryParams: queryParams);
      // A API parece retornar uma lista diretamente
      if (response is List) {
        // CORREÇÃO: Usando fromMap
        return response.map((json) => ClanWarModel.fromMap(json as Map<String, dynamic>)).toList();
      } else {
        Logger.error('Failed to fetch clan wars: Response was not a list');
        return [];
      }
    } catch (e, st) {
      Logger.error('Error fetching clan wars', error: e, stackTrace: st);
      return [];
    }
  }

  Future<ClanWarModel?> updateClanWar(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await _apiService.put('clan-wars/$id', updateData);
      if (response != null) {
        // CORREÇÃO: Usando fromMap
        return ClanWarModel.fromMap(response);
      } else {
        Logger.error('Failed to update clan war: Response was null');
        return null;
      }
    } catch (e, st) {
      Logger.error('Error updating clan war', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> deleteClanWar(String id) async {
    try {
      // O método delete pode não retornar um corpo, apenas um status de sucesso.
      await _apiService.delete('clan-wars/$id');
      return true;
    } catch (e, st) {
      Logger.error('Error deleting clan war', error: e, stackTrace: st);
      return false;
    }
  }
}
