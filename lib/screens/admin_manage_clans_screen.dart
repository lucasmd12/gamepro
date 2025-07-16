import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/services/permission_service.dart';
import 'package:lucasbeatsfederacao/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucasbeatsfederacao/services/upload_service.dart';
import 'dart:io';


class AdminManageClansScreen extends StatefulWidget {
  final String? federationId; // Optional federation ID passed for directed creation

  const AdminManageClansScreen({super.key, this.federationId});

  @override
  State<AdminManageClansScreen> createState() => _AdminManageClansScreenState();
}

class _AdminManageClansScreenState extends State<AdminManageClansScreen> {
  List<Clan> _clans = [];
  List<Federation> _availableFederations = [];
  bool _isDesignatedFederationLeader = false; // Track if current user is leader of the passed federation
  String? _selectedFederationId;
  bool _isLoading = false;
  User? _currentUser;

  final TextEditingController _clanNameController = TextEditingController();
  final TextEditingController _editClanNameController = TextEditingController();
  File? _selectedImage; // Para o logo do clã
  final ImagePicker _picker = ImagePicker();

  // Adicionar referências aos serviços
  late final ClanService _clanService;
  late final FederationService _federationService;
  late final UserService _userService; // Adicionar UserService
  late final UploadService _uploadService; // Adicionar UploadService

  @override
  void initState() {
    super.initState();
    // Inicializar serviços usando Provider
    _clanService = Provider.of<ClanService>(context, listen: false);
    _federationService = Provider.of<FederationService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false); // Inicializar UserService
    _uploadService = Provider.of<UploadService>(context, listen: false); // Inicializar UploadService
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUser = authProvider.currentUser;

