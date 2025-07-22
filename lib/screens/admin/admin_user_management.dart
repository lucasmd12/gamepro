import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/user_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Para RoleExtension

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _limit = 20; // Número de usuários por página

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore && !_isFetchingMore) {
        _loadMoreUsers();
      }
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1; // Resetar página ao recarregar
      _users = []; // Limpar usuários existentes
      _filteredUsers = [];
      _hasMore = true;
    });
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final fetchedUsers = await userService.getAllUsers(page: _currentPage, limit: _limit);
      setState(() {
        _users = fetchedUsers;
        _filteredUsers = List.from(_users);
        _isLoading = false;
        _hasMore = fetchedUsers.length == _limit; // Se o número de usuários for menor que o limite, não há mais páginas
      });
    } catch (e) {
      Logger.error('Erro ao carregar usuários: $e');
      setState(() {
        _errorMessage = 'Falha ao carregar usuários: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (!_hasMore || _isFetchingMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    _currentPage++;
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final newUsers = await userService.getAllUsers(page: _currentPage, limit: _limit);
      setState(() {
        _users.addAll(newUsers);
        _filteredUsers = List.from(_users.where((user) => user.username.toLowerCase().contains(_searchController.text.toLowerCase()) || (user.clanName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)));
        _hasMore = newUsers.length == _limit;
        _isFetchingMore = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar mais usuários: $e');
      setState(() {
        _isFetchingMore = false;
        // Não setar _errorMessage aqui para não sobrescrever o erro principal, se houver
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          return user.username.toLowerCase().contains(query.toLowerCase()) ||
                 (user.clanName?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
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
              'Conteúdo da Gestão de Usuários ADM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar usuários...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              onChanged: _filterUsers,
            ),
          ),

          const SizedBox(height: 16),

          // Lista de usuários
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? const Center(
                            child: Text('Nenhum usuário encontrado.',
                                style: TextStyle(color: Colors.white)),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredUsers.length + (_hasMore ? 1 : 0), // Adiciona 1 para o indicador de carregamento
                            itemBuilder: (context, index) {
                              if (index == _filteredUsers.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(child: CircularProgressIndicator(color: Colors.blue)),
                                );
                              }
                              final user = _filteredUsers[index];
                              return _buildUserCard(user);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Adicionar novo usuário
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final isOnline = user.isOnline ?? false; // Assumindo que User tem isOnline
    final role = user.role; // Já é um enum Role
    final clanName = user.clanName;
    final clanTag = user.clanTag;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar do usuário
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getRoleColor(role),
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Informações do usuário
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (clanName != null && clanTag != null)
                      Text(
                        'Clã: $clanName [$clanTag]',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Badge do role
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(role),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role.displayName, // Usando a extensão displayName
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Ações do usuário
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                text: 'Editar',
                icon: Icons.edit,
                color: Colors.blue,
                onPressed: () => _editUser(user),
              ),
              _buildActionButton(
                text: 'Banir',
                icon: Icons.block,
                color: Colors.red,
                onPressed: () => _banUser(user),
              ),
              _buildActionButton(
                text: 'Promover',
                icon: Icons.arrow_upward,
                color: Colors.green,
                onPressed: () => _promoteUser(user),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
      case Role.user:
        return Colors.green;
      case Role.idcloned:
        return Colors.purple; // Cor para o ADM Master idcloned
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(Role role) {
    return role.displayName; // Usando a extensão displayName
  }

  void _editUser(User user) {
    // Implementar edição de usuário
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando usuário: ${user.username}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _banUser(User user) {
    // Implementar banimento de usuário
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Confirmar Banimento', style: TextStyle(color: Colors.white)),
        content: Text(
          'Tem certeza que deseja banir o usuário ${user.username}?',
          style: const TextStyle(color: Colors.white),
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
                SnackBar(
                  content: Text('Usuário ${user.username} foi banido'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Banir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _promoteUser(User user) {
    // Implementar promoção de usuário
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Promovendo usuário: ${user.username}"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}


