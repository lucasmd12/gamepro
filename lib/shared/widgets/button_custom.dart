// /home/ubuntu/lucasbeats_v4/project_android/lib/shared/widgets/button_custom.dart
import 'package:flutter/material.dart';

// Placeholder ButtonCustom widget
class ButtonCustom extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool disabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? minWidth;
  final double? height;

  const ButtonCustom({
    super.key, // Use super parameter
    required this.title,
    required this.onPressed,
    this.disabled = false,
    this.backgroundColor = const Color(0xFFFF1A1A), // Default red color
    this.textColor = Colors.white,
    this.minWidth = double.infinity, // Default to full width
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: minWidth,
      height: height,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey[700] : backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text(title),
      ),
    );
  }
}

