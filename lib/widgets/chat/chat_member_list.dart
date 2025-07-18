import 'package:flutter/material.dart';

class ChatMemberList extends StatelessWidget {
  final List<String> members;

  const ChatMemberList({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(members[index]),
        );
      },
    );
  }
}


