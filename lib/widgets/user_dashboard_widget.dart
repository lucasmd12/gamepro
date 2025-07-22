import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart'; // Importar ApiService
import 'package:lucasbeatsfederacao/services/auth_service.dart'; // Importar AuthService
import 'package:provider/provider.dart'; // Importar Provider
import 'package:http/http.dart' as http;
import 'dart:convert';
// CORREÇÃO: Adicionado o import do AuthProvider, caso seja necessário em outro lugar.
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';


class UserDashboardWidget extends StatelessWidget {
  final User user;

  const UserDashboardWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade800.withAlpha((0.8 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getRoleColor(user.role),
                  backgroundImage: user.avatar != null && Uri.tryParse(user.avatar!)?.hasAbsolutePath == true
                    ? NetworkImage(user.avatar!)
                    : null,
                  child: user.avatar == null
                    ? Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRoleDisplayName(user.role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (user.federationTag != null && user.federationTag!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tag: ${user.federationTag}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusIndicator(user.isOnline),
              ],
            ),
            const SizedBox(height: 16),
            _buildUserStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isOnline) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildUserStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserStats(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || !snapshot.hasData) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Tempo Online', '0h 0m'),
                _buildStatColumn('Mensagens', '0'),
                _buildStatColumn('Chamadas', '0'),
              ],
            );
          }
          
          final stats = snapshot.data!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Tempo Online', stats['onlineTime'] ?? '0h 0m'),
              _buildStatColumn('Mensagens', '${stats['totalMessages'] ?? 0}'),
              _buildStatColumn('Chamadas', '${stats['totalCalls'] ?? 0}'),
            ],
          );
        },
      ),
    );
  }

  // ==================== INÍCIO DA CORREÇÃO ====================
  Future<Map<String, dynamic>> _fetchUserStats(BuildContext context) async {
    try {
      // Acessando o AuthService diretamente, que é a fonte da verdade para autenticação.
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // O ApiService e o token devem ser acessados a partir do AuthService.
      final apiService = authService.apiService;
      final token = authService.token;

      // Se não houver token, não há como fazer a requisição.
      if (token == null) return {};

      final response = await http.get(
        Uri.parse('${apiService.baseUrl}/api/stats/user/${user.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // Silently fail and return empty stats
    }
    return {};
  }
  // ===================== FIM DA CORREÇÃO ======================

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.admMaster:
        return Colors.red;
      case Role.clanLeader:
        return Colors.orange;
      case Role.clanSubLeader:
        return Colors.yellow.shade700;
      case Role.clanMember:
        return Colors.blue;
      case Role.guest:
        return Colors.grey;
      case Role.user:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(Role role) {
    switch (role) {
      case Role.admMaster:
        return 'ADM MASTER';
      case Role.user:
        return 'USUÁRIO';
      default:
        // Mantive a sua lógica original aqui
        return role.toString().split('.').last.toUpperCase();
    }
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
