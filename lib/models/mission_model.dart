import 'dart:convert';

class Mission {
  final String id;
  final String name;
  final String description;
  final String clanId;
  final DateTime scheduledTime;
  final int targetProgress; // quantidade que deve ser atingida
  final int currentProgress; // valor atual (controlado no frontend)
  final List<String> confirmedMembers;
  final List<String> strategyMediaUrls;
  final String status;

  Mission({
    required this.id,
    required this.name,
    required this.description,
    required this.clanId,
    required this.scheduledTime,
    this.targetProgress = 100,
    this.currentProgress = 0,
    List<String>? confirmedMembers,
    List<String>? strategyMediaUrls,
    this.status = 'pending',
  }) : confirmedMembers = confirmedMembers ?? [],
       strategyMediaUrls = strategyMediaUrls ?? [];


  bool get isCompleted => currentProgress >= targetProgress || status == 'completed';


  Mission copyWith({
    String? id,
    String? name,
    String? description,
    String? clanId,
    DateTime? scheduledTime,
    int? targetProgress,
    int? currentProgress,
    List<String>? confirmedMembers,
    List<String>? strategyMediaUrls,
    String? status,
  }) {
    return Mission(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      clanId: clanId ?? this.clanId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      targetProgress: targetProgress ?? this.targetProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      confirmedMembers: confirmedMembers ?? this.confirmedMembers,
      strategyMediaUrls: strategyMediaUrls ?? this.strategyMediaUrls,
      status: status ?? this.status,
    );
  }

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['_id'] as String? ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      clanId: map['clan'] as String? ?? '', // Assumindo que 'clan' no backend é o clanId
      scheduledTime: DateTime.parse(map['scheduledTime']),
      targetProgress: map['targetProgress'] as int? ?? 100,
      currentProgress: map['currentProgress'] as int? ?? 0,
      confirmedMembers: List<String>.from(map['confirmedMembers'] ?? []),
      strategyMediaUrls: List<String>.from(map['strategyMediaUrls'] ?? []),
      status: map['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'clan': clanId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'targetProgress': targetProgress,
      'currentProgress': currentProgress,
      'confirmedMembers': confirmedMembers,
      'strategyMediaUrls': strategyMediaUrls,
      'status': status,
    };
  }

  factory Mission.fromJson(String source) => Mission.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}

