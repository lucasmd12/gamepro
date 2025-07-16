import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/widgets/admin_notification_dialog.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_clans_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_users_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_wars_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_federations_screen.dart';

class AdminDashboard extends StatelessWidget {
  final User currentUser;

  const AdminDashboard({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boas-vindas
          Card(
            color: Colors.grey.shade800.withValues(alpha: 0.8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.red,
                    child: Text(
                      currentUser.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-vindo, ${currentUser.username}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Administrador da FEDERACAO MADOUT',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Estatísticas principais
          Row(
            children: [
              Expanded(child: _buildStatCard('Federações', '3', Icons.group_work, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Clãs', '15', Icons.groups, Colors.orange)),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildStatCard('Usuários', '247', Icons.people, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Online', '89', Icons.circle, Colors.green)),
            ],
          ),

          const SizedBox(height: 20),

          // Ações rápidas
          const Text(
            'Ações Rápidas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildActionCard(
                'Notificação Global',
                Icons.notifications_active,
                Colors.red,
                () => _sendGlobalNotification(context),
              ),
              _buildActionCard(
                'Criar Federação',
                Icons.add_circle,
                Colors.purple,
                () => _createFederation(context),
              ),
              _buildActionCard(
                'Promover Usuário',
                Icons.person_add,
                Colors.green,
                () => _promoteUser(context),
              ),
              _buildActionCard(
                'Gerenciar Clãs',
                Icons.settings,
                Colors.orange,
                () => _manageClans(context),
              ),
              _buildActionCard(
                'Gerenciar Guerras',
                Icons.gavel,
                Colors.redAccent,
                () => _manageWars(context),
              ),
              _buildActionCard(
                'Relatórios',
                Icons.analytics,
                Colors.blue,
                () => _viewReports(context),
              ),
              _buildActionCard(
                'Estatísticas',
                Icons.bar_chart,
                Colors.teal,
                () => _viewStats(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Atividades recentes
          Card(
            color: Colors.grey.shade800.withValues(alpha: 0.8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Atividades Recentes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActivityItem(
                    'Novo usuário registrado: player123',
                    '2 min atrás',
                    Icons.person_add,
                    Colors.green,
                  ),
                  _buildActivityItem(
                    'Clã "Warriors" criado por líder456',
                    '15 min atrás',
                    Icons.group_add,
                    Colors.blue,
                  ),
                  _buildActivityItem(
                    'Federação "Elite" atualizada',
                    '1 hora atrás',
                    Icons.update,
                    Colors.orange,
                  ),
                  _buildActivityItem(
                    'Usuário banido por violação de regras',
                    '2 horas atrás',
                    Icons.block,
                    Colors.red,
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
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      color: Colors.grey.shade800.withValues(alpha: 0.8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendGlobalNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AdminNotificationDialog(),
    );
  }

  void _createFederation(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminManageFederationsScreen()));
  }

  void _promoteUser(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminManageUsersScreen()));
  }

  void _manageClans(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminManageClansScreen()));
  }

  void _viewReports(BuildContext context) {
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

  void _viewStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estatísticas'),
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
}



  void _manageWars(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminManageWarsScreen()));
  }


