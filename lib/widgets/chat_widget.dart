import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/chat_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/message_model.dart';
import 'package:lucasbeatsfederacao/widgets/permission_widget.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class ChatWidget extends StatefulWidget {
  final String entityId;
  final String chatType; // 'clan', 'federation', 'global'
  final String title;

  const ChatWidget({
    super.key,
    required this.entityId,
    required this.chatType,
    required this.title,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Mapeamento de cores para cargos
  final Map<String, Color> _roleColors = {
    'ADM': Colors.purple, // Exemplo para ADM
    'leader': Colors.black, // Líder (preto)
    'sub_leader': Colors.deepOrange, // Sub-líder (laranja)
    'Iniciante': Colors.blue, // Iniciante (azul)
    'Ativos': Colors.green, // Ativos (verde)
    'Outro1': Colors.red, // Outro cargo 1 (vermelho)
    'Outro2': Colors.deepPurple, // Outro cargo 2 (roxo)
    'Outro3': Colors.yellow, // Outro cargo 3 (amarelo)
  };

  final Map<String, Color> _roleTextColors = {
    'ADM': Colors.white,
    'leader': Colors.red, // Texto vermelho para líder
    'sub_leader': Colors.white,
    'Iniciante': Colors.black,
    'Ativos': Colors.white,
    'Outro1': Colors.black,
    'Outro2': Colors.white,
    'Outro3': Colors.blue, // Texto azul para amarelo
  };

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.getMessages(
 widget.entityId,
 widget.chatType,
      );
    } catch (e) {
      Logger.error('Erro ao carregar mensagens', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar mensagens')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.sendMessage( // Corrigido para usar argumentos posicionais
        widget.entityId,
 message,
        widget.chatType,
 );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      Logger.error('Erro ao enviar mensagem', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar mensagem')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        // Exibir mensagens do cache gerenciado pelo ChatService
        final cacheKey = widget.chatType == 'global' ? 'global' : widget.entityId;
        return _buildMessagesListView(chatService.getCachedMessagesForEntity(cacheKey));
      },
    );
  }

  Widget _buildCachedMessagesList(ChatService chatService) {
    final cacheKey = widget.chatType == 'global' ? 'global' : widget.entityId;
    final messages = chatService.getCachedMessagesForEntity(cacheKey);
    return _buildMessagesListView(messages);
  }

  Widget _buildMessagesListView(List<Message> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('Nenhuma mensagem ainda. Seja o primeiro a conversar!'),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isMyMessage = message.senderId == authService.currentUser?.id;

    // Determinar a cor de fundo e cor do texto com base no cargo
    Color bubbleColor = isMyMessage ? Colors.blue[600]! : Colors.grey[300]!;
    Color textColor = isMyMessage ? Colors.white : Colors.black87;
    String? displayedRole;

    if (!isMyMessage) {
      if (message.senderRole == 'ADM') {
        bubbleColor = _roleColors['ADM']!;
        textColor = _roleTextColors['ADM']!;
        displayedRole = 'ADM';
      } else if (message.senderClanCustomRole != null && message.senderClanCustomRole!.isNotEmpty) {
        // Priorizar cargo customizado do clã
        bubbleColor = _roleColors[message.senderClanCustomRole!] ?? Colors.grey[300]!;
        textColor = _roleTextColors[message.senderClanCustomRole!] ?? Colors.black87;
        displayedRole = message.senderClanCustomRole!;
      } else if (message.senderRole == 'leader') {
        bubbleColor = _roleColors['leader']!;
        textColor = _roleTextColors['leader']!;
        displayedRole = 'Líder';
      } else if (message.senderRole == 'sub_leader') {
        bubbleColor = _roleColors['sub_leader']!;
        textColor = _roleTextColors['sub_leader']!;
        displayedRole = 'Sub-Líder';
      }
    }

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMyMessage)
              Row(
                children: [
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: textColor, // Usar a cor do texto definida para o cargo
                    ),
                  ),
                  if (displayedRole != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        '($displayedRole)',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.8), // Cor do texto do cargo
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              message.message,
              style: TextStyle(
                color: textColor, // Usar a cor do texto definida para o cargo
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.7), // Cor do texto do timestamp
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return PermissionWidget(
      requiredAction: 'send_${widget.chatType}_message',
      clanId: widget.chatType == 'clan' ? widget.entityId : null,
      federationId: widget.chatType == 'federation' ? widget.entityId : null,
      fallback: Container(
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          'Você não tem permissão para enviar mensagens neste chat.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}


