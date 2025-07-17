import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/chat_service.dart';
import 'package:lucasbeatsfederacao/models/message_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Importação necessária para formatação de data

class ContextualChatScreen extends StatefulWidget {
  final String chatContext; // e.g., 'global', 'federation_id', 'clan_id'

  const ContextualChatScreen({super.key, required this.chatContext});

  @override
  State<ContextualChatScreen> createState() => _ContextualChatScreenState();
}

class _ContextualChatScreenState extends State<ContextualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  // Removido _messages = [], pois vamos usar o Consumer para obter os dados do ChatService

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // A chamada para listenToMessages foi ajustada para não esperar um retorno
    Provider.of<ChatService>(context, listen: false).listenToMessages(widget.chatContext, _getChatType());
  }

  String _getChatType() {
    if (widget.chatContext == 'global') {
      return 'global';
    }
    // Assumindo que o chatContext para federação e clã é o ID deles
    // A lógica pode precisar de ajuste dependendo do formato exato do chatContext
    return 'unknown'; 
  }

  void _loadMessages() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final chatType = _getChatType();
    try {
      // Apenas carrega as mensagens, o Consumer cuidará de exibi-las
      await chatService.getMessages(widget.chatContext, chatType);
      _scrollToBottom();
    } catch (e, s) {
      Logger.error("Erro ao carregar mensagens iniciais", error: e, stackTrace: s);
    }
  }

  void _sendMessage({File? file}) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final chatType = _getChatType();
    final messageContent = _messageController.text.trim();

    if (messageContent.isEmpty && file == null) return;

    try {
      await chatService.sendMessage(widget.chatContext, messageContent, chatType, file: file);
      _messageController.clear();
      _scrollToBottom();
      // Não é mais necessário chamar _loadMessages, o Consumer e o listener de socket farão a atualização
    } catch (e, s) {
      Logger.error("Erro ao enviar mensagem", error: e, stackTrace: s);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _sendMessage(file: File(image.path));
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _sendMessage(file: File(video.path));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // CORREÇÃO APLICADA AQUI:
  // A função _formatTimestamp foi adicionada dentro da classe.
  String _formatTimestamp(DateTime timestamp) {
    // Formata a hora como HH:mm
    return DateFormat.Hm().format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Chat: ${widget.chatContext == 'global' ? 'Global' : widget.chatContext}'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[800],
            child: Text(
              'Conteúdo do Chat Contextual para: ${widget.chatContext}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                final messages = chatService.getCachedMessagesForEntity(widget.chatContext);
                // Atualiza o scroll quando a lista de mensagens muda
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[600]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, color: Colors.grey),
                            onPressed: _pickImage,
                          ),
                          IconButton(
                            icon: const Icon(Icons.videocam, color: Colors.grey),
                            onPressed: _pickVideo,
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isSystem = message.isSystem ?? false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isOwnMessage = currentUser?.username == message.senderName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSystem
            ? MainAxisAlignment.center
            : isOwnMessage
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          if (!isSystem && !isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSystem
                    ? Colors.grey[700]
                    : isOwnMessage
                        ? Colors.blue
                        : Colors.grey[800],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSystem && !isOwnMessage)
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!isSystem && !isOwnMessage) const SizedBox(height: 4),
                  if (message.fileUrl != null) ...[
                    if (message.type == 'image')
                      Image.network(
                        message.fileUrl!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
                      )
                    else if (message.type == 'video')
                      Container(
                        width: 200,
                        height: 150,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSystem ? 12 : 14,
                      fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // A chamada agora funciona porque o método foi definido
                    _formatTimestamp(message.timestamp),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isSystem && isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
