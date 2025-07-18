import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'dart:io' as io;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/chat_service.dart';
import 'package:lucasbeatsfederacao/widgets/user_identity_widget.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart';
import 'package:lucasbeatsfederacao/models/message_model.dart' as model;

class ClanTextChatScreen extends StatefulWidget {
  final String clanId;
  final String clanName;

  const ClanTextChatScreen({super.key, required this.clanId, required this.clanName});

  @override
  State<ClanTextChatScreen> createState() => _ClanTextChatScreenState();
}

class _ClanTextChatScreenState extends State<ClanTextChatScreen> {
  final _uuid = const Uuid();
  ChatService? _chatService;
  SocketService? _socketService;
  String? _currentUserId;
  final PagingController<int, types.Message> _pagingController = PagingController(firstPageKey: 0);
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _socketService = Provider.of<SocketService>(context, listen: false);
    _currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    _socketService?.messageStream.listen((messageData) {
      if (messageData["chatType"] == "clan" && messageData["entityId"] == widget.clanId) {
        final model.Message receivedModelMessage = model.Message.fromMap(messageData);
        final newMessage = _convertModelMessageToUiMessage(receivedModelMessage);
        
        final currentList = _pagingController.itemList ?? [];
        currentList.insert(0, newMessage);
        _pagingController.value = PagingState(
          itemList: currentList,
          nextPageKey: _pagingController.nextPageKey,
          error: null,
        );
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

  @override
  void dispose() {
    _pagingController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final messages = await _chatService?.getMessages(
        widget.clanId,
        'clan',
        page: pageKey,
        limit: 20,
      );

      if (messages != null) {
        final chatMessages = messages.map(_convertModelMessageToUiMessage).toList();
        final isLastPage = chatMessages.length < 20;

        if (isLastPage) {
          _pagingController.appendLastPage(chatMessages);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(chatMessages, nextPageKey);
        }
      } else {
        _pagingController.appendLastPage([]);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  types.Message _convertModelMessageToUiMessage(model.Message msg) {
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

    switch (msg.messageType) {
      case 'image':
        return types.ImageMessage(
          author: user,
          createdAt: msg.createdAt.millisecondsSinceEpoch,
          id: msg.id,
          name: msg.fileName ?? 'image.jpg',
          size: msg.fileSize?.toInt() ?? 0,
          uri: msg.fileUrl ?? '',
        );
      case 'file':
        return types.FileMessage(
          author: user,
          createdAt: msg.createdAt.millisecondsSinceEpoch,
          id: msg.id,
          name: msg.fileName ?? 'file',
          size: msg.fileSize?.toInt() ?? 0,
          uri: msg.fileUrl ?? '',
        );
      case 'audio':
        return types.AudioMessage(
          author: user,
          createdAt: msg.createdAt.millisecondsSinceEpoch,
          id: msg.id,
          name: msg.fileName ?? 'audio.aac',
          size: msg.fileSize?.toInt() ?? 0,
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
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
              const SizedBox(height: 20),
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
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1440,
    );

    if (result != null) {
      _chatService?.sendMessage(widget.clanId, '', 'clan', file: io.File(result.path));
    }
  }

  void _handleCameraSelection() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1440,
    );

    if (result != null) {
      _chatService?.sendMessage(widget.clanId, '', 'clan', file: io.File(result.path));
    }
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      _chatService?.sendMessage(
        widget.clanId, '', 'clan', file: io.File(result.files.single.path!),
      );
    }
  }

  void _handleSendPressed(types.PartialText message) {
    _chatService?.sendMessage(widget.clanId, message.text, 'clan');
  }

  Widget _customMessageBuilder(types.Message message, {required int messageWidth}) {
    final bool isCurrentUser = message.author.id == _currentUserId;

    if (isCurrentUser) {
      return _buildMessageContent(message);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserIdentityWidget(
            userId: message.author.id,
            username: message.author.firstName ?? 'Usuário',
            avatar: message.author.imageUrl,
            clanFlag: message.author.metadata?['clanFlag'],
            federationTag: message.author.metadata?['federationTag'],
            role: message.author.metadata?["role"],
            clanRole: message.author.metadata?["clanRole"],
            size: 32,
            showFullIdentity: true,
          ),
          const SizedBox(height: 4),
          _buildMessageContent(message),
        ],
      ),
    );
  }

  Widget _buildMessageContent(types.Message message) {
    if (message is types.TextMessage) {
      return Text(message.text);
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (message is types.AudioMessage) {
      return Row(
        children: const [
          Icon(Icons.play_arrow, color: Colors.blue),
          SizedBox(width: 8),
          Text('Mensagem de voz'),
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
    final user = types.User(id: _currentUserId ?? 'default_user_id');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Chat do Clã: ${widget.clanName}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Chat(
        messages: _pagingController.itemList ?? [],
        onSendPressed: _handleSendPressed,
        user: user,
        onAttachmentPressed: _handleAttachmentPressed,
        customMessageBuilder: (message, {required messageWidth}) =>
            _customMessageBuilder(message, messageWidth: messageWidth),
        theme: const DarkChatTheme(
          backgroundColor: Color(0xFF121212),
          inputBackgroundColor: Color(0xFF1E1E1E),
          primaryColor: Colors.blue,
          secondaryColor: Color(0xFF2D2D2D),
          inputTextColor: Colors.white,
          sentMessageBodyTextStyle: TextStyle(color: Colors.white),
          receivedMessageBodyTextStyle: TextStyle(color: Colors.white),
          // sentMessageContainerDecoration: BoxDecoration( // Removido: parâmetro não reconhecido
          //   color: Colors.blue,
          //   borderRadius: BorderRadius.all(Radius.circular(12)),
          // ),
          // receivedMessageContainerDecoration: BoxDecoration( // Removido: parâmetro não reconhecido
          //   color: Color(0xFF2D2D2D),
          //   borderRadius: BorderRadius.all(Radius.circular(12)),
          // ),
        ),
      ),
    );
  }
}
