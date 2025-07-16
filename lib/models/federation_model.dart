import 'package:lucasbeatsfederacao/models/clan_model.dart';

// Assuming Clan model is needed for FederationClan
// Assuming User model is needed for FederationLeader

class FederationLeader {
  final String id;
  final String username;
  final String? avatar;

  FederationLeader({
    required this.id,
    required this.username,
    this.avatar,
  });

  factory FederationLeader.fromJson(Map<String, dynamic> json) {
    return FederationLeader(
      id: json["_id"] ?? json["id"] ?? "",
      username: json["username"] ?? "Unknown",
      avatar: json["avatar"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "username": username,
      "avatar": avatar,
    };
  }
}

class FederationClan {
  final String id;
  final String name;
  final String? tag;

  FederationClan({
    required this.id,
    required this.name,
    this.tag,
  });

  factory FederationClan.fromJson(Map<String, dynamic> json) {
    return FederationClan(
      id: json["_id"] ?? json["id"] ?? "",
      name: json["name"] ?? "Unknown Clan",
      tag: json["tag"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "tag": tag,
    };
  }

  // Método para converter FederationClan para Clan
  Clan toClan({
    required String leaderId,
  }) {
    return Clan(
      id: id,
      name: name,
      tag: tag ?? "",
      leaderId: leaderId,
    );
  }
}

class FederationAlly {
  final String id;
  final String name;

  FederationAlly({
    required this.id,
    required this.name,
  });

  factory FederationAlly.fromJson(Map<String, dynamic> json) {
    return FederationAlly(
      id: json["_id"] ?? json["id"] ?? "",
      name: json["name"] ?? "Unknown Federation",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
    };
  }
}

class Federation {
  final String id;
  final String name;
  final String? tag;
  final FederationLeader leader;
  final List<FederationLeader> subLeaders;
  final List<FederationClan> clans;
  final int? clanCount; // Adicionado: Contagem de clãs
  final List<FederationAlly> allies;
  final List<FederationAlly> enemies;
  final String? description;
  final String? rules;
 final bool? isPublic;
  final String? banner;

  Federation({
    required this.id,
    required this.name,
    this.tag,
    required this.leader,
    required this.subLeaders,
    required this.clans,
    this.clanCount, // Adicionado ao construtor
    required this.allies,
    required this.enemies,
    this.description,
    this.isPublic,
    this.rules,
    this.banner,
  });

  factory Federation.fromJson(Map<String, dynamic> json) {
    return Federation(
      id: json["_id"] ?? json["id"] ?? "",
      name: json["name"] ?? "Default Federation Name",
      tag: json["tag"],
      leader: (() {
        final dynamic leaderData = json["leader"];
        if (leaderData is String) {
          return FederationLeader(id: leaderData, username: "Unknown");
        }
        return FederationLeader.fromJson(leaderData as Map<String, dynamic>? ?? {});
      })(),
      subLeaders: (json["subLeaders"] as List? ?? [])
          .map((i) => FederationLeader.fromJson(i as Map<String, dynamic>))
          .toList(),
      clans: (json["clans"] as List? ?? [])
          .map((i) => FederationClan.fromJson(i))
          .toList(),
      clanCount: json["clanCount"] as int?, // Mapeando clanCount
      allies: (json["allies"] as List? ?? [])
          .map((i) => FederationAlly.fromJson(i))
          .toList(),
      enemies: (json["enemies"] as List? ?? [])
          .map((i) => FederationAlly.fromJson(i))
          .toList(),
      description: json["description"],
      rules: json["rules"],
      isPublic: json['isPublic'] as bool?,
      banner: json["banner"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      if (tag != null) "tag": tag,
      "leader": leader.toJson(),
      "subLeaders": subLeaders.map((s) => s.toJson()).toList(),
      "clans": clans.map((clan) => clan.toJson()).toList(),
      if (clanCount != null) "clanCount": clanCount,
      "allies": allies.map((ally) => ally.toJson()).toList(),
      "enemies": enemies.map((enemy) => enemy.toJson()).toList(),
      if (description != null) "description": description,
      if (isPublic != null) "isPublic": isPublic,
      if (rules != null) "rules": rules,
      if (banner != null) "banner": banner,
    };
  }
}


