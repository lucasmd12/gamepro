// Removed Firestore import
import '../models/questionnaire_model.dart';
import '../services/api_service.dart'; // Import ApiService
import '../utils/logger.dart'; // Use Logger

class QuestionnaireService {
  final ApiService _apiService; // Inject ApiService

  QuestionnaireService(this._apiService);

  // Criar novo questionário (POST /api/questionnaires)
  Future<QuestionnaireModel?> createQuestionnaire(QuestionnaireModel questionnaire) async {
    try {
      final response = await _apiService.post('/api/questionnaires', questionnaire.toJson());
      if (response != null) {
        Logger.info('Questionário criado com sucesso via API.');
        return QuestionnaireModel.fromJson(response);
      } else {
        Logger.warning('API não retornou dados ao criar questionário.');
        return null;
      }
    } catch (e, s) {
      Logger.error('Erro ao criar questionário via API', error: e, stackTrace: s);
      throw Exception('Falha ao criar questionário: ${e.toString()}');
    }
  }

  // Obter todos os questionários (GET /api/questionnaires)
  Future<List<QuestionnaireModel>> getQuestionnaires() async {
    try {
      final response = await _apiService.get('/api/questionnaires?active=all'); // Example query param
      if (response != null && response is List) {
        final questionnaires = response.map((data) => QuestionnaireModel.fromJson(data)).toList();
        Logger.info('Buscou ${questionnaires.length} questionários via API.');
        return questionnaires;
      } else {
        Logger.warning('API não retornou lista de questionários ou formato inválido.');
        return [];
      }
    } catch (e, s) {
      Logger.error('Erro ao buscar questionários via API', error: e, stackTrace: s);
      return [];
    }
  }

  // Obter questionários ativos (GET /api/questionnaires?active=true)
  Future<List<QuestionnaireModel>> getActiveQuestionnaires() async {
    try {
      final response = await _apiService.get('/api/questionnaires?active=true');
      if (response != null && response is List) {
        final questionnaires = response.map((data) => QuestionnaireModel.fromJson(data)).toList();
        Logger.info('Buscou ${questionnaires.length} questionários ativos via API.');
        return questionnaires;
      } else {
        Logger.warning('API não retornou lista de questionários ativos ou formato inválido.');
        return [];
      }
    } catch (e, s) {
      Logger.error('Erro ao buscar questionários ativos via API', error: e, stackTrace: s);
      return [];
    }
  }

  // Atualizar questionário (PUT /api/questionnaires/{questionnaireId})
  Future<bool> updateQuestionnaire(String questionnaireId, Map<String, dynamic> updateData) async {
    try {
      final response = await _apiService.put('/api/questionnaires/$questionnaireId', updateData);
      final success = response != null;
      if (success) {
        Logger.info('Questionário $questionnaireId atualizado com sucesso via API.');
      } else {
        Logger.warning('Falha ao atualizar questionário $questionnaireId via API.');
      }
      return success;
    } catch (e, s) {
      Logger.error('Erro ao atualizar questionário $questionnaireId via API', error: e, stackTrace: s);
      return false;
    }
  }

  // Excluir questionário (DELETE /api/questionnaires/{questionnaireId})
  Future<bool> deleteQuestionnaire(String questionnaireId) async {
    try {
      final response = await _apiService.delete('/api/questionnaires/$questionnaireId');
      final success = response != null;
      if (success) {
        Logger.info('Questionário $questionnaireId excluído com sucesso via API.');
      } else {
        Logger.warning('Falha ao excluir questionário $questionnaireId via API.');
      }
      return success;
    } catch (e, s) {
      Logger.error('Erro ao excluir questionário $questionnaireId via API', error: e, stackTrace: s);
      return false;
    }
  }

  // Ativar/desativar questionário (PATCH /api/questionnaires/{questionnaireId})
  Future<bool> toggleQuestionnaireStatus(String questionnaireId, bool isActive) async {
    try {
      final response = await _apiService.patch('/api/questionnaires/$questionnaireId', {'isActive': isActive});
      final success = response != null;
      if (success) {
        Logger.info('Status do questionário $questionnaireId alterado para $isActive via API.');
      } else {
        Logger.warning('Falha ao alterar status do questionário $questionnaireId via API.');
      }
      return success;
    } catch (e, s) {
      Logger.error('Erro ao alterar status do questionário $questionnaireId via API', error: e, stackTrace: s);
      return false;
    }
  }

  // Enviar resposta de questionário (POST /api/questionnaire-responses)
  Future<bool> submitQuestionnaireResponse(String questionnaireId, String userId, Map<String, dynamic> responses) async {
    try {
      final response = await _apiService.post('/api/questionnaire-responses', {
        'questionnaireId': questionnaireId,
        'userId': userId,
        'responses': responses,
        // 'submittedAt' should likely be handled by the backend
      });
      final success = response != null;
      if (success) {
        Logger.info('Resposta do questionário $questionnaireId enviada pelo usuário $userId via API.');
      } else {
        Logger.warning('Falha ao enviar resposta do questionário $questionnaireId via API.');
      }
      return success;
    } catch (e, s) {
      Logger.error('Erro ao enviar resposta do questionário $questionnaireId via API', error: e, stackTrace: s);
      return false;
    }
  }
}