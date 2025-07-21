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
  
  // Adicionando uma instância do PermissionService que será usada na tela
  late final PermissionService _permissionService;

  @override
  void initState() {
    super.initState();
    // Inicializar serviços usando Provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _clanService = Provider.of<ClanService>(context, listen: false);
    _federationService = Provider.of<FederationService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
    _uploadService = Provider.of<UploadService>(context, listen: false);
    
    // Inicializa o PermissionService com o AuthProvider
    _permissionService = PermissionService(authProvider: authProvider);
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUser = authProvider.currentUser;

    if (_currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    await _loadClans();

    if (_currentUser!.role == Role.admMaster || widget.federationId != null) {
      await _loadFederations();
    }

    if (_currentUser!.role != Role.admMaster && widget.federationId != null) {
      try {
        final designatedFederation = await _federationService.getFederationDetails(widget.federationId!);

        if (designatedFederation != null) {
          _isDesignatedFederationLeader = designatedFederation.leader.id == _currentUser!.id;
        }

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
      final clans = await _clanService.getAllClans();
      if (mounted) {
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
    if (widget.federationId == null) {
      _selectedFederationId = null;
    } else {
      _selectedFederationId = widget.federationId;
    }
    _clanNameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final authProvider = Provider.of<AuthProvider>(dialogContext, listen: false);
        final currentUser = authProvider.currentUser!;
        final bool isAdmMaster = currentUser.role == Role.admMaster;
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
                if (isAdmMaster || _isDesignatedFederationLeader)
                  DropdownButtonFormField<String?>(
                    value: _selectedFederationId,
                    decoration: const InputDecoration(
                      labelText: "Associar a Federação",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      if (isAdmMaster && !_isDesignatedFederationLeader)
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
                      setState(() {
                        _selectedFederationId = val;
                      });
                    },
                    isDense: true,
                    iconDisabledColor: Colors.grey,
                    autovalidateMode: AutovalidateMode.disabled,
                    disabledHint: disableFederationSelection ? Text(_availableFederations.first.name) : null,
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

                if (_isDesignatedFederationLeader && _selectedFederationId == null) {
                  _showSnackBar("Internal Error: Designated leader must have a federation selected.", isError: true);
                  return;
                }

                Navigator.of(dialogContext).pop();

                try {
                  String? logoUrl;
                  if (_selectedImage != null) {
                    final uploadResult = await _uploadService.uploadMissionImage(_selectedImage!);
                    if (uploadResult["success"]) {
                      logoUrl = uploadResult["data"]["url"];
                    } else {
                      _showSnackBar("Falha ao fazer upload do logo: ${uploadResult["message"]}", isError: true);
                      return;
                    }
                  }

                  final Map<String, dynamic> clanData = {
                    "name": clanName,
                    if (logoUrl != null) "logo": logoUrl,
                  };

                  if (isAdmMaster || _isDesignatedFederationLeader) {
                    clanData["federationId"] = _selectedFederationId;
                  } else {
                     _showSnackBar("Você não tem permissão para criar clãs.", isError: true);
                     return;
                  }

                  final newClan = await _clanService.createClan(clanData);

                  if (newClan != null) {
                    _showSnackBar("Clan \"${newClan.name}\" created successfully!");
                    _loadClans();
                  } else {
                    _showSnackBar("Failed to create clan.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Error creating clan:", error: e, stackTrace: s);
                  _showSnackBar("Failed to create clan: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditClanDialog(Clan clan) {
    _editClanNameController.text = clan.name;
    
    // A verificação de permissão agora usa o método centralizado _canEditClan
    if (!_canEditClan(clan)) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
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
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                Navigator.of(dialogContext).pop();

                try {
                  final updatedClan = await _clanService.updateClanDetails(clan.id, name: newName);
                  if (updatedClan != null) {
                    _showSnackBar("Clan \"${updatedClan.name}\" updated successfully!");
                    _loadClans();
                  } else {
                    _showSnackBar("Failed to update clan.", isError: true);
                  }
                } catch (e, s) {
                   Logger.error("Error updating clan ${clan.id}:", error: e, stackTrace: s);
                   _showSnackBar("Failed to update clan: ${e.toString()}", isError: true);
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
      builder: (BuildContext dialogContext) {
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
                Navigator.of(dialogContext).pop();

                try {
                  final success = await _clanService.transferClanLeadership(clan.id, newLeaderUsernameOrId);

                  if (success) {
                    _showSnackBar("Liderança do clã \"${clan.name}\" transferida com sucesso!");
                    _loadClans();
                  } else {
                    _showSnackBar("Failed to transfer clan leadership.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Error transferring clan leadership:", error: e, stackTrace: s);
                  _showSnackBar("Failed to transfer clan leadership: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteClanConfirmationDialog(Clan clan) {
    if (!_canDeleteClan()) {
       showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
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
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: Text("Tem certeza que deseja excluir o clã \"${clan.name}\"?"),
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
                Navigator.of(dialogContext).pop();

                try {
                  bool success = await _clanService.deleteClan(clan.id);

                  if (success) {
                    _showSnackBar("Clan \"${clan.name}\" deleted successfully!");
                    _loadClans();
                  } else {
                    _showSnackBar("Failed to delete clan.", isError: true);
                  }
                } catch (e, s) {
                   Logger.error("Error deleting clan ${clan.id}:", error: e, stackTrace: s);
                   _showSnackBar("Failed to delete clan: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // =================================================================================
  // FUNÇÕES DE VERIFICAÇÃO DE PERMISSÃO CENTRALIZADAS
  // Todas as verificações agora usam a instância _permissionService.
  // =================================================================================

  bool _canEditClan(Clan clan) {
    // CORREÇÃO APLICADA: Usa a instância _permissionService criada no initState.
    return _permissionService.canManageClan(clan);
  }

  bool _canDeleteClan() {
    // Esta lógica é simples, então pode continuar aqui ou ser movida para o serviço.
    // Para consistência, vamos movê-la para o serviço também.
    return _permissionService.canAccessAdminPanel(); // Assumindo que só ADM pode deletar.
  }

  bool _canTransferLeadership() {
    return _permissionService.canAccessAdminPanel(); // Assumindo que só ADM pode transferir.
  }

  bool _canDeclareWar() {
    // A permissão para declarar guerra pode depender do clã de origem.
    // Por enquanto, vamos manter uma verificação geral.
    return _permissionService.canAccessAdminPanel(); // Simplificado.
  }
  
  bool _canCreateClans() {
      return _permissionService.canCreateClan();
  }

  void _showAssignClanDialog(User user) {
    String? selectedClanId;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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

  void _showDeclareWarDialog(Clan attackingClan) {
    String? targetClanId;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                  // A verificação de permissão deve ser feita antes de chamar o serviço
                  if (!_permissionService.canDeclareWar(attackingClan)) {
                      _showSnackBar("Você não tem permissão para declarar guerra por este clã.", isError: true);
                      return;
                  }
                  final clanWar = await _clanService.declareWar(attackingClan.id, targetClanId!);
                  if (clanWar != null) {
                    _showSnackBar("Guerra declarada com sucesso!");
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
    if (_currentUser == null && !_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Gerenciar Clãs")),
        body: const Center(child: Text("Por favor, faça login para gerenciar clãs.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Clãs"),
      ),
      body: _isLoading && _clans.isEmpty
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
                    final clanName = clan.name;

                    final bool canTransfer = _canTransferLeadership();
                    final bool canEdit = _canEditClan(clan);
                    final bool canDelete = _canDeleteClan();
                    final bool canWar = _permissionService.canDeclareWar(clan); // Verificação específica por clã

                    return ListTile(
                      title: Text(clanName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           if (canTransfer)
                             IconButton(
                                icon: const Icon(Icons.transfer_within_a_station),
                                onPressed: () => _showTransferLeadershipDialog(clan),
                                tooltip: "Transferir Liderança",
                             ),
                           if (canEdit)
                             IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditClanDialog(clan),
                                tooltip: "Editar Clã",
                             ),
                           if (canDelete)
                             IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteClanConfirmationDialog(clan),
                                tooltip: "Excluir Clã",
                             ),
                           if (canWar)
                             IconButton(
                                icon: const Icon(Icons.gavel),
                                onPressed: () => _showDeclareWarDialog(clan),
                                tooltip: "Declarar Guerra",
                             ),
                            if (!canEdit && !canDelete && !canTransfer && !canWar)
                              const SizedBox.shrink(),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: _canCreateClans()
          ? FloatingActionButton(
              onPressed: _showCreateClanDialog,
              tooltip: "Criar Novo Clã",
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _clanNameController.dispose();
    _editClanNameController.dispose();
    super.dispose();
  }
}
