import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/services/invite_service.dart';
import 'package:lucasbeatsfederacao/services/user_service.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart'; // Import ApiService
import 'package:lucasbeatsfederacao/models/clan_model.dart'; // Import Clan model
import 'package:lucasbeatsfederacao/models/member_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart'; // Import SocketService
import 'package:lucasbeatsfederacao/widgets/member_list_item.dart';
import 'dart:async'; // Import for StreamSubscription

class MembersTab extends StatefulWidget {
  final String clanId;

  final Clan clan; // Adicionado
  const MembersTab({super.key, required this.clanId, required this.clan}); // clan agora é required

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inviteUsernameController = TextEditingController();
  late SocketService _socketService; // SocketService instance
  late StreamSubscription _userOnlineSubscription;
  late StreamSubscription _userOfflineSubscription;

  @override
  void initState() {
    super.initState();
    // Obtain SocketService instance via Provider
    _socketService = Provider.of<SocketService>(context, listen: false);
    _loadMembers();
    _searchController.addListener(_filterMembers);
    _setupSocketListeners(); // Setup socket listeners
  }

  void _setupSocketListeners() {
    _userOnlineSubscription = _socketService.userOnlineStream.listen((userId) {
      _updateMemberOnlineStatus(userId, true);
    });

    _userOfflineSubscription = _socketService.userOfflineStream.listen((userId) {
      _updateMemberOnlineStatus(userId, false);
    });
  }

  @override
  void dispose() {
    // Cancel subscriptions in dispose
    _userOnlineSubscription.cancel();
    _userOfflineSubscription.cancel();
    _searchController.dispose();
    _inviteUsernameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final clanService = Provider.of<ClanService>(context, listen: false);

      final members = await clanService.getClanMembers(widget.clanId);

      if (mounted) {
        setState(() {
          _members = members;
          _filteredMembers = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar membros', error: e);
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar membros: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _updateMemberOnlineStatus(String userId, bool isOnline) {
    // Find the member in the list and update their online status
    final index = _members.indexWhere((member) => member.id == userId);
    if (index != -1) {
      setState(() {
        // Create a new Member instance with updated online status
        _members[index] = Member(
          id: _members[index].id,
          username: _members[index].username,
          avatarUrl: _members[index].avatarUrl, // Include the existing avatarUrl
          role: _members[index].role, // Keep the original role
          isOnline: isOnline, // Update online status
        );
        // Also update filtered members if the member is in the filtered list
        _filterMembers(); // Re-filter the list to update UI
      });
    }
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _members.where((member) {
        return member.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convidar Novo Membro'),
        content: TextField(
          controller: _inviteUsernameController,
          decoration: const InputDecoration(
            labelText: 'Nome de Usuário do Membro',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _sendInvite,
            child: const Text('Enviar Convite'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvite() async {
    Navigator.pop(context); // Fechar o diálogo
    final username = _inviteUsernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, insira um nome de usuário.")),
      );
      return;
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final userService = UserService(apiService);
      final user = await userService.getUserByUsername(username);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuário com este nome de usuário não encontrado.")),
        );
        return;
      }

      // ✅✅✅ CORREÇÃO APLICADA AQUI ✅✅✅
      // Agora estamos passando o 'apiService' para o construtor do 'InviteService'.
      final inviteService = InviteService(apiService);
      await inviteService.createInvite(user.id, 'clan', widget.clanId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convite enviado com sucesso!')),
      );
      _inviteUsernameController.clear();
    } catch (e) {
      Logger.error('Erro ao enviar convite', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar convite: ${e.toString()}')),
      );
    }
  }

  void _handleMemberAction(Member member, String action) {
    switch (action) {
      case 'promote':
        _promoteMember(member);
        break;
      case 'demote':
        _demoteMember(member);
        break;
      case 'remove':
        _removeMember(member);
        break;
      case 'message':
        _sendMessage(member);
        break;
    }
  }

  void _promoteMember(Member member) async {
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      await clanService.promoteMember(member.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membro ${member.username} promovido com sucesso!')),
      );
      _loadMembers();
    } catch (e) {
      Logger.error('Erro ao promover membro', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao promover membro: ${e.toString()}')),
      );
    }
  }

  void _demoteMember(Member member) async {
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      await clanService.demoteMember(member.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membro ${member.username} rebaixado com sucesso!')),
      );
      _loadMembers();
    } catch (e) {
      Logger.error('Erro ao rebaixar membro', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao rebaixar membro: ${e.toString()}')),
      );
    }
  }

  void _removeMember(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Membro'),
        content: Text('Tem certeza que deseja remover ${member.username} do clã?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final clanService = Provider.of<ClanService>(context, listen: false);
                await clanService.removeMember(member.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Membro ${member.username} removido com sucesso!')),
                );
                _loadMembers();
              } catch (e) {
                Logger.error('Erro ao remover membro', error: e);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao remover membro: ${e.toString()}')),
                );
              }
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(Member member) {
    // Implementar envio de mensagem
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enviar mensagem para ${member.username} - Em desenvolvimento')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentUser;

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadMembers();
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        final bool canManageMembers = currentUser?.clanRole == Role.leader || currentUser?.clanRole == Role.subLeader || currentUser?.role == Role.admMaster;

        return Column(
          children: [
            // Cabeçalho com busca e botão de convite
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Membros do Clã (${_members.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (canManageMembers) // Mostrar botão de convite apenas para quem pode gerenciar
                        ElevatedButton.icon(
                          onPressed: _showInviteDialog,
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Convidar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar membros...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade800.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Estatísticas rápidas
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Online',
                    '${_members.where((m) => m.isOnline).length}',
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Líderes',
                    '${_members.where((m) => m.role == Role.leader || m.role == Role.subLeader).length}',
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'Membros',
                    '${_members.where((m) => m.role == Role.clanMember).length}',
                    Colors.blue, // Assuming Role.member represents the general clan member
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lista de membros
            Expanded(
              child: _filteredMembers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Nenhum membro encontrado'
                                : 'Nenhum membro corresponde à busca',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          return MemberListItem(
                            member: member,
                            currentUser: currentUser!,
                            onMemberAction: _handleMemberAction,
                            canManage: canManageMembers,
                            clanFlagUrl: widget.clan.flag, // Passa a URL da bandeira do clã
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
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
