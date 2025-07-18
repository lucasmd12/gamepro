import 'package:flutter/material.dart';

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() => _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  bool _maintenanceMode = false;
  bool _registrationEnabled = true;
  bool _chatEnabled = true;
  bool _voiceEnabled = true;
  bool _notificationsEnabled = true;
  int _maxUsersPerClan = 50;
  int _maxClansPerFederation = 20;
  String _serverRegion = 'Brasil';

  final List<String> _regions = ['Brasil', 'Estados Unidos', 'Europa', 'Ásia'];

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
                'Conteúdo das Configurações do Sistema ADM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Configurações gerais
            _buildSettingsSection(
              'Configurações Gerais',
              Icons.settings,
              Colors.blue,
              [
                _buildSwitchSetting(
                  'Modo de Manutenção',
                  'Desabilita o acesso de usuários ao sistema',
                  _maintenanceMode,
                  (value) => setState(() => _maintenanceMode = value),
                  Colors.red,
                ),
                _buildSwitchSetting(
                  'Registro de Novos Usuários',
                  'Permite que novos usuários se registrem',
                  _registrationEnabled,
                  (value) => setState(() => _registrationEnabled = value),
                  Colors.green,
                ),
                _buildDropdownSetting(
                  'Região do Servidor',
                  'Selecione a região principal do servidor',
                  _serverRegion,
                  _regions,
                  (value) => setState(() => _serverRegion = value!),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Configurações de funcionalidades
            _buildSettingsSection(
              'Funcionalidades',
              Icons.apps,
              Colors.green,
              [
                _buildSwitchSetting(
                  'Sistema de Chat',
                  'Habilita/desabilita o sistema de chat',
                  _chatEnabled,
                  (value) => setState(() => _chatEnabled = value),
                  Colors.blue,
                ),
                _buildSwitchSetting(
                  'Sistema de Voz',
                  'Habilita/desabilita chamadas de voz',
                  _voiceEnabled,
                  (value) => setState(() => _voiceEnabled = value),
                  Colors.purple,
                ),
                _buildSwitchSetting(
                  'Notificações Push',
                  'Habilita/desabilita notificações push',
                  _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Limites do sistema
            _buildSettingsSection(
              'Limites do Sistema',
              Icons.security,
              Colors.orange,
              [
                _buildSliderSetting(
                  'Máximo de Usuários por Clã',
                  'Define o limite máximo de membros em um clã',
                  _maxUsersPerClan.toDouble(),
                  10,
                  100,
                  (value) => setState(() => _maxUsersPerClan = value.round()),
                ),
                _buildSliderSetting(
                  'Máximo de Clãs por Federação',
                  'Define o limite máximo de clãs em uma federação',
                  _maxClansPerFederation.toDouble(),
                  5,
                  50,
                  (value) => setState(() => _maxClansPerFederation = value.round()),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Configurações de segurança
            _buildSettingsSection(
              'Segurança',
              Icons.shield,
              Colors.red,
              [
                _buildActionSetting(
                  'Backup do Sistema',
                  'Criar backup completo do sistema',
                  Icons.backup,
                  Colors.blue,
                  _createBackup,
                ),
                _buildActionSetting(
                  'Limpar Cache',
                  'Limpar cache do sistema para melhor performance',
                  Icons.cleaning_services,
                  Colors.orange,
                  _clearCache,
                ),
                _buildActionSetting(
                  'Reiniciar Servidor',
                  'Reiniciar o servidor (todos os usuários serão desconectados)',
                  Icons.restart_alt,
                  Colors.red,
                  _restartServer,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botão de salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Configurações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, Color color, List<Widget> settings) {
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
          ...settings,
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String title, String description, bool value, Function(bool) onChanged, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(String title, String description, String value, List<String> options, Function(String?) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.grey[700],
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String title, String description, double value, double min, double max, Function(double) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${value.round()}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[600],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(String title, String description, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Criar Backup', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Deseja criar um backup completo do sistema? Este processo pode levar alguns minutos.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup iniciado...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Criar Backup'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache limpo com sucesso!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _restartServer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Reiniciar Servidor', style: TextStyle(color: Colors.white)),
        content: const Text(
          'ATENÇÃO: Esta ação irá desconectar todos os usuários e reiniciar o servidor. Tem certeza que deseja continuar?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Servidor será reiniciado em 30 segundos...'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

