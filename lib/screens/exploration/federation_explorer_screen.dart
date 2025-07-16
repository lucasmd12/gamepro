import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';

class FederationExplorerScreen extends StatefulWidget {
  const FederationExplorerScreen({super.key});

  @override
  State<FederationExplorerScreen> createState() => _FederationExplorerScreenState();
}

class _FederationExplorerScreenState extends State<FederationExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Federation> _federations = [];
  List<Federation> _filteredFederations = [];
  bool _isLoading = true;

  late FederationService _federationService;

  @override
  void initState() {
    super.initState();
    _federationService = Provider.of<FederationService>(context, listen: false);
    _loadFederations();
  }

  Future<void> _loadFederations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedFederations = await _federationService.getAllFederations();
      if (mounted) {
        setState(() {
          _federations = fetchedFederations;
          _filteredFederations = List.from(_federations);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar federações: $e")),
        );
      }
    }
  }

  void _filterFederations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFederations = List.from(_federations);
      } else {
        _filteredFederations = _federations.where((federation) {
          return federation.name.toLowerCase().contains(query.toLowerCase()) ||
                 (federation.tag?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (federation.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
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
              'Conteúdo da Tela de Exploração de Federações',
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
                hintText: 'Pesquisar federações...',
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
              onChanged: _filterFederations,
            ),
          ),

          const SizedBox(height: 16),

          // Lista de federações
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _filteredFederations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma federação encontrada',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredFederations.length,
                        itemBuilder: (context, index) {
                          final federation = _filteredFederations[index];
                          return _buildFederationCard(federation);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFederationCard(Federation federation) {
    final bannerColor = Colors.blue;
    final clanCountDisplay = federation.clanCount ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        // CORREÇÃO: 'withOpacity' substituído por 'withAlpha'.
        border: Border.all(color: bannerColor.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        children: [
          // Banner da federação
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // CORREÇÃO: 'withOpacity' substituído por 'withAlpha'.
                colors: [bannerColor, bannerColor.withAlpha((0.7 * 255).round())],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                // Logo da federação (placeholder)
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      // CORREÇÃO: 'withOpacity' substituído por 'withAlpha'.
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_tree,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                
                // Tag da federação
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      // CORREÇÃO: 'withOpacity' substituído por 'withAlpha'.
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '[${federation.tag ?? ''}]',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Status público/privado
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: federation.isPublic == true ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      federation.isPublic == true ? 'Público' : 'Privado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo da federação
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome da federação
                Text(
                  federation.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Descrição
                Text(
                  federation.description ?? 'Sem descrição.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Estatísticas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Clãs', '$clanCountDisplay', Icons.groups),
                    _buildStatColumn("Membros", "${federation.clans.length}", Icons.people),
                    _buildStatColumn("Rank", "#${federation.id.substring(0, 4)}", Icons.star),
                  ],
                ),

                const SizedBox(height: 16),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewFederation(federation),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Ver Detalhes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: federation.isPublic == true ? () => _joinFederation(federation) : null,
                        icon: Icon(
                          federation.isPublic == true ? Icons.add : Icons.lock,
                          size: 16,
                        ),
                        label: Text(federation.isPublic == true ? 'Solicitar' : 'Privado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: federation.isPublic == true ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
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
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _viewFederation(Federation federation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text(
          federation.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tag: [${federation.tag ?? ''}]',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              federation.description ?? 'Sem descrição.',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Estatísticas:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '• ${federation.clanCount ?? 0} clãs',
              style: TextStyle(color: Colors.grey[300]),
            ),
            Text(
              '• ${federation.isPublic == true ? 'Federação pública' : 'Federação privada'}',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _joinFederation(Federation federation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text("Solicitar Entrada", style: TextStyle(color: Colors.white)),
        content: Text(
          "Deseja solicitar entrada na federação ${federation.name}?",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Solicitação enviada para ${federation.name}"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Solicitar"),
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
