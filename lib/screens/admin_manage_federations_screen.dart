import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_clans_screen.dart'; // Para gerenciar clãs dentro da federação

class AdminManageFederationsScreen extends StatefulWidget {
  const AdminManageFederationsScreen({super.key});

  @override
  State<AdminManageFederationsScreen> createState() => _AdminManageFederationsScreenState();
}

class _AdminManageFederationsScreenState extends State<AdminManageFederationsScreen> {
  List<Federation> _federations = [];
  bool _isLoading = false;

  final TextEditingController _federationNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFederations();
  }

  Future<void> _loadFederations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      final fetchedFederations = await federationService.getAllFederations();
      if (mounted) {
        setState(() {
          _federations = fetchedFederations;
        });
      }
    } catch (e, s) {
      Logger.error('Error loading federations:', error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar('Erro ao carregar federações: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    _federationNameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Nova Federação'),
          content: TextField(
            controller: _federationNameController,
            decoration: const InputDecoration(hintText: 'Nome da Federação'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Criar'),
              onPressed: () async {
                final federationName = _federationNameController.text.trim();
                if (federationName.isEmpty) {
                  _showSnackBar('O nome da federação não pode ser vazio.', isError: true);
                  return;
                }
                Navigator.of(context).pop();
                try {
                  final federationService = Provider.of<FederationService>(context, listen: false);
                  final newFederation = await federationService.createFederation({'name': federationName});
                  if (newFederation != null) {
                    _showSnackBar('Federação "${newFederation.name}" criada com sucesso!');
                    _loadFederations();
                  } else {
                    _showSnackBar('Falha ao criar federação.', isError: true);
                  }
                } catch (e, s) {
                  Logger.error('Error creating federation:', error: e, stackTrace: s);
                  _showSnackBar('Erro ao criar federação: ${e.toString()}', isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFederationConfirmationDialog(Federation federation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir a federação "${federation.name}"? Todos os clãs associados a ela serão desvinculados.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final federationService = Provider.of<FederationService>(context, listen: false);
                  bool success = await federationService.deleteFederation(federation.id);
                  if (success) {
                    _showSnackBar('Federação "${federation.name}" excluída com sucesso!');
                    _loadFederations();
                  } else {
                    _showSnackBar('Falha ao excluir federação.', isError: true);
                  }
                } catch (e, s) {
                  Logger.error('Error deleting federation:', error: e, stackTrace: s);
                  _showSnackBar('Erro ao excluir federação: ${e.toString()}', isError: true);
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

    if (currentUser == null || currentUser.role != Role.admMaster) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gerenciar Federações')),
        body: const Center(child: Text('Acesso negado. Apenas ADM_MASTER pode gerenciar federações.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Federações'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _federations.isEmpty
              ? const Center(child: Text('Nenhuma federação encontrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _federations.length,
                  itemBuilder: (context, index) {
                    final federation = _federations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionTile(
                        title: Text(federation.name),
                        subtitle: Text(
                            'Líder: ${federation.leader.username ?? 'N/A'} | Clãs: ${federation.clans.length}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${federation.id}'),
                                Text('Sub-líderes: ${federation.subLeaders.map((s) => s.username).join(', ')}'),
                                Text('Aliados: ${federation.allies.map((a) => a.name).join(', ')}'),
                                Text('Inimigos: ${federation.enemies.map((e) => e.name).join(', ')}'),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Navegar para a tela de gerenciamento de clãs, filtrando por esta federação
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AdminManageClansScreen(federationId: federation.id),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.groups),
                                      label: const Text('Gerenciar Clãs da Federação'),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _showDeleteFederationConfirmationDialog(federation),
                                      tooltip: 'Excluir Federação',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFederationDialog,
        tooltip: 'Criar Nova Federação',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _federationNameController.dispose();
    super.dispose();
  }
}


