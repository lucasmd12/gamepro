import 'package:flutter/material.dart';

class ContextIndicator extends StatelessWidget {
  final String contextName;
  final IconData contextIcon;
  final Color? backgroundColor;
  final Color? textColor;

  const ContextIndicator({
    super.key,
    required this.contextName,
    required this.contextIcon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(contextIcon, size: 18, color: textColor ?? Colors.white),
          const SizedBox(width: 8),
          Text(
            contextName,
            style: TextStyle(color: textColor ?? Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


