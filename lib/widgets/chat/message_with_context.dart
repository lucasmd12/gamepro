import 'package:flutter/material.dart';

class MessageWithContext extends StatelessWidget {
  final String sender;
  final String message;
  final String? contextInfo; // e.g., clan name, federation name
  final bool isMe;

  const MessageWithContext({
    super.key,
    required this.sender,
    required this.message,
    this.contextInfo,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[700],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (contextInfo != null)
              Text(
                contextInfo!,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            const SizedBox(height: 4.0),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}


