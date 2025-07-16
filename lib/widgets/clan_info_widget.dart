import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/member_model.dart';

class ClanInfoWidget extends StatefulWidget {
  final String clanId;

  const ClanInfoWidget({
    super.key,
    required this.clanId,
  });

  @override
  State<ClanInfoWidget> createState() => _ClanInfoWidgetState();
}

class _ClanInfoWidgetState extends State<ClanInfoWidget> {
  Clan? _clan;
  List<Member> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClanInfo();
  }

  Future<void> _loadClanInfo() async {
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final clan = await clanService.getClanById(widget.clanId);
      final members = await clanService.getClanMembers(widget.clanId);

      if (mounted) {
        setState(() {
          _clan = clan;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar informações do clã', error: e);
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar clã: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        color: Colors.grey.shade800.withValues(alpha: 0.8),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        color: Colors.grey.shade800.withValues(alpha: 0.8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_clan == null) {
      return Card(
        color: Colors.grey.shade800.withValues(alpha: 0.8),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Clã não encontrado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Card(
      color: Colors.grey.shade800.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Banner do clã
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade700,
                    image: (_clan!.flag != null && _clan!.flag!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(_clan!.flag!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (_clan!.flag == null || _clan!.flag!.isEmpty)
                      ? Icon(
                          Icons.shield,
                          color: Colors.grey.shade400,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _clan!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_clan!.tag.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _clan!.tag,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_clan!.members?.length ?? 0} membros',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildClanStats(),
            const SizedBox(height: 12),
            _buildOnlineMembers(),
          ],
        ),
      ),
    );
  }

  Widget _buildClanStats() {
    final onlineMembersCount = _members.where((m) => m.isOnline).length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            'Membros Online',
            '$onlineMembersCount',
            Icons.people,
          ),
          _buildStatColumn(
            'Canais de Voz',
            '${_clan!.voiceChannels?.length ?? 0}',
            Icons.headset,
          ),
          _buildStatColumn(
            'Canais de Texto',
            '${_clan!.textChannels?.length ?? 0}',
            Icons.chat,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOnlineMembers() {
    final onlineMembers = _members.where((m) => m.isOnline).toList();
    
    if (onlineMembers.isEmpty) {
      return Text(
        'Nenhum membro online',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Membros Online (${onlineMembers.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: onlineMembers.take(5).map((member) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                member.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
        if (onlineMembers.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${onlineMembers.length - 5} outros',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }
}


