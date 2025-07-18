
class InviteModel {
  final String id;
  final String type;
  final String targetId;
  final String senderId;
  final String recipientId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String targetName; // Nome do clã/federação
  final String senderName; // Nome do remetente

  InviteModel({
    required this.id,
    required this.type,
    required this.targetId,
    required this.senderId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.targetName,
    required this.senderName,
  });

  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['_id'] as String,
      type: json['type'] as String,
      targetId: json['target'] as String,
      senderId: json['sender'] as String,
      recipientId: json['recipient'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      targetName: json['target'] != null && json['target']['name'] != null
          ? json['target']['name'] as String
          : 'N/A',
      senderName: json['sender'] != null && json['sender']['username'] != null
          ? json['sender']['username'] as String
          : 'N/A',
    );
  }
}


