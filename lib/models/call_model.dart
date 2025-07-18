import 'dart:convert';

enum CallStatus {
  active,
  ended,
  pending,
  accepted,
  rejected,
}

enum CallType {
  audio,
  video,
}

class Call {
  final String id;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
 final String? roomName;
 final String? callerName;
  final DateTime? endTime;

  Call({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
 this.roomName,
 this.callerName,
    required this.startTime,
    this.endTime,
  });

  factory Call.fromMap(Map<String, dynamic> map) {
    return Call(
      id: map['id'] ?? '',
      callerId: map['callerId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      type: CallType.values.firstWhere(
 (e) => e.toString().split('.').last == map['type'],
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => CallStatus.ended, // Using 'ended' as a safe default for unknown statuses
      ),
 roomName: map['roomName'],
 callerName: map['callerName'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
 if (roomName != null) 'roomName': roomName,
 if (callerName != null) 'callerName': callerName,
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory Call.fromJson(String source) => Call.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());

  Call copyWith({
    String? id,
    String? callerId,
    String? receiverId,
    CallType? type,
    CallStatus? status,
    DateTime? startTime,
    DateTime? endTime,
 String? roomName,
 String? callerName,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
 roomName: roomName ?? this.roomName,
 callerName: callerName ?? this.callerName,
      endTime: endTime ?? this.endTime,
    );
  }
}


