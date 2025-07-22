import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_user_management.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_organization_management.dart';
import 'package:lucasbeatsfederacao/screens/clan_management_screen.dart';
import 'package:lucasbeatsfederacao/screens/federation_list_screen.dart';

class QuickActionsWidget extends StatelessWidget {
  final Role userRole;
  final String? clanId;

  const QuickActionsWidget({
    super.key,
    required this.userRole,
    this.clanId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade800.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 12),
            _buildActionsForRole(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsForRole(BuildContext context) {
    switch (userRole) {
      case Role.admMaster:
        return _buildAdminActions(context);
      case Role.clanLeader:
        return _buildLeaderActions(context);
      case Role.clanSubLeader:
        return _buildSubLeaderActions(context);
      case Role.clanMember:
        return _buildMemberActions(context);
      case Role.guest:
        return _buildGuestActions(context);
      case Role.user:
        return _buildUserActions(context);
      default:
        return _buildGuestActions(context);
    }
  }

  Widget _buildAdminActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          context,
          'Criar Federação',
          Icons.group_work,
          Colors.purple,
          () => _showCreateFederationDialog(context),
        ),
        _buildActionButton(
          context,
          'Gerenciar Federações',
          Icons.account_tree,
          Colors.blueGrey,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FederationListScreen())),
        ),
        _buildActionButton(
          context,
          'Gerenciar Clãs',
          Icons.groups,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminOrganizationManagementScreen()),
          ),
        ),
        _buildActionButton(
          context,
          'Promover Usuário',
          Icons.person_add,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminUserManagementScreen())),
        ),
        _buildActionButton(
          context,
          'Fazer Chamada',
          Icons.call,
          Colors.green, () => _showCallDialog(context),),
      ],
    );
  }

  Widget _buildLeaderActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          context,
          'Gerenciar Clã',
          Icons.settings,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClanManagementScreen(clanId: clanId!)),
          ),
        ),
        _buildActionButton(
          context,
          'Adicionar Membro',
          Icons.person_add,
          Colors.green,
          () => _showAddMemberDialog(context),
        ),
        _buildActionButton(
          context,
          'Criar Canal',
          Icons.add_circle,
          Colors.blue,
          () => _showCreateChannelDialog(context),
        ),
        _buildActionButton(
          context,
          'Configurar Clã',
          Icons.tune,
          Colors.purple,
          () => _showClanSettingsDialog(context),
        ),
      ],
    );
  }

  Widget _buildSubLeaderActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          context,
          'Gerenciar Membros',
          Icons.people,
          Colors.blue,
          () => _showManageMembersDialog(context),
        ),
        _buildActionButton(
          context,
          'Moderar Chat',
          Icons.chat,
          Colors.green,
          () => _showModerateChatDialog(context),
        ),
        _buildActionButton(
          context,
          'Ver Relatórios',
          Icons.analytics,
          Colors.purple,
          () => _showReportsDialog(context),
        ),
      ],
    );
  }

  Widget _buildMemberActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          context,
          'Fazer Chamada',
          Icons.call,
          Colors.green,
          () => _showCallDialog(context),
        ),
        _buildActionButton(
          context,
          'Entrar em Canal',
          Icons.headset,
          Colors.blue,
          () => _showJoinChannelDialog(context),
        ),
        _buildActionButton(
          context,
          'Ver Missões',
          Icons.assignment,
          Colors.green,
          () => _showMissionsDialog(context),
        ),
        _buildActionButton(
          context,
          'Perfil do Clã',
          Icons.info,
          Colors.purple,
          () => _showClanProfileDialog(context),
        ),
      ],
    );
  }

  Widget _buildGuestActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          context,
          'Solicitar Entrada',
          Icons.login,
          Colors.blue,
          () => _showRequestJoinDialog(context),
        ),
        _buildActionButton(
          context,
          'Explorar Clãs',
          Icons.explore,
          Colors.green,
          () => _showExploreClansDialog(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _showCreateFederationDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Nova Federação'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome da Federação'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome da federação';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: tagController,
                  decoration: const InputDecoration(labelText: 'Tag da Federação (Opcional)'),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Criar'),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final federationService = Provider.of<FederationService>(context, listen: false);
                
                // ==================== INÍCIO DA CORREÇÃO ====================
                // Passando o nome e a descrição (do controller da tag) como dois argumentos separados.
                final newFederation = await federationService.createFederation(
                  nameController.text,
                  tagController.text.isNotEmpty ? tagController.text : null,
                );
                // ===================== FIM DA CORREÇÃO ======================

                Navigator.of(context).pop();

                if (newFederation != null) {
                  CustomSnackbar.showSuccess(context, 'Federação "${newFederation.name}" criada com sucesso!');
                } else {
                  CustomSnackbar.showError(context, 'Falha ao criar federação.');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPromoteUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promover Usuário'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Membro'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateChannelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Canal'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClanSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações do Clã'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManageMembersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerenciar Membros'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showModerateChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderar Chat'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatórios'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showJoinChannelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrar em Canal'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Missões'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClanProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil do Clã'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRequestJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Entrada'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExploreClansDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Explorar Clãs'),
        content: const Text('Funcionalidade em desenvolvimento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(BuildContext context) {
    Navigator.pushNamed(context, '/call-contacts');
  }

  Widget _buildUserActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          context,
          'Fazer Chamada',
          Icons.call,
          Colors.green,
          () => _showCallDialog(context),
        ),
        _buildActionButton(
          context,
          'Ver Missões',
          Icons.assignment,
          Colors.green,
          () => _showMissionsDialog(context),
        ),
      ],
    );
  }
}
