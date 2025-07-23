import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/call_provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/call_model.dart' show CallStatus;
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallPage extends StatefulWidget {
  final String? contactName;
  final String? contactId;
  final String roomName; // Pode ser o callId para P2P ou roomName para Jitsi

  const CallPage({
    super.key,
    this.contactName,
    this.contactId,
    required this.roomName,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    _localRenderer.initialize();
    _remoteRenderer.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ AÇÃO 1: GARANTIR QUE O CONTEXTO É VÁLIDO ANTES DE USAR O PROVIDER
      if (mounted) {
        final voipService = Provider.of<VoIPService>(context, listen: false);
        // Atualizar renderers com os streams do VoIPService
        // Adicionando verificação de nulidade para os streams
        if (voipService.localStream != null) {
          _localRenderer.srcObject = voipService.localStream;
        }
        if (voipService.remoteStream != null) {
          _remoteRenderer.srcObject = voipService.remoteStream;
        }
        
        // Listener para quando os streams forem atualizados no VoIPService
        voipService.addListener(_updateRenderers);
      }
    });
  }
  
  // ✅ AÇÃO 2: CRIADO MÉTODO SEPARADO PARA ATUALIZAR RENDERERS
  void _updateRenderers() {
    if (mounted) {
      final voipService = Provider.of<VoIPService>(context, listen: false);
      setState(() {
        if (voipService.localStream != null) {
          _localRenderer.srcObject = voipService.localStream;
        }
        if (voipService.remoteStream != null) {
          _remoteRenderer.srcObject = voipService.remoteStream;
        }
      });
    }
  }

  @override
  void dispose() {
    // ✅ AÇÃO 3: REMOVER O LISTENER PARA EVITAR MEMORY LEAKS
    if (mounted) {
      Provider.of<VoIPService>(context, listen: false).removeListener(_updateRenderers);
    }
    _pulseController.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // ✅ AÇÃO 4: O Consumer2 ESTÁ CORRETO, O ERRO DEVE SER CASCATA. NENHUMA MUDANÇA AQUI.
      body: Consumer2<CallProvider, VoIPService>(
        builder: (context, callProvider, voipService, child) {
          return SafeArea(
            child: Column(
              children: [
                // Header com informações da chamada
                _buildCallHeader(voipService),

                // Avatar e informações do contato
                Expanded(
                  flex: 3,
                  child: _buildContactInfo(voipService),
                ),

                // Status da chamada
                _buildCallStatus(voipService),

                // Controles da chamada
                Expanded(
                  flex: 2,
                  child: _buildCallControls(context, voipService),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallHeader(VoIPService voipService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () async {
              if (voipService.isInCall) {
                await voipService.endCall();
              }
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Text(
            _getCallStatusText(voipService.currentCall?.status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w500,
            ),
          ),
          if (voipService.isInCall)
            Text(
              voipService.formatCallDuration(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500, ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildContactInfo(VoIPService voipService) {
    final contactName = widget.contactName ??
                       voipService.currentCall?.callerId ??
                       voipService.currentCall?.receiverId ??
                       'Usuário';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: voipService.isCalling || voipService.currentCall?.status == CallStatus.pending
                  ? _pulseAnimation.value
                  : 1.0,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.purple.shade400,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        Text(
          contactName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        if (voipService.currentCall?.status == CallStatus.pending)
          const Text(
            'Chamando...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildCallStatus(VoIPService voipService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _getCallStatusText(voipService.currentCall?.status),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ), textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, VoIPService voipService) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: Icons.mic_off,
              color: Colors.white,
              backgroundColor: Colors.grey.shade800,
              onPressed: () {
                voipService.toggleMute();
              },
              tooltip: 'Mudo',
            ),
            _buildControlButton(
              icon: Icons.volume_up,
              color: Colors.white,
              backgroundColor: Colors.grey.shade800,
              onPressed: () {
                // Implementar toggle speaker
              },
              tooltip: 'Alto-falante',
            ),
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.white,
              backgroundColor: Colors.red,
              onPressed: () async {
                await voipService.endCall();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              tooltip: 'Encerrar Chamada',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onPressed,
    double size = 60,
    double iconSize = 30,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? Colors.grey.shade800,
            boxShadow: [
              BoxShadow( 
                color: Colors.black.withAlpha((255 * 0.3).round()),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  String _getCallStatusText(CallStatus? state) {
    switch (state) {
      case CallStatus.active:
        return 'Em chamada';
      case CallStatus.ended:
        return 'Chamada encerrada';
      case CallStatus.pending:
        return 'Chamando...';
      case CallStatus.accepted:
        return 'Conectado';
      case CallStatus.rejected:
        return 'Chamada rejeitada';
      default:
        return 'Desconhecido';
    }
  }
}
