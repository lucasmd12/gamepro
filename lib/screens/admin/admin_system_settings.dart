import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/admin_service.dart';
import 'package:lucasbeatsfederacao/models/system_setting.dart';
import 'package:lucasbeatsfederacao/services/notification_service.dart'; // Import adicionado

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() => _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  final NotificationService _notificationService = NotificationService(); // Instância do NotificationService
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações do Sistema")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingsSection(
                    "Configurações Gerais",
                    Icons.settings,
                    Colors.blue,
                    [
                      _buildSwitchSetting(
                        "Modo de Manutenção",
                        "Ativa ou desativa o modo de manutenção do sistema.",
                        _currentSettings.maintenanceMode,
                        (value) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(maintenanceMode: value);
                          });
                        },
                        Colors.blue,
                      ),
                      _buildSwitchSetting(
                        "Registro de Usuários",
                        "Permite ou impede novos registros de usuários.",
                        _currentSettings.registrationEnabled,
                        (value) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(registrationEnabled: value);
                          });
                        },
                        Colors.blue,
                      ),
                      _buildSwitchSetting(
                        "Chat Habilitado",
                        "Ativa ou desativa o sistema de chat global.",
                        _currentSettings.chatEnabled,
                        (value) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(chatEnabled: value);
                          });
                        },
                        Colors.blue,
                      ),
                      _buildSwitchSetting(
                        "Voz Habilitada",
                        "Ativa ou desativa as funcionalidades de voz (VoIP).",
                        _currentSettings.voiceEnabled,
                        (value) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(voiceEnabled: value);
                          });
                        },
                        Colors.blue,
                      ),
                      _buildSwitchSetting(
                        "Notificações Habilitadas",
                        "Ativa ou desativa o envio de notificações push.",
                        _currentSettings.notificationsEnabled,
                        (value) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(notificationsEnabled: value);
                          });
                        },
                        Colors.blue,
                      ),
                      _buildDropdownSetting(
                        "Região do Servidor",
                        "Define a região principal do servidor para otimização de latência.",
                        _currentSettings.serverRegion,
                        _regions,
                        (value) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(serverRegion: value);
                          });
                        },
                      ),
                      _buildSliderSetting(
                        "Máx. Usuários por Clã",
                        "Define o número máximo de usuários permitidos por clã.",
                        _currentSettings.maxUsersPerClan.toDouble(),
                        10,
                        200,
                        (value) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(maxUsersPerClan: value.round());
                          });
                        },
                      ),
                      _buildSliderSetting(
                        "Máx. Clãs por Federação",
                        "Define o número máximo de clãs permitidos por federação.",
                        _currentSettings.maxClansPerFederation.toDouble(),
                        1,
                        50,
                        (value) {
                          setState(() {
                            _currentSettings = _currentSettings.copyWith(maxClansPerFederation: value.round());
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsSection(
                    "Gerenciamento de Notificações",
                    Icons.notifications_active,
                    Colors.orange,
                    [
                      _buildActionSetting(
                        "Enviar Notificação Global",
                        "Envie uma mensagem para todos os usuários do aplicativo.",
                        Icons.send,
                        Colors.orange,
                        () {
                          _showSendGlobalNotificationDialog(context);
                        },
                      ),
                      _buildActionSetting(
                        "Convidar Usuário para Clã",
                        "Envie um convite para um usuário se juntar a um clã específico.",
                        Icons.person_add,
                        Colors.orange,
                        () {
                          _showInviteUserToClanDialog(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsSection(
                    "Ferramentas do Sistema",
                    Icons.build,
                    Colors.red,
                    [
                      _buildActionSetting(
                        "Criar Backup do Sistema",
                        "Gere um backup completo de todos os dados do sistema.",
                        Icons.backup,
                        Colors.red,
                        _createBackup,
                      ),
                      _buildActionSetting(
                        "Limpar Cache do Sistema",
                        "Limpe o cache de dados temporários para otimizar o desempenho.",
                        Icons.cleaning_services,
                        Colors.red,
                        _clearCache,
                      ),
                      _buildActionSetting(
                        "Reiniciar Servidor",
                        "Reinicie o servidor principal do aplicativo. Isso desconectará todos os usuários.",
                        Icons.restart_alt,
                        Colors.red,
                        _restartServer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Salvar Configurações",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // Diálogo para enviar notificação global
  void _showSendGlobalNotificationDialog(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Enviar Notificação Global"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Título"),
              ),
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(labelText: "Corpo da Mensagem"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Enviar"),
              onPressed: () async {
                try {
                  await _notificationService.sendGlobalNotification(
                    _titleController.text,
                    _bodyController.text,
                  );
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notificação global enviada com sucesso!")),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao enviar notificação global: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Diálogo para convidar usuário para clã
  void _showInviteUserToClanDialog(BuildContext context) {
    final TextEditingController _userIdController = TextEditingController();
    final TextEditingController _clanIdController = TextEditingController(); // TODO: Substituir por Dropdown/Search

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Convidar Usuário para Clã"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: "ID do Usuário Alvo"),
              ),
              TextField(
                controller: _clanIdController,
                decoration: const InputDecoration(labelText: "ID do Clã"),
              ), // TODO: Implementar seleção de clã mais amigável
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Convidar"),
              onPressed: () async {
                // TODO: Chamar o serviço de notificação para enviar o convite de clã
                print("Convidar Usuário ${_userIdController.text} para Clã ${_clanIdController.text}");
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Convite de clã enviado (simulado).")), // Substituir por sucesso real
                );
              },
            ),
          ],
        );
      },
    );
  }
  SystemSetting _currentSettings = SystemSetting(
    maintenanceMode: false,
    registrationEnabled: true,
    serverRegion: 'Brasil',
    chatEnabled: true,
    voiceEnabled: true,
    notificationsEnabled: true,
    maxUsersPerClan: 50,
    maxClansPerFederation: 10,
  );
  bool _isLoading = false;

  final List<String> _regions = ['Brasil', 'Estados Unidos', 'Europa', 'Ásia'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final settings = await adminService.getSystemSettings();
      setState(() {
        _currentSettings = settings;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar configurações: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      await adminService.updateSystemSettings(_currentSettings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar configurações: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
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
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup iniciado...'),
                  backgroundColor: Colors.blue,
                ),
              );
              try {
                final adminService = Provider.of<AdminService>(context, listen: false);
                await adminService.createSystemBackup();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup criado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao criar backup: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Criar Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      await adminService.clearSystemCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache limpo com sucesso!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao limpar cache: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restartServer() async {
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
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Servidor será reiniciado em 30 segundos...'),
                  backgroundColor: Colors.red,
                ),
              );
              try {
                final adminService = Provider.of<AdminService>(context, listen: false);
                await adminService.restartServer();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Servidor reiniciado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao reiniciar servidor: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.red)),
          ),
        ],
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
}


