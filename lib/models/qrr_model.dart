import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';

enum QRRType {
  mission("Missão"),
  event("Evento"),
  training("Treinamento"),
  operation("Operação"),
  rule("Regra");

  final String displayName;
  const QRRType(this.displayName);

  IconData get icon {
    switch (this) {
      case QRRType.mission:
        return Icons.military_tech;
      case QRRType.event:
        return Icons.event;
      case QRRType.training:
        return Icons.fitness_center;
      case QRRType.operation:
        return Icons.precision_manufacturing;
      case QRRType.rule:
        return Icons.gavel;
    }
  }
}

enum QRRPriority {
  low("Baixa"),
  medium("Média"),
  high("Alta"),
  critical("Crítica");

  final String displayName;
  const QRRPriority(this.displayName);

  Color get color {
    switch (this) {
      case QRRPriority.low:
        return Colors.green;
      case QRRPriority.medium:
        return Colors.yellow.shade700;
      case QRRPriority.high:
        return Colors.orange;
      case QRRPriority.critical:
        return Colors.red;
    }
  }
}

enum QRRStatus {
  active("Ativa"),
  pending("Pendente"),
  completed("Concluída"),
  cancelled("Cancelada");

  final String displayName;
  const QRRStatus(this.displayName);

  Color get color {
    switch (this) {
      case QRRStatus.active:
        return Colors.blue;
      case QRRStatus.pending:
        return Colors.grey;
      case QRRStatus.completed:
        return Colors.green;
      case QRRStatus.cancelled:
        return Colors.red;
    }
  }

  bool get isActive => this == QRRStatus.active;
  bool get isPending => this == QRRStatus.pending;
  bool get isCompleted => this == QRRStatus.completed;
  bool get isCancelled => this == QRRStatus.cancelled;
}

class QRRModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final QRRStatus status;
  final QRRType type;
  final QRRPriority priority;
  final String createdBy;
  final List<User> participants;
  final List<Map<String, dynamic>>? performanceMetrics;
  final String? clanId;
  final String? federationId;
  final String? location;
  final String? notes;
  final Color? displayColor;
  final IconData? displayIcon;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? maxParticipants;
  final String? result; // Adicionado como propriedade para evitar 'this' em getter
  final String? imageUrl; // Adicionado como propriedade para evitar 'this' em getter
  final Duration? duration; // Adicionado como propriedade para evitar 'this' em getter
  final List<String>? requiredRoles; // Adicionado como propriedade para evitar 'this' em getter
  final String? enemyClanId; // Novo campo
  final String? enemyClanFlagUrl; // Novo campo

  QRRModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.type,
    required this.priority,
    required this.createdBy,
    required this.participants,
    this.performanceMetrics,
    this.clanId,
    this.federationId,
    this.location,
    this.notes,
    this.displayColor,
    this.displayIcon,
    this.startTime,
    this.endTime,
    this.maxParticipants,
    this.result, // Inicializado no construtor
    this.imageUrl, // Inicializado no construtor
    this.duration, // Inicializado no construtor
    this.requiredRoles, // Inicializado no construtor
    this.enemyClanId, // Inicializado no construtor
    this.enemyClanFlagUrl, // Inicializado no construtor
  });

  factory QRRModel.fromJson(Map<String, dynamic> json) {
    Color? color;
    if (json["displayColor"] != null) {
      switch (json["displayColor"]) {
        case 'red':
          color = Colors.red;
          break;
        case 'blue':
          color = Colors.blue;
          break;
        case 'green':
          color = Colors.green;
          break;
        case 'yellow':
          color = Colors.yellow;
          break;
        case 'orange':
          color = Colors.orange;
          break;
        default:
          color = null;
      }
    }

    IconData? icon;
    if (json["displayIcon"] != null) {
      switch (json["displayIcon"]) {
        case 'star':
          icon = Icons.star;
          break;
        case 'flag':
          icon = Icons.flag;
          break;
        case 'check':
          icon = Icons.check_circle;
          break;
        case 'warning':
          icon = Icons.warning;
          break;
        case 'info':
          icon = Icons.info;
          break;
        case 'event':
          icon = Icons.event;
          break;
        default:
          icon = null;
      }
    }

    final parsedStartDate = DateTime.parse(json["startDate"] as String);
    final parsedEndDate = DateTime.parse(json["endDate"] as String);
    final parsedStartTime = json["startTime"] != null ? DateTime.parse(json["startTime"] as String) : null;
    final parsedEndTime = json["endTime"] != null ? DateTime.parse(json["endTime"] as String) : null;

    Duration? calculatedDuration;
    if (parsedStartTime != null && parsedEndTime != null) {
      calculatedDuration = parsedEndTime.difference(parsedStartTime);
    } else {
      calculatedDuration = parsedEndDate.difference(parsedStartDate);
    }

    return QRRModel(
      id: json["_id"] as String,
      title: json["title"] as String,
      description: json["description"] as String,
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      status: QRRStatus.values.firstWhere((e) => e.name == json["status"] as String),
      type: QRRType.values.firstWhere((e) => e.name == json["type"] as String),
      priority: QRRPriority.values.firstWhere((e) => e.name == json["priority"] as String),
      createdBy: json["createdBy"] as String,
      participants: (json["participants"] as List<dynamic>)
          .map((p) => User.fromJson(p as Map<String, dynamic>))
          .toList(),
      performanceMetrics: json["performanceMetrics"] != null
          ? List<Map<String, dynamic>>.from(json["performanceMetrics"])
          : null,
      clanId: json["clanId"] as String?,
      federationId: json["federationId"] as String?,
      location: json["location"] as String?,
      notes: json["notes"] as String?,
      displayColor: color,
      displayIcon: icon,
      startTime: parsedStartTime,
      endTime: parsedEndTime,
      maxParticipants: json["maxParticipants"] as int?,
      result: (QRRStatus.values.firstWhere((e) => e.name == json["status"] as String)).isCompleted ? 'Concluída com sucesso' : null,
      imageUrl: json["imageUrl"] as String?, // Usar o campo real do JSON
      duration: calculatedDuration,
      requiredRoles: (json["requiredRoles"] as List<dynamic>?)?.map((e) => e as String).toList(), // Usar o campo real do JSON
      enemyClanId: json["enemyClanId"] as String?,
      enemyClanFlagUrl: json["enemyClanFlagUrl"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String? colorString;
    if (displayColor != null) {
      if (displayColor == Colors.red) colorString = 'red';
      if (displayColor == Colors.blue) colorString = 'blue';
      if (displayColor == Colors.green) colorString = 'green';
      if (displayColor == Colors.yellow) colorString = 'yellow';
      if (displayColor == Colors.orange) colorString = 'orange';
    }

    String? iconString;
    if (displayIcon != null) {
      if (displayIcon == Icons.star) iconString = 'star';
      if (displayIcon == Icons.flag) iconString = 'flag';
      if (displayIcon == Icons.check_circle) iconString = 'check';
      if (displayIcon == Icons.warning) iconString = 'warning';
      if (displayIcon == Icons.info) iconString = 'info';
      if (displayIcon == Icons.event) iconString = 'event';
    }

    return {
      '_id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'priority': priority.name,
      'createdBy': createdBy,
      'participants': participants.map((p) => p.toJson()).toList(),
      if (performanceMetrics != null) 'performanceMetrics': performanceMetrics,
      if (clanId != null) 'clanId': clanId,
      if (federationId != null) 'federationId': federationId,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (colorString != null) 'displayColor': colorString,
      if (iconString != null) 'displayIcon': iconString,
      if (startTime != null) 'startTime': startTime!.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (requiredRoles != null) 'requiredRoles': requiredRoles,
      if (enemyClanId != null) 'enemyClanId': enemyClanId,
      if (enemyClanFlagUrl != null) 'enemyClanFlagUrl': enemyClanFlagUrl,
    };
  }

  bool userIsParticipant(String userId) {
    return participants.any((p) => p.id == userId);
  }

  int get participantCount => participants.length;

  // Métodos vitais para funcionamento
  bool canUserJoin(String userId) {
    if (status != QRRStatus.active && status != QRRStatus.pending) return false;
    if (maxParticipants != null && participantCount >= maxParticipants!) return false;
    return !userIsParticipant(userId);
  }

  // Getters de compatibilidade
  bool get isActive => status.isActive;
  bool get isPending => status.isPending;
  bool get isCompleted => status.isCompleted;
  bool get isCancelled => status.isCancelled;
  
  // Getter para verificar se pode ser editado
  bool get canBeEdited => status == QRRStatus.pending || status == QRRStatus.active;
  
  // Getter para verificar se está em andamento
  bool get isInProgress {
    final now = DateTime.now();
    return status.isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  // Getter para verificar se já passou do prazo
  bool get isOverdue {
    final now = DateTime.now();
    return !status.isCompleted && now.isAfter(endDate);
  }
}




