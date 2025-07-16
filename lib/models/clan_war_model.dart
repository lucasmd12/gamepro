import 'package:lucasbeatsfederacao/models/clan_model.dart';

enum ClanWarStatus {
  pending,
  active,
  completed,
  cancelled,
}

class ClanWarModel {
  final String id;
  final String challengerClanId;
  final String challengedClanId;
  final DateTime startTime;
  final DateTime endTime;
  final ClanWarStatus status;
  final String? winnerClanId;
  final String? description;
  final Clan? challengerClan; // Opcional, para incluir dados do clã desafiante
  final Clan? challengedClan; // Opcional, para incluir dados do clã desafiado
  final Clan? winnerClan; // Opcional, para incluir dados do clã vencedor, se disponível

  ClanWarModel({
    required this.id,
    required this.challengerClanId,
    required this.challengedClanId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.winnerClanId,
    this.description,
    this.challengerClan,
    this.challengedClan,
    this.winnerClan,
  });

  // O nome do método de fábrica foi alterado para fromMap para manter a consistência
  factory ClanWarModel.fromMap(Map<String, dynamic> map) {
    return ClanWarModel(
      id: map["_id"] as String? ?? map["id"] as String? ?? '', // Aceita _id ou id
      challengerClanId: map["challengerClanId"] as String,
      challengedClanId: map["challengedClanId"] as String,
      startTime: DateTime.parse(map["startTime"] as String),
      endTime: DateTime.parse(map["endTime"] as String),
      status: ClanWarStatus.values.firstWhere(
          (e) => e.toString().split(".").last == map["status"],
          orElse: () => ClanWarStatus.pending), // Adicionado orElse para segurança
      winnerClanId: map["winnerClanId"] as String?,
      description: map["description"] as String?,

      // CORREÇÃO: Chamando Clan.fromMap em vez de Clan.fromJson
      challengerClan: map["challengerClan"] != null && map["challengerClan"] is Map<String, dynamic>
          ? Clan.fromMap(map["challengerClan"] as Map<String, dynamic>)
          : null,
          
      // CORREÇÃO: Chamando Clan.fromMap em vez de Clan.fromJson
      winnerClan: map["winnerClan"] != null && map["winnerClan"] is Map<String, dynamic>
          ? Clan.fromMap(map["winnerClan"] as Map<String, dynamic>)
          : null,
          
      // CORREÇÃO: Chamando Clan.fromMap em vez de Clan.fromJson
      challengedClan: map["challengedClan"] != null && map["challengedClan"] is Map<String, dynamic>
          ? Clan.fromMap(map["challengedClan"] as Map<String, dynamic>)
          : null,
    );
  }

  // O nome do método de serialização foi alterado para toMap para manter a consistência
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "challengerClanId": challengerClanId,
      "challengedClanId": challengedClanId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
      "status": status.toString().split(".").last,
      "winnerClanId": winnerClanId,
      "description": description,
      // CORREÇÃO: Chamando toMap para consistência
      "challengerClan": challengerClan?.toMap(),
      "challengedClan": challengedClan?.toMap(),
      "winnerClan": winnerClan?.toMap(),
    };
  }
}
