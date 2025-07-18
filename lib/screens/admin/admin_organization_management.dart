import 'package:flutter/material.dart';

class AdminOrganizationManagementScreen extends StatefulWidget {
  const AdminOrganizationManagementScreen({super.key});

  @override
  State<AdminOrganizationManagementScreen> createState() => _AdminOrganizationManagementScreenState();
}

class _AdminOrganizationManagementScreenState extends State<AdminOrganizationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _organizations = [];
  List<Map<String, dynamic>> _filteredOrganizations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  void _loadOrganizations() {
    // Simulando carregamento de organizações
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _organizations = [
            {
              'id': '1',
              'name': 'POCASIDEIA',
              'tag': 'PCD',
              'type': 'clan',
              'memberCount': 25,
              'isActive': true,
              'createdAt': DateTime.now().subtract(const Duration(days: 30)),
              'leader': 'lucasg',
            },
            {
              'id': '2',
              'name': 'FEDERACAO MADOUT',
              'tag': 'FMAD',
              'type': 'federation',
              'memberCount': 156,
              'isActive': true,
              'createdAt': DateTime.now().subtract(const Duration(days: 90)),
              'leader': 'admin',
            },
            {
              'id': '3',
              'name': 'WARRIORS',
              'tag': 'WAR',
              'type': 'clan',
              'memberCount': 18,
              'isActive': false,
              'createdAt': DateTime.now().subtract(const Duration(days: 15)),
              'leader': 'warrior_leader',
            },
          ];
          _filteredOrganizations = List.from(_organizations);
          _isLoading = false;
        });
      }
    });
  }

  void _filterOrganizations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrganizations = List.from(_organizations);
      } else {
        _filteredOrganizations = _organizations.where((org) {
          return org['name'].toLowerCase().contains(query.toLowerCase()) ||
                 org['tag'].toLowerCase().contains(query.toLowerCase()) ||
                 org['leader'].toLowerCase().contains(query.toLowerCase());
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
              'Conteúdo da Gestão de Organizações ADM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),

          // Filtros e pesquisa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar organizações...',
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
                    onChanged: _filterOrganizations,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Filtros avançados
                    },
                    icon: Icon(Icons.filter_list, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de organizações
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredOrganizations.length,
                    itemBuilder: (context, index) {
                      final organization = _filteredOrganizations[index];
                      return _buildOrganizationCard(organization);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Criar nova organização
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOrganizationCard(Map<String, dynamic> organization) {
    final isActive = organization['isActive'] ?? false;
    final type = organization['type'] ?? 'clan';
    final memberCount = organization['memberCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Ícone da organização
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(type),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Informações da organização
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          organization['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor(type),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '[${organization['tag']}]',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Líder: ${organization['leader']}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$memberCount membros',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Ativo' : 'Inativo',
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

          // Estatísticas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Membros', '$memberCount', Icons.people),
                _buildStatItem('Criado', _formatDate(organization['createdAt']), Icons.calendar_today),
                _buildStatItem('Tipo', type.toUpperCase(), _getTypeIcon(type)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Ações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'Editar',
                Icons.edit,
                Colors.blue,
                () => _editOrganization(organization),
              ),
              _buildActionButton(
                isActive ? 'Desativar' : 'Ativar',
                isActive ? Icons.pause : Icons.play_arrow,
                isActive ? Colors.orange : Colors.green,
                () => _toggleOrganizationStatus(organization),
              ),
              _buildActionButton(
                'Excluir',
                Icons.delete,
                Colors.red,
                () => _deleteOrganization(organization),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(80, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'federation':
        return Colors.purple;
      case 'clan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'federation':
        return Icons.account_tree;
      case 'clan':
        return Icons.groups;
      default:
        return Icons.group;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Hoje';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}sem';
    } else {
      return '${(difference.inDays / 30).floor()}m';
    }
  }

  void _editOrganization(Map<String, dynamic> organization) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando organização: ${organization['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _toggleOrganizationStatus(Map<String, dynamic> organization) {
    final isActive = organization['isActive'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isActive ? 'Desativando' : 'Ativando'} organização: ${organization['name']}'),
        backgroundColor: isActive ? Colors.orange : Colors.green,
      ),
    );
  }

  void _deleteOrganization(Map<String, dynamic> organization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
        content: Text(
          'Tem certeza que deseja excluir a organização ${organization['name']}? Esta ação não pode ser desfeita.',
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
                  content: Text('Organização ${organization['name']} foi excluída'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

