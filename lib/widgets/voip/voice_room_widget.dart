import 'package:flutter/material.dart';

class VoiceRoomWidget extends StatelessWidget {
  final String roomName;
  final int participantCount;
  final VoidCallback onJoin;

  const VoiceRoomWidget({
    super.key,
    required this.roomName,
    required this.participantCount,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: const Icon(Icons.mic),
        title: Text(roomName),
        subtitle: Text('$participantCount participantes'),
        trailing: ElevatedButton(
          onPressed: onJoin,
          child: const Text('Entrar'),
        ),
      ),
    );
  }
}