    if (_currentUser == null) {
      // User not logged in or not available, handle appropriately (e.g., navigate to login)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    await _loadClans();

    // Load federations only for ADM_MASTER or if a specific federationId is provided
    if (_currentUser!.role == Role.admMaster || widget.federationId != null) {
      await _loadFederations();
    }

    // Check if the user is the designated leader of the provided federation
    if (_currentUser!.role != Role.admMaster && widget.federationId != null) {
      try {
        final designatedFederation = await _federationService.getFederationDetails(widget.federationId!);

        if (designatedFederation != null) {
          _isDesignatedFederationLeader = designatedFederation.leader.id == _currentUser!.id;
        }

        // If designated leader, pre-select this federation and limit the available federations list
        if (_isDesignatedFederationLeader && designatedFederation != null) {
          if (mounted) {
            setState(() {
              _availableFederations = [designatedFederation];
              _selectedFederationId = widget.federationId;
            });
          }
        }
      } catch (e, s) {
        Logger.error("Error checking federation leader status:", error: e, stackTrace: s);
        if (mounted) {
          _showSnackBar("Failed to check federation leader status: $e", isError: true);
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClans() async {
    Logger.info("Loading clans...");
    if (!mounted) return;

    try {
      // TODO: Consider filtering clans if federationId is provided and user is not ADM_MASTER for better performance
      final clans = await _clanService.getAllClans();
      if (mounted) {
        // Filter out any potential nulls and ensure it\'s a List<Clan>
        setState(() {
          _clans = clans.whereType<Clan>().toList();
        });
      }
    } catch (e, s) {
      Logger.error("Error loading clans:", error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar("Failed to load clans: $e", isError: true);
        setState(() {
          _clans = [];
        });
      }
    }
  }

  Future<void> _loadFederations() async {
    Logger.info("Loading federations...");
    if (!mounted) return;

    try {
      final federations = await _federationService.getAllFederations();
      if (mounted) {
        setState(() {
          // Safely assign federations, filtering out any potential nulls
          _availableFederations = federations.whereType<Federation>().toList();
        });
      }
    } catch (e, s) {
      Logger.error("Error loading federations:", error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar("Failed to load federations: $e", isError: true);
        setState(() {
          _availableFederations = [];
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    isError
        ? CustomSnackbar.showError(context, message)
        : CustomSnackbar.showSuccess(context, message);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showCreateClanDialog() {
    // Reset selected federation before showing dialog unless an initial one is provided
    if (widget.federationId == null) {
      _selectedFederationId = null;
    } else {
      // If federationId is provided, make sure _selectedFederationId is set for the dropdown
      _selectedFederationId = widget.federationId;
    }
    _clanNameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext para evitar conflito
        final authProvider = Provider.of<AuthProvider>(dialogContext, listen: false);
        final currentUser = authProvider.currentUser!; // Assumindo que currentUser não é nulo aqui com base na lógica de _loadData
        final bool isAdmMaster = currentUser.role == Role.admMaster;
        // Determine if the dropdown should be disabled (for designated leaders who are not ADM_MASTER)
        final bool disableFederationSelection = _isDesignatedFederationLeader && !isAdmMaster;

        return AlertDialog(
          title: const Text("Criar Novo Clã"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _clanNameController,
                  decoration: const InputDecoration(hintText: "Nome do Clã"),
                ),
                const SizedBox(height: 16),
                // Image selection
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Selecionar Logo do Clã"),
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.file(
                      _selectedImage!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                // Show dropdown for ADM_MASTERs or if user is designated leader
                if (isAdmMaster || _isDesignatedFederationLeader)
                  DropdownButtonFormField<String?>(
                    value: _selectedFederationId,
                    decoration: const InputDecoration(
                      labelText: "Associar a Federação",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      if (isAdmMaster && !_isDesignatedFederationLeader) // Only ADM_MASTERs not designated leaders can select "Nenhuma Federação"
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text("Nenhuma Federação"),
                        ),
                      ..._availableFederations.map((federation) {
                        return DropdownMenuItem<String?>(
                          value: federation.id,
                          child: Text(federation.name),
                        );
                      }).toList(),
                    ],
                    onChanged: disableFederationSelection ? null : (val) {
                      // When user selects a federation manually (only if enabled)
                      setState(() {
                        _selectedFederationId = val;
                      });
                    },
                    // Disable the dropdown if selection is not allowed
                    isDense: true,
                    iconDisabledColor: Colors.grey,
                    autovalidateMode: AutovalidateMode.disabled,
                    // Add explicit disabled property for clarity
                    disabledHint: disableFederationSelection ? Text(_availableFederations.first.name ?? "Federação sem nome") : null,
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Criar"),
              onPressed: () async {
                final clanName = _clanNameController.text.trim();
                if (clanName.isEmpty) {
                  _showSnackBar("Clan name cannot be empty.", isError: true);
                  return;
                }

                // If designated leader, ensure a federation is selected (it should be pre-selected)
                if (_isDesignatedFederationLeader && _selectedFederationId == null) {
                  _showSnackBar("Internal Error: Designated leader must have a federation selected.", isError: true);
                  return;
                }

                Navigator.of(dialogContext).pop(); // Dismiss dialog

                try {
                  String? logoUrl;
                  if (_selectedImage != null) {
                    final uploadResult = await _uploadService.uploadMissionImage(_selectedImage!); // Reusing mission image upload for now
                    if (uploadResult["success"]) {
                      logoUrl = uploadResult["data"]["url"];
                    } else {
                      _showSnackBar("Falha ao fazer upload do logo: ${uploadResult["message"]}", isError: true);
                      return; // Stop if logo upload fails
                    }
                  }

                  final Map<String, dynamic> clanData = {
                    "name": clanName,
                    if (logoUrl != null) "logo": logoUrl,
                  };

                  // Use the selected federation ID if available (for ADM_MASTER or designated leader)
                  if (isAdmMaster || _isDesignatedFederationLeader) {
                    clanData["federationId"] = _selectedFederationId;
                  } else {
                    // This case should ideally not be reached due to FAB visibility, but as a safeguard:
                     _showSnackBar("Você não tem permissão para criar clãs.", isError: true);
                     return;
                  }

                  final newClan = await _clanService.createClan(clanData);

                  if (newClan != null) {
                    _showSnackBar("Clan \"${newClan.name}\" created successfully!");
                    _loadClans(); // Refresh the list
                    // TODO: Consider navigating back or to the new clan\"s details if created by designated leader
                  } else {
                    _showSnackBar("Failed to create clan.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Error creating clan:", error: e, stackTrace: s);
                  _showSnackBar("Failed to create clan: ${e.toString()}", isError: true); // Show detailed error
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditClanDialog(Clan clan) {
    _editClanNameController.text = clan.name; // Assuming name is never null based on model
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser; // currentUser pode ser nulo aqui antes do check de permissão
    // Permission check for editing: ADM_MASTER or the leader of THIS specific clan
    final bool canEdit = currentUser?.role == Role.admMaster || (currentUser?.id != null && currentUser?.id == clan.leaderId);

    if (!canEdit) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) { // Usar dialogContext
          return AlertDialog(
            title: const Text("Permissão Negada"),
            content: const Text("Você não tem permissão para editar este clã."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return; // Stop here if no permission
    }


    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext
        return AlertDialog(
          title: Text("Editar Clã: ${clan.name}"),
          content: TextField(
            controller: _editClanNameController,
            decoration: const InputDecoration(hintText: "Novo Nome do Clã"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Salvar"),
              onPressed: () async {
                final newName = _editClanNameController.text.trim();
                if (newName.isEmpty) {
                  _showSnackBar("Clan name cannot be empty.", isError: true);
                  return;
                }
                Navigator.of(dialogContext).pop(); // Dismiss dialog

                try {
                  final updatedClan = await _clanService.updateClanDetails(clan.id, name: newName);
                  if (updatedClan != null) {
                    _showSnackBar("Clan \"${updatedClan.name}\\\" updated successfully!");
                    _loadClans(); // Refresh the list
                  } else {
                    _showSnackBar("Failed to update clan.", isError: true);
                  }
                } catch (e, s) {
                   Logger.error("Error updating clan ${clan.id}:", error: e, stackTrace: s);
                   _showSnackBar("Failed to update clan: ${e.toString()}", isError: true); // Show detailed error
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showTransferLeadershipDialog(Clan clan) {
    final TextEditingController newLeaderUsernameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext
        return AlertDialog(
          title: Text("Transferir Liderança do Clã: ${clan.name}"),
          content: TextField(
            controller: newLeaderUsernameController,
            decoration: const InputDecoration(hintText: "Nome de usuário do novo líder"),
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
                final newLeaderUsernameOrId = newLeaderUsernameController.text.trim();
                if (newLeaderUsernameOrId.isEmpty) {
                  _showSnackBar("O nome de usuário ou ID do novo líder não pode ser vazio.", isError: true);
                  return;
                }
                Navigator.of(dialogContext).pop(); // Dismiss dialog

                try {
                  // Assumindo que o input é o ID do usuário para simplificar por agora.
                  // Se a API esperar o username, a lógica aqui precisará buscar o ID do usuário pelo username primeiro.
                  final success = await _clanService.transferClanLeadership(clan.id, newLeaderUsernameOrId);

                  if (success) {
                    _showSnackBar("Liderança do clã \"${clan.name}\\\" transferida com sucesso!");
                    // Opcional: Recarregar a lista de clãs para refletir a mudança de líder
                    _loadClans();
                  } else {
                    _showSnackBar("Failed to transfer clan leadership.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Error transferring clan leadership:", error: e, stackTrace: s);
                  _showSnackBar("Failed to transfer clan leadership: ${e.toString()}", isError: true); // Added detailed error
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteClanConfirmationDialog(Clan clan) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    // Permission check for deleting: only ADM_MASTER
    final bool canDelete = currentUser?.role == Role.admMaster;

    if (!canDelete) {
       showDialog(
        context: context,
        builder: (BuildContext dialogContext) { // Usar dialogContext
          return AlertDialog(
            title: const Text("Permissão Negada"),
            content: const Text("Você não tem permissão para excluir clãs."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return; // Stop here if no permission
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: Text("Tem certeza que deseja excluir o clã \"${clan.name}\"?"), // Assuming name is not null
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Excluir"),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss dialog

                try {
                  bool success = await _clanService.deleteClan(clan.id);

                  if (success) {
                    _showSnackBar("Clan \"${clan.name}\" deleted successfully!");
                    _loadClans(); // Refresh the list on success
                  } else {
                    _showSnackBar("Failed to delete clan.", isError: true);
                  }
                } catch (e, s) {
                   Logger.error("Error deleting clan ${clan.id}:", error: e, stackTrace: s);
                   _showSnackBar("Failed to delete clan: ${e.toString()}", isError: true); // Show detailed error
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Helper to check edit permission for a given clan
  bool _canEditClan(Clan clan) {
     if (_currentUser == null) return false;
 return PermissionService.canManageClan(_currentUser!, clan.id);
  }

  // Helper to check delete permission for a given clan (only ADM_MASTER)
   bool _canDeleteClan() {
     if (_currentUser == null) return false;
     return _currentUser!.role == Role.admMaster;
  }

  // Helper to check transfer leadership permission for a given clan (only ADM_MASTER)
   bool _canTransferLeadership() {
     if (_currentUser == null) return false;
     return _currentUser!.role == Role.admMaster;
   }

  // Helper to check declare war permission (only ADM_MASTER)
  bool _canDeclareWar() {
    if (_currentUser == null) return false;
    return _currentUser!.role == Role.admMaster;
  }

  // NOTE: _showAssignClanDialog was moved here from outside the class
  void _showAssignClanDialog(User user) {
    String? selectedClanId;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext
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
              ..._clans.map((clan) {
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
                    _showSnackBar("Clã atribuído com sucesso!");
                    _loadClans();
                  } else {
                    _showSnackBar("Falha ao atribuir clã.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Erro ao atribuir clã:", error: e, stackTrace: s);
                  _showSnackBar("Erro ao atribuir clã: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // NOTE: _showDeclareWarDialog was moved here from outside the class
  void _showDeclareWarDialog(Clan attackingClan) {
    String? targetClanId;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext
        return AlertDialog(
          title: Text("Declarar Guerra de ${attackingClan.name}"),
          content: DropdownButtonFormField<String?>(
            value: targetClanId,
            decoration: const InputDecoration(
              labelText: "Selecione o Clã Alvo",
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text("Selecione um Clã"),
              ),
              ..._clans.where((clan) => clan.id != attackingClan.id).map((clan) {
                return DropdownMenuItem<String?>(
                  value: clan.id,
                  child: Text(clan.name),
                );
              }).toList(),
            ],
            onChanged: (val) {
              targetClanId = val;
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
              child: const Text("Declarar Guerra"),
              onPressed: () async {
                if (targetClanId == null) {
                  _showSnackBar("Por favor, selecione um clã alvo.", isError: true);
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  final clanWar = await _clanService.declareWar(attackingClan.id, targetClanId!);
                  if (clanWar != null) {
                    _showSnackBar("Guerra declarada com sucesso!");
                    // Opcional: Atualizar a lista de guerras ou navegar para a tela de guerras
                  } else {
                    _showSnackBar("Falha ao declarar guerra.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Erro ao declarar guerra:", error: e, stackTrace: s);
                  _showSnackBar("Erro ao declarar guerra: ${e.toString()}", isError: true);
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
    // Ensure currentUser is available for conditional rendering
    if (_currentUser == null && !_isLoading) {
      // Or show a loading indicator or redirect
      return Scaffold(
        appBar: AppBar(title: const Text("Gerenciar Clãs")),
        body: const Center(child: Text("Por favor, faça login para gerenciar clãs.")), // More informative message
      );
    }

    // Determine if the user can create clans (ADM_MASTER or designated federation leader)
    final bool canCreateClans = _currentUser?.role == Role.admMaster || _isDesignatedFederationLeader;


    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Clãs"),
      ),
      body: _isLoading && _clans.isEmpty // Show loading only initially or when refreshing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _clans.isEmpty
              ? const Center(
                  child: Text("Nenhum clã encontrado."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _clans.length,
                  itemBuilder: (context, index) {
                    final clan = _clans[index];
                    final clanName = clan.name; // Assuming name is not null

                    // Check specific permissions for the current clan in the list
                    final bool canTransferLeadership = _canTransferLeadership();
                    final bool canEditThisClan = _canEditClan(clan);
                    final bool canDeleteAnyClan = _canDeleteClan(); // Delete is global for ADM_MASTER

                    return ListTile(
                      title: Text(clanName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           if (canTransferLeadership) // Conditionally show transfer leadership button
                             IconButton(
                                icon: const Icon(Icons.transfer_within_a_station),
                                onPressed: () {
                                  _showTransferLeadershipDialog(clan);
                                },
                                tooltip: "Transferir Liderança",
                             ),
                           if (canEditThisClan) // Conditionally show edit button
                             IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditClanDialog(clan);
                                },
                                tooltip: "Editar Clã",
                             ),
                           if (canDeleteAnyClan) // Conditionally show delete button
                             IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _showDeleteClanConfirmationDialog(clan);
                                },
                                tooltip: "Excluir Clã",
                             ),
                           if (_canDeclareWar()) // Conditionally show declare war button
                             IconButton(
                                icon: const Icon(Icons.gavel),
                                onPressed: () {
                                  _showDeclareWarDialog(clan);
                                },
                                tooltip: "Declarar Guerra",
                             ),
                            // If no actions are allowed for this clan, hide the row
                            if (!canEditThisClan && !canDeleteAnyClan && !canTransferLeadership && !_canDeclareWar())
                              const SizedBox.shrink(), // Hide the row if no actions
                        ],
                      ),
                    );
                  },
                ),
      // Show FAB for ADM_MASTERs OR for Federation Leaders when navigating from their federation detail
      floatingActionButton: canCreateClans
          ? FloatingActionButton(
              onPressed: _showCreateClanDialog,
              tooltip: "Criar Novo Clã",
              child: const Icon(Icons.add),
            )
          : null, // Hide FAB for other users
    );
  }

  @override
  void dispose() {
    _clanNameController.dispose();
    _editClanNameController.dispose();
    super.dispose();
  }
}
