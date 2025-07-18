import 'dart:convert';

class CustomRole {
  final String name;
  final List<String> permissions;
  final String? color;

  CustomRole({
    required this.name,
    required this.permissions,
    this.color,
  });

  factory CustomRole.fromMap(Map<String, dynamic> map) {
    return CustomRole(
      name: map["name"] ?? "",
      permissions: List<String>.from(map["permissions"] ?? []),
      color: map["color"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "permissions": permissions,
      if (color != null) "color": color,
    };
  }
}

class Clan {
  final String id;
  final String name;
  final String tag;
  final String leaderId;
  final String? description;
  final String? bannerImageUrl;
  final String? flag;
  final List<String>? members;
  final int? memberCount; // Adicionado: Contagem de membros
  final List<String>? subLeaders;
  final List<String>? allies;
  final List<String>? enemies;
  final List<String>? textChannels;
  final List<String>? voiceChannels;
  final List<Map<String, dynamic>>? memberRoles;
  final List<CustomRole>? customRoles;
  final String? rules;
  final DateTime? createdAt;

  Clan({
    required this.id,
    required this.name,
    required this.tag,
    required this.leaderId,
    this.description,
    this.bannerImageUrl,
    this.flag,
    this.members,
    this.memberCount, // Adicionado ao construtor
    this.subLeaders,
    this.allies,
    this.enemies,
    this.textChannels,
    this.voiceChannels,
    this.memberRoles,
    this.customRoles,
    this.rules,
    this.createdAt,
  });

  factory Clan.fromMap(Map<String, dynamic> map) {
    return Clan(
      id: map["_id"] ?? "",
      name: map["name"] ?? "",
      tag: map["tag"] ?? "",
      leaderId: map["leader"] != null
          ? (map["leader"] is Map ? map["leader"]["_id"] as String? ?? "" : map["leader"] as String? ?? "")
          : map["leaderId"] as String? ?? "",
      description: map["description"],
      bannerImageUrl: map["banner"],
      flag: map["flag"],
      members: List<String>.from(map["members"] ?? []),
      memberCount: map["memberCount"] as int?, // Mapeando memberCount
      subLeaders: List<String>.from(map["subLeaders"] ?? []),
      allies: List<String>.from(map["allies"] ?? []),
      enemies: List<String>.from(map["enemies"] ?? []),
      textChannels: List<String>.from(map["textChannels"] ?? []),
      voiceChannels: List<String>.from(map["voiceChannels"] ?? []),
      memberRoles: map["memberRoles"] != null
          ? List<Map<String, dynamic>>.from(map["memberRoles"].map((x) => Map<String, dynamic>.from(x)))
          : null,
      customRoles: map["customRoles"] != null
          ? List<CustomRole>.from(map["customRoles"].map((x) => CustomRole.fromMap(x)))
          : null,
      rules: map["rules"],
      createdAt: map["createdAt"] != null
          ? DateTime.parse(map["createdAt"])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "_id": id,
      "name": name,
      "tag": tag,
      "leader": leaderId,
      if (description != null) "description": description,
      if (bannerImageUrl != null) "banner": bannerImageUrl,
      if (flag != null) "flag": flag,
      if (members != null) "members": members,
      if (memberCount != null) "memberCount": memberCount,
      if (subLeaders != null) "subLeaders": subLeaders,
      if (allies != null) "allies": allies,
      if (enemies != null) "enemies": enemies,
      if (textChannels != null) "textChannels": textChannels,
      if (voiceChannels != null) "voiceChannels": voiceChannels,
      if (memberRoles != null) "memberRoles": memberRoles,
      if (customRoles != null) "customRoles": customRoles!.map((x) => x.toMap()).toList(),
      if (rules != null) "rules": rules,
      if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
    };
  }

  factory Clan.fromJson(String source) => Clan.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}


