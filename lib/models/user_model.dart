import 'package:lucasbeatsfederacao/models/role_model.dart'; // Importar Role
import 'package:lucasbeatsfederacao/utils/logger.dart'; // Importar Logger para logs de debug

class User {
  final String id;
  final String username;
  final String? avatar;
  final String? bio;
  final String status;
  final String? clanId; // Pode ser nulo se não tiver clã
  final String? clanName; // Adicionado: Nome do clã
  final String? clanTag; // Adicionado: Tag do clã
  final Role clanRole; // Alterado para Role
  final String? federationId; // Pode ser nulo
  final String? federationName; // Adicionado: Nome da federação
  final String? federationTag; // Adicionado: Tag da federação
  final Role federationRole; // Adicionado: Papel na federação
  final Role role; // Alterado para Role
  bool isOnline; // ✅ AÇÃO 1: MUDADO DE 'final bool online' PARA 'bool isOnline'
  final DateTime? ultimaAtividade; // Pode ser nulo
  final DateTime? lastSeen; // Pode ser nulo
  final DateTime? createdAt; // Adicionado: Data de criação do usuário

  User({
    required this.id,
    required this.username,
    this.avatar,
    this.bio = 'Sem biografia.',
    this.status = 'offline',
    this.clanId,
    this.clanName,
    this.clanTag,
    this.clanRole = Role.member,
    this.federationId,
    this.federationName,
    this.federationTag,
    this.federationRole = Role.member,
    this.role = Role.user,
    this.isOnline = false, // ✅ AÇÃO 2: ATUALIZADO O CONSTRUTOR
    this.ultimaAtividade,
    this.lastSeen,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? _getStringOrIdFromMap(dynamic value) {
      if (value is String) {
        return value;
      } else if (value is Map<String, dynamic>) {
        return value['_id'] as String?;
      }
      if (value != null) {
         Logger.warning('Expected String or Map for ID, but got ${value.runtimeType}');
      }
      return null;
    }

    String? _getNameFromMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['name'] as String?;
      }
       if (value != null) {
         Logger.warning('Expected Map for Name, but got ${value.runtimeType}');
      }
      return null;
    }

    String? _getTagFromMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['tag'] as String?;
      }
       if (value != null) {
         Logger.warning('Expected Map for Tag, but got ${value.runtimeType}');
      }
      return null;
    }

    DateTime? _parseDateTime(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          Logger.error('Failed to parse DateTime string: $value', error: e);
          return null;
        }
      }
       if (value != null) {
         Logger.warning('Expected String for DateTime, but got ${value.runtimeType}');
      }
      return null;
    }

    final dynamic clanData = json['clan'];
    final dynamic federationData = json['federation'];
    final dynamic rawRole = json['role'];
    final dynamic rawClanRole = json['clanRole'];
    final dynamic rawFederationRole = json['federationRole'];

    return User(
      id: json['_id'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      status: json['status'] as String? ?? 'offline',
      clanId: _getStringOrIdFromMap(clanData),
      clanName: _getNameFromMap(clanData),
      clanTag: _getTagFromMap(clanData),
      clanRole: rawClanRole is String ? roleFromString(rawClanRole) : Role.member,
      federationId: _getStringOrIdFromMap(federationData),
      federationName: _getNameFromMap(federationData),
      federationTag: _getTagFromMap(federationData),
      federationRole: rawFederationRole is String ? roleFromString(rawFederationRole) : Role.member,
      role: rawRole is String ? roleFromString(rawRole) : Role.user,
      isOnline: json['isOnline'] as bool? ?? json['online'] as bool? ?? false, // ✅ AÇÃO 3: AJUSTADO O fromJson PARA ACEITAR 'isOnline' OU 'online'
      ultimaAtividade: _parseDateTime(json['ultimaAtividade']),
      lastSeen: _parseDateTime(json['lastSeen']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'avatar': avatar,
      'bio': bio,
      'status': status,
      'clanId': clanId,
      'clanName': clanName,
      'clanTag': clanTag,
      'clanRole': roleToString(clanRole),
      'federationId': federationId,
      'federationName': federationName,
      'federationTag': federationTag,
      'federationRole': roleToString(federationRole),
      'role': roleToString(role),
      'isOnline': isOnline, // ✅ AÇÃO 4: ATUALIZADO O toJson
      'ultimaAtividade': ultimaAtividade?.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // ✅ AÇÃO 5: REMOVIDO O GETTER REDUNDANTE, POIS O CAMPO AGORA É PÚBLICO
  String? get tag => federationTag;
  String? get clan => clanId;
  String? get federation => federationId;
}
