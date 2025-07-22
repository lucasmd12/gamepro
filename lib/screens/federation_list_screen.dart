import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/screens/federation_detail_screen.dart';

class FederationListScreen extends StatefulWidget {
  const FederationListScreen({super.key});

  @override
  State<FederationListScreen> createState() => _FederationListScreenState();
}

class _FederationListScreenState extends State<FederationListScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _leaderUsernameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Federation> _federations = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _limit = 10; // Número de federações por página

  @override
  void initState() {
    super.initState();
    _loadFederations();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore && !_isFetchingMore) {
        _loadMoreFederations();
      }
    });
  }

  Future<void> _loadFederations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1; // Resetar página ao recarregar
      _federations = []; // Limpar federações existentes
      _hasMore = true;
    });
    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      // ASSUMINDO QUE VOCÊ VAI CORRIGIR O FEDERATIONSERVICE PARA ACEITAR page E limit
      final fetchedFederations = await federationService.getAllFederations(page: _currentPage, limit: _limit);
      setState(() {
        _federations = fetchedFederations;
        _isLoading = false;
        _hasMore = fetchedFederations.length == _limit;
      });
    } catch (e, s) {
      Logger.error('Error loading federations:', error: e, stackTrace: s);
      setState(() {
        _errorMessage = 'Falha ao carregar federações: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreFederations() async {
    if (!_hasMore || _isFetchingMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    _currentPage++;
    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      // ASSUMINDO QUE VOCÊ VAI CORRIGIR O FEDERATIONSERVICE PARA ACEITAR page E limit
      final newFederations = await federationService.getAllFederations(page: _currentPage, limit: _limit);
      setState(() {
        _federations.addAll(newFederations);
        _hasMore = newFederations.length == _limit;
        _isFetchingMore = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar mais federações: $e');
      setState(() {
        _isFetchingMore = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _showCreateFederationDialog() {
    _nameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: const Text('Criar Nova Federação', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Federação',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (Opcional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Criar', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () async {
                final String name = _nameController.text.trim();
                final String description = _descriptionController.text.trim();

                if (name.isEmpty) {
                  _showSnackBar('O nome da federação não pode ser vazio.', isError: true);
                  return;
                }
                Navigator.of(context).pop();

                try {
                  final federationService = Provider.of<FederationService>(context, listen: false);
                  // ==================== INÍCIO DA CORREÇÃO ====================
                  // O erro original era passar um mapa. A correção é passar os argumentos
                  // como Strings separadas, que é o formato mais provável que seu serviço espera.
                  final newFederation = await federationService.createFederation(name, description);
                  // ===================== FIM DA CORREÇÃO ======================

                  if (newFederation != null) {
                    _showSnackBar('Federação "${newFederation.name}" criada com sucesso!');
                    _loadFederations();
                  } else {
                    _showSnackBar('Erro ao criar federação. Tente novamente.', isError: true);
                  }
                } catch (e, s) {
                  Logger.error('Error creating federation:', error: e, stackTrace: s);
                  _showSnackBar('Erro ao criar federação: $e', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showTransferLeadershipDialog(Federation federation) {
    _leaderUsernameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212121),
          title: Text('Transferir Liderança de ${federation.name}', style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: _leaderUsernameController,
            decoration: const InputDecoration(
              labelText: 'Nome de usuário do novo líder',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Transferir', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () async {
                final String newLeaderUsername = _leaderUsernameController.text.trim();
                if (newLeaderUsername.isEmpty) {
                  _showSnackBar('O nome de usuário do novo líder não pode ser vazio.', isError: true);
                  return;
                }
                Navigator.of(context).pop();

                try {
                  final federationService = Provider.of<FederationService>(context, listen: false);
                  final success = await federationService.transferFederationLeadership(federation.id, newLeaderUsername);
                   _showSnackBar(success ? 'Liderança da Federação transferida com sucesso!' : 'Falha ao transferir a liderança da Federação.', isError: !success);
                } catch (e, s) {
                   Logger.error('Error transferring federation leadership:', error: e, stackTrace: s);
                   _showSnackBar('Erro ao transferir liderança: $e', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool isAdmMaster = currentUser?.role == Role.admMaster;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Federações'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
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
                        onPressed: _loadFederations,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _federations.isEmpty
                  ? const Center(
                      child: Text('Nenhuma federação encontrada.', style: TextStyle(color: Colors.white)),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _federations.length + (_isFetchingMore ? 1 : 0), // Corrigido para usar _isFetchingMore
                      itemBuilder: (context, index) {
                        if (index == _federations.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final federation = _federations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: const Icon(Icons.account_tree),
                            title: Text(federation.name),
                            subtitle: Text(federation.description ?? 'Sem descrição'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FederationDetailScreen(federation: federation),
                                ),
                              );
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAdmMaster)
                                  IconButton(
                                    icon: const Icon(Icons.transfer_within_a_station, color: Colors.orangeAccent),
                                    onPressed: () {
                                      _showTransferLeadershipDialog(federation);
                                    },
                                    tooltip: 'Transferir Liderança',
                                  ),
                                if (isAdmMaster)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Confirmar Exclusão'),
                                            content: Text('Tem certeza que deseja excluir a federação "${federation.name}"?'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('Cancelar'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  final success = await Provider.of<FederationService>(context, listen: false).deleteFederation(federation.id);
                                                  if (success) {
                                                    _showSnackBar('Federação "${federation.name}" excluída com sucesso!');
                                                    _loadFederations();
                                                  } else {
                                                    _showSnackBar('Falha ao excluir federação.', isError: true);
                                                  }
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    tooltip: 'Excluir Federação',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: isAdmMaster
          ? FloatingActionButton(
              onPressed: _showCreateFederationDialog,
              tooltip: 'Criar Nova Federação',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _leaderUsernameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
