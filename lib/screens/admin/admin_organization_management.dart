import 'package:flutter/material.dart';
import 'package:provider/provider';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class AdminOrganizationManagementScreen extends StatefulWidget {
  const AdminOrganizationManagementScreen({super.key});

  @override
  State<AdminOrganizationManagementScreen> createState() => _AdminOrganizationManagementScreenState();
}

class _AdminOrganizationManagementScreenState extends State<AdminOrganizationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _organizations = []; // Pode conter Clan ou Federation
  List<dynamic> _filteredOrganizations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final federationService = Provider.of<FederationService>(context, listen: false);

      final List<Clan> clans = await clanService.getAllClans();
      final List<Federation> federations = await federationService.getAllFederations();

      setState(() {
        _organizations = [...clans, ...federations];
        _filteredOrganizations = List.from(_organizations);
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar organizações: $e');
      setState(() {
        _errorMessage = 'Falha ao carregar organizações: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterOrganizations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOrganizations = List.from(_organizations);
      } else {
        _filteredOrganizations = _organizations.where((org) {
          final name = org is Clan ? org.name : (org as Federation).name;
          final tag = org is Clan ? org.tag : (org as Federation).tag; // Federação pode não ter tag
          final leader = org is Clan ? org.leader?.username : (org as Federation).leader?.username; // Assumindo que leader é um objeto User

          return name.toLowerCase().contains(query.toLowerCase()) ||
                 (tag?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (leader?.toLowerCase().contains(query.toLowerCase()) ?? false);
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
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadOrganizations,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _filteredOrganizations.isEmpty
                        ? const Center(
                            child: Text('Nenhuma organização encontrada.',
                                style: TextStyle(color: Colors.white)),
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
          // Criar nova organização (clã ou federação)
          _showCreateOrganizationDialog();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOrganizationCard(dynamic organization) {
    final bool isClan = organization is Clan;
    final String name = isClan ? organization.name : organization.name;
    final String? tag = isClan ? organization.tag : organization.tag; // Federação pode não ter tag
    final String? leaderName = isClan ? organization.leader?.username : organization.leader?.username;
    final int memberCount = isClan ? organization.members.length : organization.clans.length; // Membros para clã, clãs para federação
    final bool isActive = true; // Assumindo que todas as organizações carregadas estão ativas

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
                  color: _getTypeColor(isClan ? 'clan' : 'federation'),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(isClan ? 'clan' : 'federation'),
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
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tag != null && tag.isNotEmpty)
                          const SizedBox(width: 8),
                        if (tag != null && tag.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(isClan ? 'clan' : 'federation'),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '[$tag]',
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
                    if (leaderName != null)
                      Text(
                        'Líder: $leaderName',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      isClan ? '$memberCount membros' : '$memberCount clãs',
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
                _buildStatItem(isClan ? 'Membros' : 'Clãs', '$memberCount', Icons.people),
                _buildStatItem('Criado', _formatDate(isClan ? organization.createdAt : organization.createdAt), Icons.calendar_today),
                _buildStatItem('Tipo', isClan ? 'CLÃ' : 'FEDERAÇÃO', _getTypeIcon(isClan ? 'clan' : 'federation')),
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
              if (isClan) // Ação específica para Clãs
                _buildActionButton(
                  'Associar à Federação',
                  Icons.link,
                  Colors.indigo,
                  () => _showAssociateToFederationDialog(organization as Clan),
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
    return Expanded(
      child: ElevatedButton.icon(
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

  void _editOrganization(dynamic organization) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando organização: ${organization is Clan ? organization.name : (organization as Federation).name}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _toggleOrganizationStatus(dynamic organization) {
    // Implementar lógica de ativação/desativação via API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alternando status de organização: ${organization is Clan ? organization.name : (organization as Federation).name}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteOrganization(dynamic organization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
        content: Text(
          'Tem certeza que deseja excluir a organização ${organization is Clan ? organization.name : (organization as Federation).name}? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (organization is Clan) {
                  await Provider.of<ClanService>(context, listen: false).deleteClan(organization.id);
                } else if (organization is Federation) {
                  await Provider.of<FederationService>(context, listen: false).deleteFederation(organization.id);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Organização ${organization is Clan ? organization.name : (organization as Federation).name} excluída com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadOrganizations(); // Recarrega a lista
              } catch (e) {
                Logger.error('Erro ao excluir organização: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Falha ao excluir organização: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateOrganizationDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController tagController = TextEditingController();
    String? selectedType = 'clan'; // Default to clan

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Criar Nova Organização', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Tag (apenas para Clã)',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                  enabled: selectedType == 'clan', // Only enabled for clan
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'clan', child: Text('Clã')),
                    DropdownMenuItem(value: 'federation', child: Text('Federação')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (selectedType == 'clan') {
                  await Provider.of<ClanService>(context, listen: false).createClan(nameController.text, tagController.text);
                } else if (selectedType == 'federation') {
                  await Provider.of<FederationService>(context, listen: false).createFederation(nameController.text);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${selectedType == 'clan' ? 'Clã' : 'Federação'} criada com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadOrganizations(); // Recarrega a lista
              } catch (e) {
                Logger.error('Erro ao criar organização: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Falha ao criar organização: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Criar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showAssociateToFederationDialog(Clan clan) {
    Federation? selectedFederation;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text('Associar ${clan.name} à Federação', style: const TextStyle(color: Colors.white)),
        content: FutureBuilder<List<Federation>>(
          future: Provider.of<FederationService>(context, listen: false).getAllFederations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Erro ao carregar federações: ${snapshot.error}', style: const TextStyle(color: Colors.red));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Nenhuma federação disponível.', style: TextStyle(color: Colors.white));
            }
            return DropdownButtonFormField<Federation>(
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Selecionar Federação',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
              value: selectedFederation,
              onChanged: (Federation? newValue) {
                selectedFederation = newValue;
              },
              items: snapshot.data!.map<DropdownMenuItem<Federation>>((Federation federation) {
                return DropdownMenuItem<Federation>(
                  value: federation,
                  child: Text(federation.name),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (selectedFederation != null) {
                try {
                  await Provider.of<FederationService>(context, listen: false).addClanToFederation(selectedFederation!.id, clan.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Clã ${clan.name} associado à federação ${selectedFederation!.name} com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadOrganizations(); // Recarrega a lista
                } catch (e) {
                  Logger.error('Erro ao associar clã à federação: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Falha ao associar clã: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, selecione uma federação.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Associar', style: TextStyle(color: Colors.blue)),
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


