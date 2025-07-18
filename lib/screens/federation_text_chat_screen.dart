import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
// Importar 'dart:io' com prefixo
import 'package:lucasbeatsfederacao/services/chat_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class FederationTextChatScreen extends StatefulWidget {
  final String federationId;
  final String federationName;

  const FederationTextChatScreen({super.key, required this.federationId, required this.federationName});

  @override
  State<FederationTextChatScreen> createState() => _FederationTextChatScreenState();
}

class _FederationTextChatScreenState extends State<FederationTextChatScreen> {
  final List<types.Message> _messages = [];
  final _uuid = const Uuid();
  ChatService? _chatService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    _loadMessages();
  }

  void _loadMessages() async {
    try {
      final fetchedMessages = await _chatService?.getMessages(widget.federationId, 'federation', page: 1, limit: 20);
      if (fetchedMessages != null) {
        setState(() {
          _messages.clear();
          _messages.addAll(fetchedMessages.map((msg) => types.TextMessage(
            author: types.User(id: msg.senderId, firstName: msg.senderName),
            createdAt: msg.createdAt.millisecondsSinceEpoch,
            id: msg.id,
            text: msg.message,
          )).toList().reversed); // Reverse to show latest at bottom
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar mensagens da federação: $e');
    }
  }

  void _handleSendPressed(types.PartialText message) {
    _chatService?.sendMessage(
      widget.federationId,
      message.text,
      'federation',
    );
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: types.User(id: _currentUserId!),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: _uuid.v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      setState(() {
        _messages.insert(0, message);
      });
      _chatService?.sendMessage(
        widget.federationId,
        '', // Mensagem vazia para imagem
        'federation',
      );    
    }
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: types.User(id: _currentUserId!),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _uuid.v4(),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      setState(() {
        _messages.insert(0, message);
      });
      _chatService?.sendMessage(
        widget.federationId,
        '', // Mensagem vazia para arquivo
        'federation',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = types.User(id: _currentUserId!); // O usuário atual para o chat UI

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat da Federação: ${widget.federationName}'),
        centerTitle: true,
      ),
      body: Chat(
        messages: _messages,
        onAttachmentPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) => SafeArea(
              child: SizedBox(
                height: 144,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleImageSelection();
                      },
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('Foto'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleFileSelection();
                      },
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('Arquivo'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('Cancelar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        onSendPressed: _handleSendPressed,
        user: user,
        theme: const DefaultChatTheme(
          backgroundColor: Color(0xFF212121),
          primaryColor: Color(0xFFF44336),
          secondaryColor: Color(0xFF424242),
          inputBackgroundColor: Color(0xFF424242),
          inputTextColor: Colors.white,
          inputTextDecoration: InputDecoration(
            hintText: 'Digite sua mensagem...', 
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          messageBorderRadius: 12,
          messageInsetsVertical: 8,
          messageInsetsHorizontal: 12,
          receivedMessageBodyTextStyle: TextStyle(color: Colors.white),
          sentMessageBodyTextStyle: TextStyle(color: Colors.white),
          receivedMessageCaptionTextStyle: TextStyle(color: Colors.grey),
          sentMessageCaptionTextStyle: TextStyle(color: Colors.grey),
          receivedMessageDocumentIconColor: Colors.white,
          sentMessageDocumentIconColor: Colors.white,
          receivedMessageBodyBoldTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          sentMessageBodyBoldTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          receivedMessageBodyCodeTextStyle: TextStyle(fontFamily: 'monospace', color: Colors.white),
          sentMessageBodyCodeTextStyle: TextStyle(fontFamily: 'monospace', color: Colors.white),
          dateDividerTextStyle: TextStyle(color: Colors.grey, fontSize: 12),
          errorColor: Colors.red,
        ),
      ),
    );
  }
}


