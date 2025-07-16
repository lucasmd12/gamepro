import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class SegmentedNotificationService {
  static final SegmentedNotificationService _instance = SegmentedNotificationService._internal();
  factory SegmentedNotificationService() => _instance;
  SegmentedNotificationService._internal();

  final ApiService _apiService = ApiService();

  /// Envia notificação para todos os usuários (apenas ADMs)
  Future<Map<String, dynamic>> sendAdminBroadcast({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'high',
    String sound = 'default',
  }) async {
    try {
      Logger.info('Sending admin broadcast notification');
      
      final response = await _apiService.post(
        '/api/notifications/segmented/admin/send-all',
        {
          'title': title,
          'body': body,
          'data': data,
          'priority': priority,
          'sound': sound,
        },
      );

      if (response['success'] == true) {
        Logger.info('Admin broadcast sent successfully - sent: ${response['sent']}, failed: ${response['failed']}, total: ${response['total']}');
        
        return {
          'success': true,
          'message': response['message'] ?? 'Notificação enviada com sucesso',
          'sent': response['sent'] ?? 0,
          'failed': response['failed'] ?? 0,
          'total': response['total'] ?? 0,
          'details': response['details'],
        };
      } else {
        Logger.error('Admin broadcast failed - error: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao enviar notificação',
          'error': response['error'],
        };
      }
    } catch (error) {
      Logger.error('Error sending admin broadcast: ${error.toString()}');
      return {
        'success': false,
        'message': 'Erro de conexão ao enviar notificação',
        'error': error.toString(),
      };
    }
  }

  /// Envia notificação para membros de um clã (apenas Líderes do clã)
  Future<Map<String, dynamic>> sendClanNotification({
    required String clanId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'high',
    String sound = 'default',
  }) async {
    try {
      Logger.info('Sending clan notification - clanId: $clanId');
      
      final response = await _apiService.post(
        '/api/notifications/segmented/clan/send/$clanId',
        {
          'title': title,
          'body': body,
          'data': data,
          'priority': priority,
          'sound': sound,
        },
      );

      if (response['success'] == true) {
        Logger.info('Clan notification sent successfully - clanId: $clanId, sent: ${response['sent']}, failed: ${response['failed']}, total: ${response['total']}');
        
        return {
          'success': true,
          'message': response['message'] ?? 'Notificação enviada com sucesso para o clã',
          'sent': response['sent'] ?? 0,
          'failed': response['failed'] ?? 0,
          'total': response['total'] ?? 0,
          'details': response['details'],
        };
      } else {
        Logger.error('Clan notification failed - clanId: $clanId, error: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao enviar notificação para o clã',
          'error': response['error'],
        };
      }
    } catch (error) {
      Logger.error('Error sending clan notification: ${error.toString()}');
      return {
        'success': false,
        'message': 'Erro de conexão ao enviar notificação para o clã',
        'error': error.toString(),
      };
    }
  }

  /// Envia notificação para membros de uma federação (apenas Líderes da federação)
  Future<Map<String, dynamic>> sendFederationNotification({
    required String federationId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'high',
    String sound = 'default',
  }) async {
    try {
      Logger.info('Sending federation notification - federationId: $federationId');
      
      final response = await _apiService.post(
        '/api/notifications/segmented/federation/send/$federationId',
        {
          'title': title,
          'body': body,
          'data': data,
          'priority': priority,
          'sound': sound,
        },
      );

      if (response['success'] == true) {
        Logger.info('Federation notification sent successfully - federationId: $federationId, sent: ${response['sent']}, failed: ${response['failed']}, total: ${response['total']}');
        
        return {
          'success': true,
          'message': response['message'] ?? 'Notificação enviada com sucesso para a federação',
          'sent': response['sent'] ?? 0,
          'failed': response['failed'] ?? 0,
          'total': response['total'] ?? 0,
          'details': response['details'],
        };
      } else {
        Logger.error('Federation notification failed - federationId: $federationId, error: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao enviar notificação para a federação',
          'error': response['error'],
        };
      }
    } catch (error) {
      Logger.error('Error sending federation notification: ${error.toString()}');
      return {
        'success': false,
        'message': 'Erro de conexão ao enviar notificação para a federação',
        'error': error.toString(),
      };
    }
  }

  /// Visualiza quantos usuários receberão a notificação de ADM
  Future<Map<String, dynamic>> previewAdminRecipients() async {
    try {
      Logger.info('Previewing admin broadcast recipients');
      
      final response = await _apiService.get('/api/notifications/segmented/admin/preview-recipients');

      if (response['success'] == true) {
        return {
          'success': true,
          'recipientCount': response['recipientCount'] ?? 0,
          'metadata': response['metadata'],
          'preview': response['preview'] ?? [],
        };
      } else {
        Logger.error('Failed to preview admin recipients - error: ${response["message"]}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao buscar destinatários',
          'error': response['error'],
        };
      }
    } catch (error) {
      Logger.error('Error previewing admin recipients: ${error.toString()}');
      return {
        'success': false,
        'message': 'Erro de conexão ao buscar destinatários',
        'error': error.toString(),
      };
    }
  }

  /// Visualiza quantos membros do clã receberão a notificação
  Future<Map<String, dynamic>> previewClanRecipients(String clanId) async {
    try {
      Logger.info('Previewing clan recipients - clanId: $clanId');
      
      final response = await _apiService.get('/api/notifications/segmented/clan/preview-recipients/$clanId');

      if (response['success'] == true) {
        return {
          'success': true,
          'recipientCount': response['recipientCount'] ?? 0,
          'metadata': response['metadata'],
          'preview': response['preview'] ?? [],
        };
      } else {
        Logger.error('Failed to preview clan recipients - clanId: $clanId, error: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao buscar membros do clã',
          'error': response['error'],
        };
      }
    } catch (error) {
      Logger.error('Error previewing clan recipients: ${error.toString()}');
      return {
        'success': false,
        'message': 'Erro de conexão ao buscar membros do clã',
        'error': error.toString(),
      };
    }
  }

  /// Visualiza quantos membros da federação receberão a notificação
  Future<Map<String, dynamic>> previewFederationRecipients(String federationId) async {
    try {
      Logger.info('Previewing federation recipients - federationId: $federationId');
      
      final response = await _apiService.get('/api/notifications/segmented/federation/preview-recipients/$federationId');

      if (response['success'] == true) {
        return {
          'success': true,
          'recipientCount': response['recipientCount'] ?? 0,
          'metadata': response['metadata'],
          'preview': response['preview'] ?? [],
        };
      } else {
        Logger.error('Failed to preview federation recipients - federationId: $federationId, error: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao buscar membros da federação',
          'error': response['error'],
        };
      }
    } catch (error) {
      Logger.error('Error previewing federation recipients: ${error.toString()}');
      return {
        'success': false,
        'message': 'Erro de conexão ao buscar membros da federação',
        'error': error.toString(),
      };
    }
  }

  /// Obtém estatísticas de tokens segmentados (apenas ADMs)
  Future<Map<String, dynamic>> getSegmentedStats() async {
    try {
      Logger.info('Getting segmented notification statistics');
      
      final response = await _apiService.get('/api/notifications/segmented/segmented/stats');

      if (response['success'] == true) {
        return {
          'success': true,
          'statistics': response['statistics'],
        };
      } else {
        Logger.error('Failed to get segmented stats - error: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao buscar estatísticas',
          'error': response['error'],
        };
      }
    } catch (error) {
      Logger.error('Error getting segmented stats: ${error.toString()}');
      return {
        'success': false,
        'message': 'Erro de conexão ao buscar estatísticas',
        'error': error.toString(),
      };
    }
  }

  /// Valida se o título e corpo da notificação são válidos
  static Map<String, dynamic> validateNotificationContent({
    required String title,
    required String body,
  }) {
    final errors = <String>[];

    if (title.trim().isEmpty) {
      errors.add('Título é obrigatório');
    } else if (title.trim().length < 3) {
      errors.add('Título deve ter pelo menos 3 caracteres');
    } else if (title.trim().length > 100) {
      errors.add('Título deve ter no máximo 100 caracteres');
    }

    if (body.trim().isEmpty) {
      errors.add('Mensagem é obrigatória');
    } else if (body.trim().length < 10) {
      errors.add('Mensagem deve ter pelo menos 10 caracteres');
    } else if (body.trim().length > 500) {
      errors.add('Mensagem deve ter no máximo 500 caracteres');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }

  /// Formata resultado de envio para exibição
  static String formatSendResult(Map<String, dynamic> result) {
    if (result['success'] == true) {
      final sent = result['sent'] ?? 0;
      final failed = result['failed'] ?? 0;
      final total = result['total'] ?? 0;

      if (total == 0) {
        return 'Nenhum destinatário encontrado';
      } else if (failed == 0) {
        return 'Notificação enviada com sucesso para $sent usuário${sent != 1 ? 's' : ''}';
      } else {
        return 'Notificação enviada para $sent usuário${sent != 1 ? 's' : ''} ($failed falharam)';
      }
    } else {
      return result['message'] ?? 'Erro ao enviar notificação';
    }
  }

  /// Formata preview de destinatários para exibição
  static String formatRecipientPreview(Map<String, dynamic> preview) {
    if (preview['success'] == true) {
      final count = preview['recipientCount'] ?? 0;
      if (count == 0) {
        return 'Nenhum destinatário encontrado';
      } else {
        return '$count usuário${count != 1 ? 's' : ''} receberá${count == 1 ? '' : 'ão'} a notificação';
      }
    } else {
      return preview['message'] ?? 'Erro ao buscar destinatários';
    }
  }
}

