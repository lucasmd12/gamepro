import 'package:flutter/material.dart';

class VoiceControlsWidget extends StatelessWidget {
  final bool isMuted;
  final bool isSpeakerOn;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;

  const VoiceControlsWidget({
    super.key,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
          onPressed: onToggleMute,
          tooltip: isMuted ? 'Desmutar' : 'Mutar',
        ),
        IconButton(
          icon: Icon(isSpeakerOn ? Icons.volume_up : Icons.volume_off),
          onPressed: onToggleSpeaker,
          tooltip: isSpeakerOn ? 'Desligar Alto-falante' : 'Ligar Alto-falante',
        ),
        FloatingActionButton(
          onPressed: onEndCall,
          backgroundColor: Colors.red,
          child: const Icon(Icons.call_end, color: Colors.white),
        ),
      ],
    );
  }
}


