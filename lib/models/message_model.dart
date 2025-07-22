import 'dart:convert';

class Message {
  final String id;
  final String? clanId; // Pode ser nulo se for mensagem global ou de federação
  final String? federationId; // Adicionado para mensagens de federação
  final String senderId;
  final String senderName; // Adicionado
  final String? senderRole; // Adicionado: role geral do usuário (ADM, user, etc.)
  final String? senderClanCustomRole; // Adicionado: cargo customizado no clã
  final String message;
  final DateTime createdAt;
  final String? fileUrl;
  final String? type;
  final String? senderClanFlag; // Adicionado e inicializado
  final String? senderFederationTag; // Adicionado e inicializado
  final String? senderClanRole; // Adicionado para resolver o erro
  final num? fileSize;
  final String? thumbnailUrl;
  final String? callId;
  final String? callStatus;
  final String? callType;
  final int? callDuration;
  final bool? isSystem; // Adicionado para mensagens do sistema

  Message({
    required this.id,
    this.clanId,
    this.federationId,
    required this.senderId,
    required this.senderName,
    this.senderRole,
    this.senderClanCustomRole,
    required this.message,
    required this.createdAt,
    this.fileUrl,
    this.type = 'text',
    this.senderClanFlag, // Inicializado no construtor
    this.senderFederationTag, // Inicializado no construtor
    this.senderClanRole, // Inicializado no construtor
    this.fileSize,
    this.thumbnailUrl,
    this.callId,
    this.callStatus,
    this.callType,
    this.callDuration,
    this.isSystem, // Inicializado no construtor
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['_id'] ?? '',
      clanId: map['clanId'],
      federationId: map['federationId'],
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Usuário Desconhecido',
      senderRole: map['senderRole'],
      senderClanCustomRole: map['senderClanCustomRole'],
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      fileUrl: map['fileUrl'],
      type: map['type'] ?? 'text',
      senderClanFlag: map['senderClanFlag'], // Mapeando o novo campo
      senderFederationTag: map['senderFederationTag'], // Mapeando o novo campo
      senderClanRole: map["senderClanRole"], // Mapeando o novo campo
      fileSize: map["fileSize"],
      thumbnailUrl: map["thumbnailUrl"],
      callId: map["callId"],
      callStatus: map["callStatus"],
      callType: map["callType"],
      callDuration: map["callDuration"],
      isSystem: map['isSystem'] ?? false, // Mapeando o novo campo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'clanId': clanId,
      'federationId': federationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderClanCustomRole': senderClanCustomRole,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'senderClanFlag': senderClanFlag,
      'senderFederationTag': senderFederationTag,
      'senderClanRole': senderClanRole,
      'isSystem': isSystem, // Incluindo no toMap
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (type != null) 'type': type,
    };
  }

  factory Message.fromJson(String source) => Message.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());

  // Adicionando o getter 'timestamp' para compatibilidade
  DateTime get timestamp => createdAt;

  // Getters vitais para o sistema respiratório (Chat UI)
  String? get senderAvatarUrl => null; // Placeholder - pode ser implementado futuramente
  String? get messageType => type; // Mapeia para o campo existente
  
  // Getters para compatibilidade com flutter_chat_ui
  String get text => message;
  String get authorId => senderId;
  String get authorName => senderName;
  
  // Getter para verificar se é mensagem de arquivo
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;
  
  // Getters adicionais para compatibilidade total
  String? get fileName {
    if (fileUrl == null) return null;
    return fileUrl!.split('/').last.split('?').first;
  }

  // Getter para extensão do arquivo
  String? get fileExtension {
    if (fileName == null) return null;
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : null;
  }

  // Getter para tipo de arquivo (se houver)
  String? get fileType {
    if (fileUrl == null) return null;
    final extension = fileUrl!.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'aac':
        return 'audio';
      case 'pdf':
      case 'doc':
      case 'docx':
        return 'document';
      default:
        return 'file';
    }
  }
}


