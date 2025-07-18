import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
import '../call_history_page.dart';
import '../profile_screen.dart';
import '../privacy_screen.dart';
import '../notification_settings_screen.dart';
import '../about_page.dart';
import '../login_screen.dart';

class SettingsTab extends StatelessWidget {
  final String clanId; // Adicionado clanId

  const SettingsTab({super.key, required this.clanId}); // Construtor atualizado

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Seção VoIP
          _buildSection(
            context,
            'VoIP',
            [
              _buildSettingItem(
                context,
                icon: Icons.history,
                title: 'Histórico de Chamadas',
                subtitle: 'Ver chamadas realizadas e recebidas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CallHistoryPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Seção Conta
          _buildSection(
            context,
            'Conta',
            [
              _buildSettingItem(
                context,
                icon: Icons.person,
                title: 'Perfil',
                subtitle: 'Editar informações do perfil',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.security,
                title: 'Privacidade',
                subtitle: 'Configurações de privacidade',
                onTap: () {
                  Navigator.push(
 context,
 MaterialPageRoute(builder: (context) => const PrivacyScreen()),
 );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Seção App
          _buildSection(
            context,
            'Aplicativo',
            [
              _buildSettingItem(
                context,
                icon: Icons.notifications,
                title: 'Notificações',
                subtitle: 'Configurar notificações',
                onTap: () {
                  Navigator.push(
 context,
 MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
 );
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.info,
                title: 'Sobre',
                subtitle: 'Informações do aplicativo',
                onTap: () {Navigator.push(
 context,
 MaterialPageRoute(builder: (context) => const AboutPage()),
 );
                },
              ),
            ],
          ),
          
          const Spacer(),
          
          // Botão de logout
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  Logger.info("Attempting logout via AuthService...");
                  await authService.logout();
                  // Navigate to the login screen and remove all previous routes
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()), // Replace LoginScreen() with your actual authentication screen widget
                      (Route<dynamic> route) => false,
                    );
                  }
                  Logger.info("Logout successful via AuthService.");
                } catch (e) {
                  Logger.error("Error during logout", error: e);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}

