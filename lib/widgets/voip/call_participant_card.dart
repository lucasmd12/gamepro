import 'package:flutter/material.dart';

class CallParticipantCard extends StatelessWidget {
  final String participantName;
  final bool isMuted;
  final bool isSpeaking;

  const CallParticipantCard({
    super.key,
    required this.participantName,
    this.isMuted = false,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(
              isMuted ? Icons.mic_off : Icons.mic_none,
              color: isSpeaking ? Colors.green : null,
            ),
            Text(participantName),
          ],
        ),
      ),
    );
  }
}


