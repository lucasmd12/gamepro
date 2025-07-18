import 'package:flutter/foundation.dart';
import 'package:lucasbeatsfederacao/models/message_model.dart';
import 'dart:io' as io;
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/firebase_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart'; // Importar SocketService
import 'package:lucasbeatsfederacao/services/upload_service.dart'; // Importar UploadService

class ChatService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseService? _firebaseService;
  final AuthService _authService;
  final SocketService _socketService; // Adicionar SocketService
  final UploadService _uploadService; // Adicionar UploadService

  final Map<String, List<Message>> _messages = {};

  ChatService({FirebaseService? firebaseService, required AuthService authService, required SocketService socketService, required UploadService uploadService})
      : _firebaseService = firebaseService,
        _authService = authService,
        _socketService = socketService,
        _uploadService = uploadService {
    _socketService.messageStream.listen((messageData) {
      _handleRealtimeMessage(messageData);
    });
  }


  Future<void> sendMessage(String entityId, String messageContent, String chatType, {io.File? file}) async {
    if (_authService.currentUser == null) {
      Logger.warning("Não autenticado para enviar mensagem.");
      return;
    }

    String? fileUrl;
    String? fileType;

    if (file != null) {
      Logger.info("Iniciando upload de arquivo para chat...");
      final uploadResult = await _uploadService.uploadMultipleFiles([file]);
      if (uploadResult["success"] == true && uploadResult["data"] is List && uploadResult["data"].isNotEmpty) {
        fileUrl = uploadResult["data"][0]["url"];
        fileType = uploadResult["data"][0]["resource_type"]; // 'image', 'video', 'raw', etc.
        Logger.info("Arquivo enviado com sucesso: $fileUrl (Tipo: $fileType)");
      } else {
        Logger.error("Falha no upload do arquivo: ${uploadResult["message"]}");
        // Decide if you want to send the message without the file or abort
        return; // Abort sending message if file upload fails critically
      }
    }

    final messageData = {
      'senderId': _authService.currentUser!.id,
      'senderName': _authService.currentUser!.username,
      'message': messageContent,
      'chatType': chatType,
      'entityId': entityId,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileType != null) 'type': fileType, // Usando 'type' para o tipo de arquivo
    };

    try {
      // Enviar via Socket.IO para tempo real
      _socketService.emit('new_message', messageData);
      Logger.info("Mensagem enviada via Socket.IO para $chatType/$entityId: $messageContent");

      // Opcional: Persistir via API REST se o backend não fizer isso automaticamente via socket
      // final response = await _apiService.post('/api/messages', messageData);
      // Logger.info('Mensagem persistida via API: $response');

    } catch (e, s) {
      Logger.error("Erro ao enviar mensagem para $chatType/$entityId", error: e, stackTrace: s);
    }
  }




  Future<List<Message>> getMessages(String entityId, String chatType, {int page = 1, int limit = 20}) async {
    String endpoint;
    switch (chatType) {
      case 'clan':
        endpoint = '/api/clans/$entityId/messages';
        break;
      case 'federation':
        endpoint = '/api/federations/$entityId/messages';
        break;
      case 'global':
        endpoint = '/api/global-chat/messages';
        break;
      default:
        Logger.warning('Tipo de chat desconhecido: $chatType');
        return [];
    }

    try {
      final response = await _apiService.get(endpoint, queryParams: {'page': page, 'limit': limit});
      if (response != null && response['success'] == true && response['messages'] is List) {
        final List<dynamic> messageData = response['messages'];
        final messages = messageData.map((json) => Message.fromMap(json)).toList();
        // Adicionar ao cache local
        _messages[entityId] = messages;
        Logger.info('Mensagens carregadas para $chatType/$entityId: ${messages.length}');
        return messages;
      } else {
        Logger.warning('Formato de resposta inesperado ao buscar mensagens para $chatType/$entityId: $response');
        return [];
      }
    } catch (e, s) {
      Logger.error('Erro ao buscar mensagens para $chatType/$entityId', error: e, stackTrace: s);
      return [];
    }
  }




  void listenToMessages(String entityId, String chatType) {
    // O listener principal já está no construtor. Este método pode ser usado para
    // garantir que o stream esteja ativo e para qualquer lógica de inicialização de UI.
    Logger.info("Iniciando escuta de mensagens para $chatType/$entityId.");
    // A lógica de atualização da UI será feita através do Consumer/Selector no widget.
  }




  void atualizarStatusPresenca(bool isOnline) {
    if (_authService.currentUser == null) {
      Logger.warning("Não autenticado para atualizar status de presença.");
      return;
    }
    final statusData = {
      'userId': _authService.currentUser!.id,
      'isOnline': isOnline,
    };
    _socketService.emit('update_presence', statusData);
    Logger.info("Status de presença atualizado para ${isOnline ? 'online' : 'offline'}.");
  }




  List<Message> getCachedMessagesForEntity(String entityId) {
    return _messages[entityId] ?? [];
  }

  void _handleRealtimeMessage(Map<String, dynamic> messageData) {
    try {
      final message = Message.fromMap(messageData);
      final entityId = message.clanId ?? message.federationId ?? message.id; // Global chat uses message.id as entityId

      if (!_messages.containsKey(entityId)) {
        _messages[entityId] = [];
      }
      _messages[entityId]!.add(message);
      notifyListeners(); // Notifica a UI para atualizar
      Logger.info("Mensagem em tempo real recebida e adicionada ao cache para $entityId.");
        } catch (e, s) {
      Logger.error("Erro ao processar mensagem em tempo real: $messageData", error: e, stackTrace: s);
    }
  }
}

