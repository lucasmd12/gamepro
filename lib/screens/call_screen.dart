// lib/screens/call_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/models/call_model.dart' show Call, CallStatus;

class CallScreen extends StatefulWidget {
  final String roomId;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.roomId,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    final voipService = Provider.of<VoIPService>(context, listen: false);

    // Listen for call state changes to automatically close the screen when call ends
    voipService.onCallStateChanged = (state) {
      if (state == 'ended') {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<VoIPService>(
        builder: (context, voipService, child) {
          // Use the current call from the service if available, otherwise use the initial call
          final String currentRoomId = voipService.currentCall?.roomName ?? widget.roomId;

          return SafeArea(
            child: Column(
              children: [
                // Header with call information
                _buildCallHeader(currentRoomId, voipService),

                // Video area (placeholder for future video implementation)
                Expanded(
                  child: _buildVideoArea(),
                ),

                // Call controls
                _buildCallControls(currentRoomId, voipService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallHeader(String roomId, VoIPService voipService) {
    String statusText = '';

    // Determine status text based on call status
    switch (voipService.currentCall?.status) {
      case CallStatus.pending:
        statusText = widget.isIncoming ? 'Chamada recebida' : 'Chamando...';
        break;
      case CallStatus.active:
        statusText = voipService.formatCallDuration(); // Assumes VoIPService has this method
        break;
      case CallStatus.ended:
        statusText = 'Chamada encerrada';
        break;
      default:
        statusText = 'Conectando...';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar placeholder
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[800],
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // User name
          Text(
            widget.isIncoming ? voipService.currentCall?.callerName ?? 'Usuário Desconhecido' : voipService.currentCall?.receiverId ?? 'Usuário Desconhecido',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Call status
          Text(
            statusText,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Remote video placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: Center(
              child: Icon(
                Icons.person,
                size: 100,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Local video placeholder
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls(String roomId, VoIPService voipService) {
    // If it's an incoming call and still pending, show accept/reject buttons
    if (voipService.currentCall?.status == CallStatus.pending && widget.isIncoming) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Reject button
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.red,
              onPressed: () async {
 await voipService.rejectCall(callId: voipService.currentCall?.callId ?? '');
 if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),

            // Accept button
            _buildControlButton(
              icon: Icons.call,
              color: Colors.green,
              onPressed: () async {
                await voipService.acceptCall(
                  roomId: voipService.currentCall?.roomName ?? "", // Use ?? ''
                  displayName: voipService.currentCall?.callerName ?? 'Usuário Desconhecido',
                );
                // Assuming acceptCall handles state change and navigation if needed
              },
            ),
          ],
        ),
      );
    } else {
      // Controls for active call
      return Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? Colors.red : Colors.grey[700]!,
              onPressed: () {
                setState(() {
                  _isMuted = !_isMuted;
                });
                voipService.toggleMute();
              },
            ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              color: Colors.red,
              onPressed: () async {
                await voipService.endCall();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),

            // Speaker button
            _buildControlButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              color: _isSpeakerOn ? Colors.blue : Colors.grey[700]!,
              onPressed: () {
                setState(() {
                  _isSpeakerOn = !_isSpeakerOn;
                });
                // TODO: Implement speaker toggle logic in VoIPService
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 30),
        onPressed: onPressed,
      ),
    );
  }
}