import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart'; // Importar Federation
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFederations();
    });
  }

  Future<void> _loadFederations() async {
    Logger.info('Loading federations...');
    if (!mounted) return;

    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      await federationService.getAllFederations(); // getAllFederations should update the state internally
      Logger.info('Federations loaded.');
    } catch (e, s) {
      Logger.error('Error loading federations:', error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar('Failed to load federations: $e', isError: true);
      }
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
                Navigator.of(context).pop(); // Dismiss dialog

                try {
                  final federationService = Provider.of<FederationService>(context, listen: false);
                  final newFederation = await federationService.createFederation({"name": name, "description": description});

                  if (newFederation != null) {
                    await federationService.getAllFederations(); // Refresh the list after creation
                    _showSnackBar('Federação "${newFederation.name}" criada com sucesso!');
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
          title: Text('Transferir Liderança de ${federation.name}', style: TextStyle(color: Colors.white)),
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
                Navigator.of(context).pop(); // Dismiss dialog

                try {
                  final federationService = Provider.of<FederationService>(context, listen: false);
                  final success = await federationService.transferFederationLeadership(federation.id, newLeaderUsername);
                   _showSnackBar(success ? 'Liderança da Federação transferida com sucesso!' : 'Falha ao transferir a liderança da Federação.', isError: !success);
                } catch (e, s) {
                   Logger.error('Error transferring federation leadership:', error: e, stackTrace: s);
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
    final bool isAdmMaster = currentUser?.role == Role.admMaster; // Alterado para ADM_MASTER

    return Scaffold(
      appBar: AppBar(
        title: const Text('Federações'),
      ),
      body: Consumer<FederationService>(
        builder: (context, federationService, child) {
          if (federationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (federationService.federations.isEmpty) {
            return const Center(child: Text('Nenhuma federação encontrada.'));
          }

          return ListView.builder(
            itemCount: federationService.federations.length,
            itemBuilder: (context, index) {
              final federation = federationService.federations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.account_tree),
                  title: Text(federation.name ?? 'Federação sem nome'),
                  subtitle: Text(federation.tag ?? 'Sem tag'),
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
                       // Botão de Transferir Liderança visível apenas para ADM_MASTER
                      if (isAdmMaster)
                        IconButton(
                          icon: const Icon(Icons.transfer_within_a_station, color: Colors.orangeAccent), // Ícone de transferência
                          onPressed: () {
                            _showTransferLeadershipDialog(federation);
                          },
                          tooltip: 'Transferir Liderança',
                        ),
                      // Botão de exclusão visível apenas para ADM_MASTER
                      if (isAdmMaster)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent), // Ícone de lixeira
                          onPressed: () {
                            // Diálogo de confirmação antes de excluir
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirmar Exclusão'),
                                  content: Text('Tem certeza que deseja excluir a federação "${federation.name ?? 'esta federação'}"?'),
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
                                        Navigator.of(context).pop(); // Fechar diálogo
                                        final success = await federationService.deleteFederation(federation.id);
                                        if (success) {
                                          _showSnackBar('Federação "${federation.name ?? 'excluída'}" excluída com sucesso!');
                                          _loadFederations(); // Recarregar a lista
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
          );
        },
      ),
      floatingActionButton: isAdmMaster // Show FAB only for ADM_MASTER
          ? FloatingActionButton(
              onPressed: _showCreateFederationDialog,
              tooltip: 'Criar Nova Federação',
              child: const Icon(Icons.add),
            )
          : null, // Hide FAB for non-ADM_MASTER
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _leaderUsernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

