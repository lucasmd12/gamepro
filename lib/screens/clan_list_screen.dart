import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/screens/clan_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';

class ClanListScreen extends StatefulWidget {
  final String? federationId; // Tornar opcional para ADM_MASTER

  const ClanListScreen({super.key, this.federationId});

  @override
  State<ClanListScreen> createState() => _ClanListScreenState();
}

class _ClanListScreenState extends State<ClanListScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Clan> _clans = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _limit = 10; // Número de clãs por página

  @override
  void initState() {
    super.initState();
    _loadClans();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore && !_isFetchingMore) {
        _loadMoreClans();
      }
    });
  }

  Future<void> _loadClans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1; // Resetar página ao recarregar
      _clans = []; // Limpar clãs existentes
      _hasMore = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final clanService = Provider.of<ClanService>(context, listen: false);

    try {
      List<Clan> fetchedClans;
      if (currentUser != null && currentUser.role == Role.admMaster) {
        Logger.info('ADM_MASTER user detected in ClanListScreen, fetching all clans.');
        fetchedClans = await clanService.getAllClans(page: _currentPage, limit: _limit);
      } else if (widget.federationId != null) {
        Logger.info('Non-ADM_MASTER user detected in ClanListScreen, fetching clans by federation.');
        fetchedClans = await clanService.fetchClansByFederation(widget.federationId!, page: _currentPage, limit: _limit);
      } else {
        Logger.warning('No federationId provided for non-ADM_MASTER user in ClanListScreen.');
        fetchedClans = [];
      }

      setState(() {
        _clans = fetchedClans;
        _isLoading = false;
        _hasMore = fetchedClans.length == _limit;
      });
    } catch (e, s) {
      Logger.error('Error loading clans:', error: e, stackTrace: s);
      setState(() {
        _errorMessage = 'Falha ao carregar clãs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreClans() async {
    if (!_hasMore || _isFetchingMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    _currentPage++;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final clanService = Provider.of<ClanService>(context, listen: false);

    try {
      List<Clan> newClans;
      if (currentUser != null && currentUser.role == Role.admMaster) {
        newClans = await clanService.getAllClans(page: _currentPage, limit: _limit);
      } else if (widget.federationId != null) {
        newClans = await clanService.fetchClansByFederation(widget.federationId!, page: _currentPage, limit: _limit);
      } else {
        newClans = [];
      }

      setState(() {
        _clans.addAll(newClans);
        _hasMore = newClans.length == _limit;
        _isFetchingMore = false;
      });
    } catch (e) {
      Logger.error('Erro ao carregar mais clãs: $e');
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

  void _showCreateClanDialog() {
    nameController.clear();
    tagController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Novo Clã'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome do Clã'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(labelText: 'Tag do Clã (Opcional)'),
              ),
            ],
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
                final String name = nameController.text.trim();
                final String tag = tagController.text.trim();

                if (name.isEmpty) {
                  _showSnackBar('O nome do clã não pode ser vazio.', isError: true);
                  return;
                }

                final clanService = Provider.of<ClanService>(context, listen: false);

                try {
                  final dynamic newClan = await clanService.createClan(name, tag.isNotEmpty ? tag : null);

                  if (mounted) {
                    if (newClan != null && newClan is Clan) {
                      _loadClans(); // Recarregar clãs após a criação
                      _showSnackBar('Clã "${newClan.name}" criado com sucesso!');
                      Navigator.of(context).pop();
                    } else {
                       _showSnackBar('Erro ao criar clã. Tente novamente mais tarde.', isError: true);
                    }
                  }
                } catch (e) {
                  Logger.error("Erro ao criar clã:", error: e);
                  _showSnackBar('Erro ao criar clã: ${e.toString()}', isError: true);
                } finally {
                   Navigator.of(context).pop();
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

    // Apenas ADM_MASTER pode criar clãs diretamente nesta tela
    final bool canCreateClan = currentUser != null && currentUser.role == Role.admMaster;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clãs'), // Título mais genérico
        actions: [
          if (canCreateClan)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Logger.info('Botão Adicionar Clã pressionado por ADM_MASTER.');
                _showCreateClanDialog();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadClans,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _clans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Nenhum clã encontrado.', style: TextStyle(color: Colors.white)),
                          if (canCreateClan)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: ElevatedButton.icon(
                                onPressed: _showCreateClanDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Criar Novo Clã'),
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _clans.length + (_hasMore ? 1 : 0), // Adiciona 1 para o indicador de carregamento
                      itemBuilder: (context, index) {
                        if (index == _clans.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final clan = _clans[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: clan.flag != null && clan.flag!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: clan.flag!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.shield),
                                  )
                                : const Icon(Icons.shield),
                            title: Text(clan.name ?? 'Clã sem nome'), // Adicionado null-check
                            subtitle: Text('Tag Clã: ${clan.tag ?? 'N/A'}'), // Usar 'N/A' se a tag for nula
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ClanDetailScreen(clan: clan),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    tagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}


