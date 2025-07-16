import 'package:flutter/material.dart';

class RecentActivitiesWidget extends StatelessWidget {
  final List<String> activities;

  const RecentActivitiesWidget({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alertas Recentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...activities.map((activity) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('• $activity'),
            )).toList(),
          ],
        ),
      ),
    );
  }
}


