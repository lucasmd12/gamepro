import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/user_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Importar Role


class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  List<User> _users = [];
  List<Clan> _clans = []; // Para o dropdown de atribuição de clã
  List<Federation> _availableFederations = []; // Para o dropdown de atribuição de federação
  bool _isLoading = false;

  // Adicionar referências aos serviços
  late final UserService _userService;
  late final ClanService _clanService;
  late final FederationService _federationService;

  @override
  void initState() {
    super.initState();
    // Inicializar serviços usando Provider
    _userService = Provider.of<UserService>(context, listen: false);
    _clanService = Provider.of<ClanService>(context, listen: false);
    _federationService = Provider.of<FederationService>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUsers();
    await _loadClans(); // Carregar clãs para o dropdown
    await _loadFederations(); // Carregar federações para o dropdown
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final fetchedUsers = await _userService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = fetchedUsers;
        });
      }
    } catch (e, s) {
      Logger.error("Error loading users:", error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar(
 "Erro ao carregar usuários: $e", isError: true);

      }
    }
  }

  Future<void> _loadClans() async {
    try {
      final fetchedClans = await _clanService.getAllClans();
      if (mounted) {
        setState(() {
          _clans = fetchedClans;
        });
      }
    } catch (e, s) {
      Logger.error("Error loading clans for assignment:", error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar(
 "Erro ao carregar clãs para atribuição: $e", isError: true);

      }
    }
  }

  Future<void> _loadFederations() async {
    try {
      final fetchedFederations = await _federationService.getAllFederations();
      if (mounted) {
        setState(() {
          _availableFederations = fetchedFederations;
        });
      }
    } catch (e, s) {
      Logger.error("Error loading federations for assignment:", error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar(
 "Erro ao carregar federações para atribuição: $e", isError: true);

      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
      );
    }
  }


  void _showAssignClanDialog(BuildContext context, User user, List<Clan> clans, void Function(String, {bool isError}) showSnackBar) {
    String? selectedClanId = user.clanId; // Corrected: Use user.clanId
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext para evitar conflito
        return AlertDialog(
          title: Text("Atribuir Clã para ${user.username}"),
          content: DropdownButtonFormField<String?>(
            value: selectedClanId,
            decoration: const InputDecoration(
              labelText: "Selecione um Clã",
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text("Nenhum Clã"),
              ),
              ...clans.map((clan) {
                return DropdownMenuItem<String?>(
                  value: clan.id,
                  child: Text(clan.name),
                );
              }).toList(),
            ],
            onChanged: (val) {
              selectedClanId = val;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Atribuir"),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final success = await _userService.assignClanToUser(user.id, selectedClanId);
                  if (success) {
                    showSnackBar("Clã atribuído com sucesso!");
                    _loadUsers(); // Recarrega a lista de usuários para refletir a mudança
                  } else {
                    showSnackBar("Falha ao atribuir clã.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Erro ao atribuir clã:", error: e, stackTrace: s);
                  showSnackBar("Erro ao atribuir clã: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showTransferClanLeadershipDialog(BuildContext context, User user, List<Clan> clans, void Function(String, {bool isError}) showSnackBar) {
    String? selectedClanId;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext
        return AlertDialog(
          title: Text("Transferir Liderança de Clã para ${user.username}"),
          content: DropdownButtonFormField<String?>(
            value: selectedClanId,
            decoration: const InputDecoration(
              labelText: "Selecione o Clã",
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text("Selecione um Clã"),
              ),
              ...clans.map((clan) {
                return DropdownMenuItem<String?>(
                  value: clan.id,
                  child: Text(clan.name),
                );
              }).toList(),
            ],
            onChanged: (val) {
              selectedClanId = val;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Transferir"),
              onPressed: () async {
                if (selectedClanId == null) {
                  showSnackBar("Por favor, selecione um clã.", isError: true); // Corrected: Use showSnackBar
 return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  final success = await _clanService.transferClanLeadership(selectedClanId!, user.id);
                  if (success) {
                    showSnackBar("Liderança do clã transferida com sucesso!");
                    _loadUsers();
                  } else {
                    showSnackBar("Falha ao transferir liderança do clã.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Erro ao transferir liderança do clã:", error: e, stackTrace: s);
                  showSnackBar("Erro ao transferir liderança do clã: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showTransferFederationLeadershipDialog(BuildContext context, User user, List<Federation> federations, void Function(String, {bool isError}) showSnackBar) {
    String? selectedFederationId;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext
        return AlertDialog(
          title: Text("Transferir Liderança de Federação para ${user.username}"),
          content: DropdownButtonFormField<String?>(
            value: selectedFederationId,
            decoration: const InputDecoration(
              labelText: "Selecione a Federação",
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text("Nenhuma Federação"),
              ),
              ...federations.map((federation) {
                return DropdownMenuItem<String?>(
                  value: federation.id,
                  child: Text(federation.name),
                );
              }).toList(),
            ],
            onChanged: (val) {
              selectedFederationId = val;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Transferir"),
              onPressed: () async {
                if (selectedFederationId == null) {
                   showSnackBar("Por favor, selecione uma federação.", isError: true); // Corrected: Use showSnackBar
 return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  final success = await _federationService.transferFederationLeadership(selectedFederationId!, user.id);
                  if (success) {
                    showSnackBar("Liderança da federação transferida com sucesso!");
                    _loadUsers();
                  } else {
                    showSnackBar("Falha ao transferir liderança da federação.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Erro ao transferir liderança da federação:", error: e, stackTrace: s);
                  showSnackBar("Erro ao transferir liderança da federação: ${e.toString()}", isError: true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Nenhum usuário encontrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      title: Text(user.username),
                      subtitle: Text('Cargo: ${user.role.displayName} | Clã: ${user.clanName ?? 'Nenhum'}'), // Corrected: Use displayName and clanName
                      trailing: Row( // Added Row to contain multiple IconButtons
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.group_add),
                            onPressed: () => _showAssignClanDialog(context, user, _clans, _showSnackBar),
                            tooltip: 'Atribuir Clã',
                          ),
                          IconButton(
                            icon: const Icon(Icons.star),
                            onPressed: () => _showTransferClanLeadershipDialog(context, user, _clans, _showSnackBar), // Corrected: Pass arguments
                            tooltip: 'Transferir Liderança de Clã',
                          ),
                          IconButton(
                            icon: const Icon(Icons.shield),
                            onPressed: () => _showTransferFederationLeadershipDialog(context, user, _availableFederations, _showSnackBar), // Corrected: Pass arguments
                            tooltip: 'Transferir Liderança de Federação', // This line seems correct, no change needed based on the instruction
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
