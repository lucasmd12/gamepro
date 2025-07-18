import 'package:flutter/material.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'Últimos 7 dias';
  bool _isLoading = false;

  final List<String> _periods = [
    'Últimas 24 horas',
    'Últimos 7 dias',
    'Últimos 30 dias',
    'Últimos 3 meses',
    'Último ano',
  ];

  @override
  Widget build(BuildContext context) {
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
                _buildReportItem('Total de Usuários', '1,247', '+12%'),
                _buildReportItem('Usuários Ativos', '892', '+8%'),
                _buildReportItem('Novos Registros', '45', '+23%'),
                _buildReportItem('Usuários Banidos', '3', '-2%'),
              ],
            ),

            const SizedBox(height: 20),

            // Relatórios de atividade
            _buildReportSection(
              'Relatório de Atividade',
              Icons.analytics,
              Colors.green,
              [
                _buildReportItem('Mensagens Enviadas', '45,678', '+15%'),
                _buildReportItem('Chamadas Realizadas', '1,234', '+7%'),
                _buildReportItem('Tempo Médio Online', '2h 34m', '+5%'),
                _buildReportItem('Canais Criados', '23', '+12%'),
              ],
            ),

            const SizedBox(height: 20),

            // Relatórios de organizações
            _buildReportSection(
              'Relatório de Organizações',
              Icons.account_tree,
              Colors.purple,
              [
                _buildReportItem('Total de Federações', '12', '+1'),
                _buildReportItem('Total de Clãs', '156', '+8'),
                _buildReportItem('Clãs Ativos', '134', '+5'),
                _buildReportItem('Média de Membros/Clã', '18.5', '+2.1'),
              ],
            ),

            const SizedBox(height: 20),

            // Relatórios do sistema
            _buildReportSection(
              'Relatório do Sistema',
              Icons.computer,
              Colors.orange,
              [
                _buildReportItem('Uptime do Servidor', '99.8%', '+0.2%'),
                _buildReportItem('Uso de CPU', '45%', '-5%'),
                _buildReportItem('Uso de Memória', '67%', '+3%'),
                _buildReportItem('Armazenamento', '234 GB', '+12 GB'),
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

  void _generateReport() {
    setState(() {
      _isLoading = true;
    });

    // Simular carregamento
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relatório atualizado para: $_selectedPeriod'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
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
}

