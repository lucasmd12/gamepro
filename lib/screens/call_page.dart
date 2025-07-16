import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/call_provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/call_model.dart' show CallStatus;

class CallPage extends StatefulWidget {
  final String? contactName;
  final String? contactId;

  final String roomName; // Adicionado para Jitsi

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

    // Iniciar a chamada Jitsi ao entrar na página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voipService = Provider.of<VoIPService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!voipService.isInCall) {
        voipService.joinJitsiMeeting(
          roomName: widget.roomName,
          userDisplayName: authService.currentUser?.username ?? 'Usuário Anônimo',
          // userEmail: null, // Removido pois o parâmetro não existe mais
          // videoMuted: true, // Conforme especificado no exemplo do usuário
          // audioMuted: false, // Conforme especificado no exemplo do usuário
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
              scale: voipService.isCalling ||
                     (widget.isIncomingCall && voipService.currentCall?.status == CallStatus.pending)
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
    // Para Jitsi, não há controles de aceitar/rejeitar chamadas diretamente na UI do app
    // O Jitsi Meet Wrapper abre a interface do Jitsi que lida com isso.
    // Apenas o botão de encerrar chamada é relevante aqui.
    return _buildActiveCallControls(context, voipService);
  }

  Widget _buildActiveCallControls(BuildContext context, VoIPService voipService) {
    return Column(
      children: [
        // Botão de encerrar chamada
        _buildControlButton(
          icon: Icons.call_end,
          color: Colors.white,
          backgroundColor: Colors.red,
          size: 70,
          iconSize: 35,
          onPressed: () async {
            await voipService.endCall();
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
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
  }) {
    return GestureDetector(
      onTap: onPressed,
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


