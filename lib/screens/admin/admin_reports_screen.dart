import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/stats_service.dart';
import 'package:lucasbeatsfederacao/services/admin_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'Últimos 7 dias';
  bool _isLoading = false;
  Map<String, dynamic> _reportData = {};
  String? _error;

  final List<String> _periods = [
    'Últimas 24 horas',
    'Últimos 7 dias',
    'Últimos 30 dias',
    'Últimos 3 meses',
    'Último ano',
  ];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  void _loadReportData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statsService = Provider.of<StatsService>(context, listen: false);
      final adminService = Provider.of<AdminService>(context, listen: false);

      // Fetch data for different report sections
      final globalStats = await statsService.getGlobalStats(); // Pass selected period
      // final userStats = await statsService.getUserStats(period: _selectedPeriod); // Assuming this method exists or will be added
      // final clanFederationStats = await statsService.getClanFederationStats(period: _selectedPeriod); // Assuming this method exists or will be added
      final systemLogs = await adminService.getSystemLogs(); // Assuming this method exists or will be added

      if (mounted) {
        setState(() {
          _reportData = {
            'userReports': {
              'totalUsers': globalStats['totalUsers'] ?? 0,
              'onlineUsers': int.tryParse(globalStats['onlineUsers']?.toString() ?? '0') ?? 0,
 'newRegistrations': 0, // Data source needs to be confirmed
 'bannedUsers': 0, // Data source needs to be confirmed
            },
            'activityReports': {
              'messagesSent': int.tryParse(globalStats['totalMessages']?.toString() ?? '0') ?? 0,
              'callsMade': int.tryParse(globalStats['activeCalls']?.toString() ?? '0') ?? 0,
              'avgOnlineTime': globalStats['avgOnlineTime'] ?? 'N/A',
              'channelsCreated': globalStats['channelsCreated'] ?? 'N/A',
            },
            'organizationReports': {
              'totalFederations': int.tryParse(globalStats['totalFederations']?.toString() ?? '0') ?? 0,
              'totalClans': int.tryParse(globalStats['totalClans']?.toString() ?? '0') ?? 0,
 'activeClans': 0, // Data source needs to be confirmed
 'avgMembersPerClan': 'N/A', // Data source needs to be confirmed
            },
            'systemReports': {
              'serverUptime': systemLogs['serverUptime'] ?? 'N/A',
              'cpuUsage': systemLogs['cpuUsage'] ?? 'N/A',
              'memoryUsage': systemLogs['memoryUsage'] ?? 'N/A',
              'storageUsed': systemLogs['storageUsed'] ?? 'N/A',
            },
          };
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao carregar dados do relatório', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar dados do relatório: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _generateReport() {
    _loadReportData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Relatório atualizado para: $_selectedPeriod'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando relatório em PDF...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compartilhando relatório...'),
        backgroundColor: Colors.green,
      ),
    );
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
              onPressed: _loadReportData,
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
                  'Conteúdo dos Relatórios ADM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Seletor de período
              Row(
                children: [
                  const Text(
                    'Período:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[600]!),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        isExpanded: true,
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        items: _periods.map((String period) {
                          return DropdownMenuItem<String>(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPeriod = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _generateReport,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Atualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Relatórios de usuários
              _buildReportSection(
                'Relatório de Usuários',
                Icons.people,
                Colors.blue,
                [
                  _buildReportItem('Total de Usuários', '${_reportData['userReports']?['totalUsers'] ?? 'N/A'}', '+12%'),
                  _buildReportItem('Usuários Online', '${_reportData['userReports']?['onlineUsers'] ?? 'N/A'}', '+8%'),
                  _buildReportItem('Novos Registros', '${_reportData['userReports']?['newRegistrations'] ?? 'N/A'}', '+23%'),
                  _buildReportItem('Usuários Banidos', '${_reportData['userReports']?['bannedUsers'] ?? 'N/A'}', '-2%'),
                ],
              ),

              const SizedBox(height: 20),

              // Relatórios de atividade
              _buildReportSection(
                'Relatório de Atividade',
                Icons.analytics,
                Colors.green,
                [
                  _buildReportItem('Mensagens Enviadas', '${_reportData['activityReports']?['messagesSent'] ?? 'N/A'}', '+15%'),
                  _buildReportItem('Chamadas Realizadas', '${_reportData['activityReports']?['callsMade'] ?? 'N/A'}', '+7%'),
                  _buildReportItem('Tempo Médio Online', '${_reportData['activityReports']?['avgOnlineTime'] ?? 'N/A'}', '+5%'),
                  _buildReportItem('Canais Criados', '${_reportData['activityReports']?['channelsCreated'] ?? 'N/A'}', '+12%'),
                ],
              ),

              const SizedBox(height: 20),

              // Relatórios de organizações
              _buildReportSection(
                'Relatório de Organizações',
                Icons.account_tree,
                Colors.purple,
                [
                  _buildReportItem('Total de Federações', '${_reportData['organizationReports']?['totalFederations'] ?? 'N/A'}', '+1'),
                  _buildReportItem('Total de Clãs', '${_reportData['organizationReports']?['totalClans'] ?? 'N/A'}', '+8'),
                  _buildReportItem('Clãs Ativos', '${_reportData['organizationReports']?['activeClans'] ?? 'N/A'}', '+5'),
                  _buildReportItem('Média de Membros/Clã', '${_reportData['organizationReports']?['avgMembersPerClan'] ?? 'N/A'}', '+2.1'),
                ],
              ),

              const SizedBox(height: 20),

              // Relatórios do sistema
              _buildReportSection(
                'Relatório do Sistema',
                Icons.computer,
                Colors.orange,
                [
                  _buildReportItem('Uptime do Servidor', '${_reportData['systemReports']?['serverUptime'] ?? 'N/A'}', '+0.2%'),
                  _buildReportItem('Uso de CPU', '${_reportData['systemReports']?['cpuUsage'] ?? 'N/A'}', '-5%'),
                  _buildReportItem('Uso de Memória', '${_reportData['systemReports']?['memoryUsage'] ?? 'N/A'}', '+3%'),
                  _buildReportItem('Armazenamento', '${_reportData['systemReports']?['storageUsed'] ?? 'N/A'}', '+12 GB'),
                ],
              ),

              const SizedBox(height: 24),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportReport,
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareReport,
                      icon: const Icon(Icons.share),
                      label: const Text('Compartilhar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildReportSection(String title, IconData icon, Color color, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildReportItem(String label, String value, String change) {
    final isPositive = change.startsWith('+');
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: changeColor.withOpacity(0.5)),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


