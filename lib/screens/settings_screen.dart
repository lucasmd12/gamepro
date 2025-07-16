import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucasbeatsfederacao/screens/login_screen.dart';
import 'package:lucasbeatsfederacao/screens/media/profile_picture_manager.dart';
import 'package:lucasbeatsfederacao/screens/admin_panel_screen.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Seção de Perfil Aprimorada
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfilePictureManagerScreen(),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50.0),
                      child: CachedNetworkImage(
                        imageUrl: currentUser.avatar ?? '',
                        placeholder: (context, url) => const Icon(Icons.person, size: 100),
                        errorWidget: (context, url, error) => const Icon(Icons.person, size: 100),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.username ?? 'Usuário',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Cargo: ${currentUser.role.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  // Afiliações Organizacionais
                  if (currentUser.federationName != null) 
                    Text(
                      'Federação: ${currentUser.federationName} ${currentUser.federationTag != null ? '(${currentUser.federationTag})' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (currentUser.clanName != null) 
                    Text(
                      'Clã: ${currentUser.clanName} ${currentUser.clanTag != null ? '(${currentUser.clanTag})' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),

          // Acesso ao Painel ADM (se aplicável)
          if (currentUser.role == Role.admMaster) 
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Acessar Painel Administrativo'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
                    ),
                  );
                },
              ),
            ),

          // Configurações de Notificações (Placeholder)
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: ExpansionTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificações'),
              children: const [
                ListTile(title: Text('Configurações de notificação aqui.')),
              ],
            ),
          ),

          // Configurações de Privacidade (Placeholder)
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: ExpansionTile(
              leading: const Icon(Icons.lock),
              title: const Text('Privacidade e Segurança'),
              children: const [
                ListTile(title: Text('Configurações de privacidade aqui.')),
              ],
            ),
          ),

          // Seção de Conta
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await Provider.of<AuthProvider>(context, listen: false).logout();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Excluir Conta', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    // Implementar lógica de exclusão de conta
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Excluir Conta'),
                          content: const Text('Tem certeza que deseja excluir sua conta? Esta ação é irreversível.'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text('Excluir'),
                              onPressed: () {
                                // Lógica para excluir a conta
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Funcionalidade de exclusão de conta a ser implementada.')),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


