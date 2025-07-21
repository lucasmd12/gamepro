import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_main_dashboard.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_user_management.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_organization_management.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_reports_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin/admin_system_settings.dart';
import 'package:lucasbeatsfederacao/screens/home_screen.dart'; // Import da HomeScreen

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _adminScreens = <Widget>[
    AdminMainDashboard(),
    AdminUserManagementScreen(),
    AdminOrganizationManagementScreen(),
    AdminReportsScreen(),
    AdminSystemSettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        // O botão de voltar será tratado automaticamente pelo Navigator
      ),
      body: _adminScreens[_selectedIndex],
      // 👇 BOTÃO ADICIONADO PARA NAVEGAR PARA A EXPERIÊNCIA COMUM
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navega para a HomeScreen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
        icon: const Icon(Icons.explore),
        label: const Text('Modo Usuário'),
        tooltip: 'Navegar pelo aplicativo como usuário',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuários',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree),
            label: 'Organizações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Relatórios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Sistema',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).primaryColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
