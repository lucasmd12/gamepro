import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class StatsService {
  final ApiService _apiService;

  StatsService(this._apiService);

  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final response = await _apiService.get('/stats/global');
      Logger.info("Estatísticas globais recebidas: $response");
      return response;
    } catch (e) {
      Logger.error('Erro ao buscar estatísticas globais: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await _apiService.get('/stats/user/$userId');
      Logger.info("Estatísticas do usuário $userId recebidas: $response");
      return response;
    } catch (e) {
      Logger.error('Erro ao buscar estatísticas do usuário $userId: $e');
      rethrow;
    }
  }
}


