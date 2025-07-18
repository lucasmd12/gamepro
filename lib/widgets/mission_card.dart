import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/mission_model.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final Function(Mission) onMissionTap;
  final VoidCallback? onClanAction; // Callback para ação QRR
  final bool isClanActionLoading;   // Loading para ação QRR
  final String clanActionLabel;     // Texto do botão QRR

  const MissionCard({
    super.key,
    required this.mission,
    required this.onMissionTap,
    this.onClanAction,
    this.isClanActionLoading = false,
    this.clanActionLabel = 'Confirmar Presença',
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = mission.currentProgress / mission.targetProgress;
    final isCompleted = mission.isCompleted;
    final canClaim = progressPercentage >= 1.0 && !isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade800.withValues(alpha: 0.8),
      child: InkWell(
        onTap: () => onMissionTap(mission),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da missão
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      // color: _getMissionTypeColor(mission.type), // Comentado: type não definido no modelo Mission
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.assignment, // Ícone genérico, já que mission.type não existe
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.name, // Usando mission.name no lugar de mission.title
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Missão', // Texto genérico, já que mission.type não existe
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'CONCLUÍDA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (canClaim)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'RESGATAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Descrição da missão
              Text(
                mission.description,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Progresso
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progresso',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${mission.currentProgress}/${mission.targetProgress}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progressPercentage.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade600,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted 
                              ? Colors.green 
                              : canClaim 
                                ? Colors.orange 
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Recompensa
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.yellow.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recompensa: N/A', // Texto genérico, já que rewardDescription não existe
                      style: TextStyle(
                        color: Colors.yellow.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // --- Botão estilizado exclusivo para missão de clã/QRR ---
              // if (mission.type == MissionType.clan || mission.type == MissionType.qrr) // Comentado: type e MissionType não definidos
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: isClanActionLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.emoji_events, color: Colors.white),
                      label: Text(
                        clanActionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: isClanActionLoading || onClanAction == null ? null : onClanAction,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


