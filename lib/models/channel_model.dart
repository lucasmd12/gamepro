import 'dart:convert';

enum ChannelType {
  text,
  voice,
}

class Channel {
  final String id;
  final String name;
  final ChannelType type;
  final String? clanId;
  final String? federationId;
  final int? userLimit;
  final String? createdByUserId;
  final List<String> activeUsers;
  final String? topic;

  Channel({
    required this.id,
    required this.name,
    required this.type,
    this.clanId,
    this.federationId,
    this.userLimit,
    this.createdByUserId,
    this.activeUsers = const [],
    this.topic,
  });

  factory Channel.fromMap(Map<String, dynamic> map) {
    List<String> activeUserIds = [];
    if (map['activeUsers'] is List) {
      activeUserIds = List<String>.from(map['activeUsers'].map((user) => user['_id']));
    }
    return Channel(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      type: ChannelType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => ChannelType.text,
      ),
      clanId: map['clanId'],
      federationId: map['federationId'],
      userLimit: map['userLimit'] != null ? int.tryParse(map['userLimit'].toString()) : null,
      createdByUserId: map["createdBy"] != null ? map["createdBy"]["_id"] : null,
      activeUsers: activeUserIds,
      topic: map["topic"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'clanId': clanId,
      'federationId': federationId,
      'userLimit': userLimit,
      'createdByUserId': createdByUserId,
      'activeUsers': activeUsers,
      'topic': topic,
    };
  }

  factory Channel.fromJson(String source) => Channel.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}


