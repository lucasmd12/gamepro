import 'package:flutter/material.dart';

class OrganizationBadge extends StatelessWidget {
  final String name;
  final String? tag;
  final IconData icon;
  final Color color;

  const OrganizationBadge({
    super.key,
    required this.name,
    this.tag,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            tag != null ? '[$tag] $name' : name,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


