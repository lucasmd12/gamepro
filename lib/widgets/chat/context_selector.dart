import 'package:flutter/material.dart';

enum ChatContextType {
  global,
  federation,
  clan,
  private,
}

class ContextSelector extends StatelessWidget {
  final ChatContextType selectedContext;
  final Function(ChatContextType) onContextSelected;

  const ContextSelector({
    super.key,
    required this.selectedContext,
    required this.onContextSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<ChatContextType>(
      value: selectedContext,
      onChanged: (ChatContextType? newValue) {
        if (newValue != null) {
          onContextSelected(newValue);
        }
      },
      items: const <DropdownMenuItem<ChatContextType>>[
        DropdownMenuItem(
          value: ChatContextType.global,
          child: Text('Global'),
        ),
        DropdownMenuItem(
          value: ChatContextType.federation,
          child: Text('Federação'),
        ),
        DropdownMenuItem(
          value: ChatContextType.clan,
          child: Text('Clã'),
        ),
        DropdownMenuItem(
          value: ChatContextType.private,
          child: Text('Privado'),
        ),
      ],
    );
  }
}


