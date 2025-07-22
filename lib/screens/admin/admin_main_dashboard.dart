import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_user_management.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_organization_management.dart'; // Importar
import 'package:lucasbeatsfederacao/screens/admin/admin_system_settings.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_reports_screen.dart';
import 'package:lucasbeatsfederacao/services/stats_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class AdminMainDashboard extends StatefulWidget {
  const AdminMainDashboard({super.key});

  @override
  State<AdminMainDashboard> createState() => _AdminMainDashboardState();
}

class _AdminMainDashboardState extends State<AdminMainDashboard> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    try {
      final statsService = Provider.of<StatsService>(context, listen: false);
      final fetchedStats = await statsService.getGlobalStats();
      if (mounted) {
        setState(() {
          _stats = {
            'totalUsers': fetchedStats['totalUsers'] ?? 0,
            'onlineUsers': fetchedStats['onlineUsers'] ?? 0,
            'totalFederations': fetchedStats['totalFederations'] ?? 0, // Corrigido para totalFederations
            'totalClans': fetchedStats['totalClans'] ?? 0, // Corrigido para totalClans
            'activeCalls': fetchedStats['activeCalls'] ?? 0,
            'totalMessages': fetchedStats['totalMessages'] ?? 0,
            'systemHealth': 100.0, // Backend não fornece, manter mock ou remover
            'serverUptime': 'N/A', // Backend não fornece, manter mock ou remover
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar dados do dashboard: $e');
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar dados: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    } else if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Conteúdo do Dashboard Principal ADM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Estatísticas principais
              _buildStatsGrid(),

              const SizedBox(height: 24),

              // Gráfico de atividade (manter mock por enquanto, pois backend não fornece dados de atividade granular)
              _buildActivityChart(),

              const SizedBox(height: 24),

              // Ações rápidas (manter navegação mock por enquanto)
              _buildQuickActions(),

              const SizedBox(height: 24),

              // Status do sistema (manter mock por enquanto, pois backend não fornece)
              _buildSystemStatus(),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Usuários Totais',
          '${_stats['totalUsers']}',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Usuários Online',
          '${_stats['onlineUsers']}',
          Icons.people_outline,
          Colors.green,
        ),
        _buildStatCard(
          'Federações',
          '${_stats['totalFederations']}',
          Icons.account_tree,
          Colors.purple,
        ),
        _buildStatCard(
          'Clãs',
          '${_stats['totalClans']}',
          Icons.groups,
          Colors.orange,
        ),
        _buildStatCard(
          'Chamadas Ativas',
          '${_stats['activeCalls']}',
          Icons.call,
          Colors.red,
        ),
        _buildStatCard(
          'Mensagens',
          '${_stats['totalMessages']}',
          Icons.message,
          Colors.cyan,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atividade nas Últimas 24h',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                final height = (index + 1) * 15.0;
                return Container(
                  width: 20,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text('12:00', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text('24:00', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ações Rápidas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Gerenciar Usuários',
                  Icons.people,
                  Colors.blue,
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUserManagementScreen()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Gerenciar Organizações',
                  Icons.account_tree,
                  Colors.purple,
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminOrganizationManagementScreen()));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Configurações do Sistema',
                  Icons.settings,
                  Colors.grey,
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSystemSettingsScreen()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Relatórios e Análises',
                  Icons.analytics,
                  Colors.green,
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminReportsScreen()));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Logs do Sistema',
                  Icons.receipt_long,
                  Colors.cyan,
                  () {
                    // TODO: Implementar navegação para tela de logs do sistema
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade de Logs do Sistema em desenvolvimento.'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Gerenciar Convites',
                  Icons.mail,
                  Colors.orange,
                  () {
                    // TODO: Implementar navegação para tela de gerenciamento de convites
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade de Gerenciamento de Convites em desenvolvimento.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status do Sistema',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusItem(
            'Saúde do Sistema',
            '${_stats['systemHealth']}%',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatusItem(
            'Tempo Online',
            '${_stats['serverUptime']}',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatusItem(
            'Última Atualização',
            'Há 2 minutos',
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}


