import 'package:lucasbeatsfederacao/models/role_model.dart';

class Member {
  final String id;
  final String username;
  final String avatarUrl;
  final Role role;
  final bool isOnline;
  final String? federationTag;

  Member({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.role,
    this.federationTag,
    this.isOnline = false,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar'] as String? ?? 'https://via.placeholder.com/150',
      role: roleFromString(json["clanRole"] as String? ?? "member"),
      isOnline: json['isOnline'] as bool? ?? false,
      federationTag: json['federationTag'] as String?,
    );
  }
}


