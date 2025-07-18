import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class GlobalStatsWidget extends StatefulWidget {
  const GlobalStatsWidget({super.key});

  @override
  State<GlobalStatsWidget> createState() => _GlobalStatsWidgetState();
}

class _GlobalStatsWidgetState extends State<GlobalStatsWidget> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _setupRealTimeUpdates();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final apiService = ApiService();
      final response = await apiService.get('/api/stats/global');
      
      setState(() {
        _stats = response ?? {};
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar estatísticas: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Usar dados de fallback
        _stats = _getFallbackStats();
      });
    }
  }

  void _setupRealTimeUpdates() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.statsUpdateStream.listen((data) {
      if (mounted) {
        setState(() {
          _stats = {..._stats, ...data};
        });
      }
    });
  }

  Map<String, dynamic> _getFallbackStats() {
    return {
      'totalUsers': 0,
      'onlineUsers': 0,
      'totalFederations': 1,
      'activeCalls': 0,
      'totalMessages': 0,
      'activeClans': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estatísticas Globais',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadStats,
              ),
            ],
          ),
          
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dados offline - Conectando ao servidor...',
                      style: TextStyle(color: Colors.orange[300]),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Estatísticas principais
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Usuários Totais', 
                _stats['totalUsers']?.toString() ?? '0', 
                Icons.people, 
                Colors.blue
              ),
              _buildStatCard(
                'Usuários Online', 
                _stats['onlineUsers']?.toString() ?? '0', 
                Icons.circle, 
                Colors.green
              ),
              _buildStatCard(
                'Federações', 
                _stats['totalFederations']?.toString() ?? '1', 
                Icons.group_work, 
                Colors.purple
              ),
              _buildStatCard(
                'Clãs Ativos', 
                _stats['activeClans']?.toString() ?? '0', 
                Icons.groups, 
                Colors.orange
              ),
              _buildStatCard(
                'Chamadas Ativas', 
                _stats['activeCalls']?.toString() ?? '0', 
                Icons.call, 
                Colors.teal
              ),
              _buildStatCard(
                'Mensagens Hoje', 
                _stats['totalMessages']?.toString() ?? '0', 
                Icons.message, 
                Colors.indigo
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status do servidor
          Card(
            color: Colors.grey.shade800.withValues(alpha: 0.8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status do Servidor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _error == null ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _error == null ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: _error == null ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Última atualização: ${DateTime.now().toString().substring(11, 19)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.grey.shade800.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

