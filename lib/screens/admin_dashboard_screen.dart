import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAdmin) {
      // Redireciona para uma tela de acesso negado ou home
      Logger.warning("Access Denied: User is not an ADM trying to access AdminDashboardScreen.");
      // Consider using Navigator.pushReplacementNamed('/access-denied') if you have a dedicated route
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso Negado')),
        body: const Center(child: Text('Você não tem permissão para acessar esta página.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do ADM Master'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: <Widget>[
            _buildAdminCard(
              context,
              icon: Icons.people,
              title: 'Gerenciar Usuários',
              onTap: () {
                Logger.info("Navigating to AdminManageUsersScreen.");
                Navigator.of(context).pushNamed('/admin-manage-users');
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.group,
              title: 'Gerenciar Clãs',
              onTap: () {
                Logger.info("Navigating to AdminManageClansScreen.");
                Navigator.of(context).pushNamed("/admin-manage-clans");
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.account_tree,
              title: 'Gerenciar Federações',
              onTap: () {
                Logger.info("Navigating to AdminManageFederationsScreen.");
                Navigator.of(context).pushNamed("/admin-manage-federations");
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.add_circle,
              title: 'Criar Federação',
              onTap: () {
                Logger.info("Opening Create Federation dialog/screen.");
                Navigator.of(context).pushNamed("/create-federation");
              },
            ),
            _buildAdminCard(
              context,
              icon: Icons.add_circle_outline,
              title: 'Criar Clã',
              onTap: () {
                Logger.info("Opening Create Clan dialog/screen.");
                Navigator.of(context).pushNamed("/create-clan");
              },
            ),
            // Adicione mais cartões conforme necessário para outras funcionalidades de ADM
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50.0, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 10.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


