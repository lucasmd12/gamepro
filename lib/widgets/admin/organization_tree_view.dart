import 'package:flutter/material.dart';

class OrganizationTreeView extends StatelessWidget {
  const OrganizationTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visualização Hierárquica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Conteúdo da árvore de visualização aqui
            Text('Conteúdo da árvore de federações e clãs...'),
          ],
        ),
      ),
    );
  }
}


