import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/chat_service.dart';
import 'dart:io' as io;
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/user_identity_widget.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart'; // Importar SocketService

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final _uuid = const Uuid();
  ChatService? _chatService;
  SocketService? _socketService; // Adicionar SocketService
  String? _currentUserId;
  final PagingController<int, types.Message> _pagingController = PagingController(firstPageKey: 0);
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _audioPath;
  final TextEditingController _textController = TextEditingController();
  bool _isSendingMessage = false; // Novo estado para feedback de envio

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _socketService = Provider.of<SocketService>(context, listen: false); // Inicializar SocketService
    _currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    // Ouvir mensagens em tempo real do SocketService
    _socketService?.messageStream.listen((messageData) {
      if (messageData["chatType"] == "global") {
        final newMessage = types.TextMessage(
          author: types.User(id: messageData["senderId"], firstName: messageData["senderName"]),
          createdAt: messageData["createdAt"],
          id: messageData["id"],
          text: messageData["message"],
        );
        // Adiciona a nova mensagem ao topo da lista
        _pagingController.value.itemList?.insert(0, newMessage);
        _pagingController.notifyListeners(); // Notifica os listeners para atualizar a UI
      }
    });

    _openRecorder();
  }

  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _recorder.openRecorder();
  }

  Future<void> _handleVoiceMessageRecording() async {
    if (_isRecording) {
      await _stopRecordingAndSend();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _recorder.startRecorder(
        toFile: 'audio_${_uuid.v4()}.aac',
        codec: Codec.aacADTS,
      );
      setState(() {
        _isRecording = true;
      });
      Logger.info('Recording started: $_audioPath');
    } catch (e) {
      Logger.error('Error starting recording: $e');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        _chatService?.sendMessage(
          'global', // entityId
          '', // messageContent (empty for file/audio)
          'global', // chatType
          file: io.File(path), // file
        );
      }
    } catch (e) {
      Logger.error('Error stopping recording: $e');
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }


  Future<void> _fetchPage(int pageKey) async {
    try {
      final messages = await _chatService?.getMessages('global', 'global',
        page: pageKey,
        limit: 20,
      );

      if (messages != null) {
        final chatMessages = messages.map((msg) {
          // Criar o usuário com informações completas de identidade
          final user = types.User(
            id: msg.senderId,
            firstName: msg.senderName,
            imageUrl: msg.senderAvatarUrl,
            metadata: {
              'clanFlag': msg.senderClanFlag,
              'federationTag': msg.senderFederationTag,
              'role': msg.senderRole,
              'clanRole': msg.senderClanRole,
            },
          );

          // Determinar o tipo de mensagem
          switch (msg.messageType) {
            case 'image':
              return types.ImageMessage(
                author: user,
                createdAt: msg.createdAt.millisecondsSinceEpoch,
                id: msg.id,
                name: 'image.jpg',
                size: 0,
                uri: msg.fileUrl ?? '',
              );
            case 'file':
              return types.FileMessage(
                author: user,
                createdAt: msg.createdAt.millisecondsSinceEpoch,
                id: msg.id,
                name: msg.fileName ?? 'file',
                size: 0,
                uri: msg.fileUrl ?? '',
              );
            case 'audio':
              return types.AudioMessage(
                author: user,
                createdAt: msg.createdAt.millisecondsSinceEpoch,
                id: msg.id,
                name: 'audio.aac',
                size: 0,
                uri: msg.fileUrl ?? '',
                duration: const Duration(seconds: 0),
              );
            default:
              return types.TextMessage(
                author: user,
                createdAt: msg.createdAt.millisecondsSinceEpoch,
                id: msg.id,
                text: msg.message,
              );
          }
        }).toList();

        final isLastPage = chatMessages.length < 20;
        if (isLastPage) {
          _pagingController.appendLastPage(chatMessages);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(chatMessages, nextPageKey);
        }
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(context);
                      _handleImageSelection();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(context);
                      _handleCameraSelection();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.attach_file,
                    label: 'Arquivo',
                    onTap: () {
                      Navigator.pop(context);
                      _handleFileSelection();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleImageSelection() async {
    setState(() { _isSendingMessage = true; });
    try {
      final result = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1440,
      );

      if (result != null) {
        await _chatService?.sendMessage(
          'global', // entityId
          '', // messageContent
          'global', // chatType
          file: io.File(result.path),
        );
      }
    } finally { 
      setState(() { _isSendingMessage = false; });
    }
  }

  void _handleCameraSelection() async {
    setState(() { _isSendingMessage = true; });
    try {
      final result = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1440,
      );

      if (result != null) {
        await _chatService?.sendMessage(
          'global', // entityId
          '', // messageContent
          'global', // chatType
          file: io.File(result.path),
        );
      }
    } finally { 
      setState(() { _isSendingMessage = false; });
    }
  }

  void _handleFileSelection() async {
    setState(() { _isSendingMessage = true; });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        await _chatService?.sendMessage(
          'global', // entityId
          '', // messageContent
          'global', // chatType
          file: io.File(result.files.single.path!),
        );
      }
    } finally { 
      setState(() { _isSendingMessage = false; });
    }
  }

  void _handleMessageTap(BuildContext context, types.Message message) {
    if (message is types.FileMessage) {
      // Implementar abertura de arquivo
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    setState(() { _isSendingMessage = true; });
    try {
      await _chatService?.sendMessage(
        'global', // entityId
        message.text, // messageContent
        'global', // chatType
      );
    } finally { 
      setState(() { _isSendingMessage = false; });
    }
  }

  Widget _customMessageBuilder(types.Message message, {required int messageWidth}) {
    if (message.author.id == _currentUserId) {
      // Mensagem do usuário atual - não precisa mostrar identidade completa
      return _buildMessageContent(message); // Retorna o conteúdo da mensagem para o usuário atual
    }

    // Mensagem de outro usuário - mostrar identidade completa
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identidade visual do usuário
          UserIdentityWidget(
            userId: message.author.id,
            username: message.author.firstName ?? 'Usuário',
            avatar: message.author.imageUrl,
            clanFlag: message.author.metadata?['clanFlag'],
            federationTag: message.author.metadata?['federationTag'],
            role: message.author.metadata?["role"], // Já é String?
            clanRole: message.author.metadata?["clanRole"], // Já é String?
            size: 32,
            showFullIdentity: true,
          ),
          
          const SizedBox(height: 4),
          
          // Conteúdo da mensagem
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: _buildMessageContent(message),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(types.Message message) {
    if (message is types.TextMessage) {
      return Text(
        message.text,
        style: const TextStyle(color: Colors.white),
      );
    } else if (message is types.ImageMessage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          message.uri,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[800],
              child: const Center(
                child: Icon(Icons.error, color: Colors.red),
              ),
            );
          },
        ),
      );
    } else if (message is types.FileMessage) {
      return Row(
        children: [
          const Icon(Icons.attach_file, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.name,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (message is types.AudioMessage) {
      return Row(
        children: [
          const Icon(Icons.play_arrow, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Mensagem de voz',
            style: TextStyle(color: Colors.white),
          ),
        ],
      );
    }
    
    return const Text(
      'Mensagem não suportada',
      style: TextStyle(color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Chat Global',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Mostrar informações do chat global
            },
          ),
        ],
      ),
      body: Chat(
        messages: _pagingController.itemList ?? [],
        onAttachmentPressed: _handleAttachmentPressed,
        onMessageTap: _handleMessageTap,
        onSendPressed: _handleSendPressed,
        user: types.User(id: _currentUserId ?? ''),
        theme: const DarkChatTheme(),
        customMessageBuilder: _customMessageBuilder,
        showUserAvatars: true,
        showUserNames: false, // Desabilitamos pois usamos nosso widget customizado
        inputOptions: InputOptions(
          sendButtonVisibilityMode: SendButtonVisibilityMode.always,
        ),
        customBottomWidget: _buildCustomInput(),
      ),
    );
  }

  Widget _buildCustomInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.grey[700]!),
        ),
      ),
      child: Row(
        children: [
          // Botão de anexo
          IconButton(
            onPressed: _isSendingMessage ? null : _handleAttachmentPressed,
            icon: Icon(Icons.attach_file, color: _isSendingMessage ? Colors.grey.shade600 : Colors.grey),
          ),
          
          // Campo de texto
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Digite sua mensagem...', 
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onSubmitted: (text) {
                  if (text.isNotEmpty) {
                    _handleSendPressed(types.PartialText(text: text));
                    _textController.clear();
                  }
                },
              ),
            ),
          ),
          
          // Botão de enviar/gravar
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isSendingMessage ? Colors.blue.shade200 : Colors.blue,
            ),
            onPressed: _isSendingMessage ? null : _handleVoiceMessageRecording,
          ),
          IconButton(
            icon: Icon(Icons.send, color: _isSendingMessage ? Colors.blue.shade200 : Colors.blue),
            onPressed: _isSendingMessage ? null : () {
              if (_textController.text.isNotEmpty) {
                _handleSendPressed(types.PartialText(text: _textController.text));
                _textController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}


