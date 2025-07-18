import 'package:flutter/material.dart';

class ContextAwareAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final Widget? leading;
  final List<Widget>? actions;
  final String? contextInfo;

  const ContextAwareAppBar({
    super.key,
    required this.titleText,
    this.leading,
    this.actions,
    this.contextInfo,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleText),
          if (contextInfo != null)
            Text(
              contextInfo!,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


