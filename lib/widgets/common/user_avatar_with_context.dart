import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatarWithContext extends StatelessWidget {
  final String? avatarUrl;
  final String? username;
  final String? contextText; // e.g., role, clan name
  final double radius;

  const UserAvatarWithContext({
    super.key,
    this.avatarUrl,
    this.username,
    this.contextText,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl!) as ImageProvider
              : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? Icon(Icons.person, size: radius)
              : null,
        ),
        if (username != null)
          Text(
            username!,
            style: TextStyle(fontSize: radius * 0.6, fontWeight: FontWeight.bold),
          ),
        if (contextText != null)
          Text(
            contextText!,
            style: TextStyle(fontSize: radius * 0.5, color: Colors.grey),
          ),
      ],
    );
  }
}


