import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // e.g., 'clan_invite', 'global_message', 'clan_message', 'federation_message'
  final Map<String, dynamic>? data; // Dados adicionais para ações ou contexto
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  // Factory constructor para criar NotificationModel a partir de um mapa (ex: de FCM)
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map["id"] ?? UniqueKey().toString(), // Gerar um ID se não houver
      title: map["title"] ?? ">Sem Título<",
      body: map["body"] ?? ">Sem Conteúdo<",
      type: map["type"] ?? "general",
      data: map["data"] is Map ? Map<String, dynamic>.from(map["data"]) : null,
      timestamp: map["timestamp"] != null
          ? DateTime.parse(map["timestamp"])
          : DateTime.now(),
      isRead: map["isRead"] ?? false,
    );
  }

  // Método para converter NotificationModel para um mapa (ex: para persistência)
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "body": body,
      "type": type,
      "data": data,
      "timestamp": timestamp.toIso8601String(),
      "isRead": isRead,
    };
  }
}


