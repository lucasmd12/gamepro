import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voip_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_identity_widget.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart'; // Importação necessária para AuthService

class VoiceCallScreen extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String channelType; // 'global', 'clan', 'federation'
  final bool isVideoCall;
  final List<Map<String, dynamic>>? participants;
  final String? callId;

  const VoiceCallScreen({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.channelType,
    this.isVideoCall = false,
    this.participants,
    this.callId,
  });

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late VoIPService _voipService;
  late SocketService _socketService;
  late AuthService _authService; // Adicionado para a correção
  bool _isConnecting = true;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  String? _error;
  List<Map<String, dynamic>> _currentParticipants = [];
  String? _currentCallId;

  @override
  void initState() {
    super.initState();
    _voipService = Provider.of<VoIPService>(context, listen: false);
    _socketService = Provider.of<SocketService>(context, listen: false);
    // Obtendo a instância do AuthService a partir do AuthProvider
    _authService = Provider.of<AuthProvider>(context, listen: false).authService;

    // CORREÇÃO APLICADA:
    // Passando o SocketService e o AuthService para o método init.
    _voipService.init(_socketService, _authService);

    _currentCallId = widget.callId;
    _isVideoEnabled = widget.isVideoCall;

    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      _voipService.setCallbacks(
        onCallStarted: (roomId) {
          if (mounted) {
            setState(() {
              _isConnecting = false;
            });
          }
        },
        onCallEnded: (roomId) {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );

      final roomId = _currentCallId ?? VoIPService.generateRoomId(
        prefix: widget.channelType,
        entityId: widget.channelId,
      );

      String displayName = user.username;
      if (user.federationTag != null && user.federationTag!.isNotEmpty) {
        displayName = '[${user.federationTag}] $displayName';
      }

      if (widget.callId == null) {
        await _voipService.initiateCall(
          targetId: widget.channelId,
          displayName: displayName,
          isVideoCall: widget.isVideoCall,
        );
      } else {
        await _voipService.startVoiceCall(
          roomId: roomId,
          displayName: displayName,
          isAudioOnly: !widget.isVideoCall,
        );
      }

      if (widget.participants != null) {
        if (mounted) {
          setState(() {
            _currentParticipants = List.from(widget.participants!);
          });
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _toggleMute() async {
    try {
      await _voipService.toggleAudio();
      if (mounted) {
        setState(() {
          _isMuted = !_isMuted;
        });
      }
    } catch (e) {
      _showError('Erro ao alternar microfone: $e');
    }
  }

  Future<void> _toggleVideo() async {
    try {
      await _voipService.toggleVideo();
      if (mounted) {
        setState(() {
          _isVideoEnabled = !_isVideoEnabled;
        });
      }
    } catch (e) {
      _showError('Erro ao alternar câmera: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      _voipService.switchCamera();
    } catch (e) {
      _showError('Erro ao trocar câmera: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      if (_currentCallId != null) {
        await _voipService.endCallApi(callId: _currentCallId!);
      }
      await _voipService.endCall();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
              Text(
                'Participantes (${_currentParticipants.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _currentParticipants.length,
                  itemBuilder: (context, index) {
                    final participant = _currentParticipants[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: UserIdentityWidget(
                        userId: participant['id'] ?? '',
                        username: participant['username'] ?? 'Usuário',
                        avatar: participant['avatar'],
                        clanFlag: participant['clanFlag'],
                        federationTag: participant['federationTag'],
                        role: participant['role'],
                        clanRole: participant['clanRole'],
                        size: 40,
                        showFullIdentity: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro na Chamada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isConnecting) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                'Conectando ao ${widget.channelName}...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isVideoCall ? 'Chamada de Vídeo' : 'Chamada de Voz',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    widget.channelName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isVideoCall ? Icons.videocam : Icons.mic,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isVideoCall ? 'Chamada de Vídeo' : 'Chamada de Voz',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.grey,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Interface do Jitsi Meet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'A interface de vídeo aparecerá aqui',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.people,
                    label: '${_currentParticipants.length}',
                    onPressed: _showParticipants,
                    backgroundColor: const Color(0xFF2D2D2D),
                  ),

                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted ? Colors.red : const Color(0xFF2D2D2D),
                  ),

                  if (widget.isVideoCall)
                    _buildControlButton(
                      icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      onPressed: _toggleVideo,
                      backgroundColor: _isVideoEnabled ? const Color(0xFF2D2D2D) : Colors.red,
                    ),

                  if (widget.isVideoCall)
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      onPressed: _switchCamera,
                      backgroundColor: const Color(0xFF2D2D2D),
                    ),

                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    size: 56,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Adicionado para evitar chamar dispose duas vezes
    if (mounted) {
      super.dispose();
    }
  }
}

Widget _buildControlButton({
  required IconData icon,
  String? label,
  required VoidCallback onPressed,
  Color? backgroundColor,
  double size = 48,
}) {
  return Column(
    children: [
      SizedBox(
        width: size,
        height: size,
        child: FloatingActionButton(
          heroTag: null,
          onPressed: onPressed,
          backgroundColor: backgroundColor ?? const Color(0xFF2D2D2D),
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
      if (label != null) ...[
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    ],
  );
}
