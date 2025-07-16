import 'package:flutter/material.dart';

class HierarchyBreadcrumb extends StatelessWidget {
  final List<String> path;
  final Function(int) onPathTap;

  const HierarchyBreadcrumb({
    super.key,
    required this.path,
    required this.onPathTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 4.0,
        children: List.generate(path.length, (index) {
          return GestureDetector(
            onTap: () => onPathTap(index),
            child: Text(
              index == path.length - 1 ? path[index] : '${path[index]} >',
              style: TextStyle(
                color: index == path.length - 1 ? Colors.white : Colors.grey,
                fontWeight: index == path.length - 1 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }
}


