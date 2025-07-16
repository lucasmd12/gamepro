import 'package:flutter/material.dart';

class ClanMiniCard extends StatelessWidget {
  final String clanName;
  final String? clanTag;
  final String? flagUrl; // URL da bandeira do clã
  final int memberCount;
  final VoidCallback onTap;

  const ClanMiniCard({
    super.key,
    required this.clanName,
    this.clanTag,
    this.flagUrl,
    required this.memberCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(4.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (flagUrl != null && flagUrl!.isNotEmpty)
                // Placeholder para a bandeira do clã
                Image.network(
                  flagUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 40), // Fallback
                )
              else
                const Icon(Icons.flag, size: 40), // Ícone padrão se não houver bandeira
              const SizedBox(height: 4),
              Text(
                clanName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (clanTag != null)
                Text(
                  '[$clanTag]',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                '👥 $memberCount',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


