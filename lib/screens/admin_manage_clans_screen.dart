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
  final String? federationId;

  const AdminManageClansScreen({super.key, this.federationId});

  @override
  State<AdminManageClansScreen> createState() => _AdminManageClansScreenState();
}

class _AdminManageClansScreenState extends State<AdminManageClansScreen> {
  List<Clan> _clans = [];
  List<Federation> _availableFederations = [];
  bool _isDesignatedFederationLeader = false;
  String? _selectedFederationId;
  bool _isLoading = false;
  User? _currentUser;

  final TextEditingController _clanNameController = TextEditingController();
  final TextEditingController _editClanNameController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late final ClanService _clanService;
  late final FederationService _federationService;
  late final UserService _userService;
  late final UploadService _uploadService;
  late final PermissionService _permissionService;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _clanService = Provider.of<ClanService>(context, listen: false);
    _federationService = Provider.of<FederationService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
    _uploadService = Provider.of<UploadService>(context, listen: false);
    _permissionService = PermissionService(authProvider: authProvider);
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;

    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
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
        if (mounted) _showSnackBar("Failed to check federation leader status: $e", isError: true);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadClans() async {
    Logger.info("Loading clans...");
    if (!mounted) return;
    try {
      // Assumindo que o serviço foi corrigido para aceitar paginação
      final clans = await _clanService.getAllClans();
      if (mounted) setState(() => _clans = clans.whereType<Clan>().toList());
    } catch (e, s) {
      Logger.error("Error loading clans:", error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar("Failed to load clans: $e", isError: true);
        setState(() => _clans = []);
      }
    }
  }

  Future<void> _loadFederations() async {
    Logger.info("Loading federations...");
    if (!mounted) return;
    try {
      // Assumindo que o serviço foi corrigido para aceitar paginação
      final federations = await _federationService.getAllFederations();
      if (mounted) setState(() => _availableFederations = federations.whereType<Federation>().toList());
    } catch (e, s) {
      Logger.error("Error loading federations:", error: e, stackTrace: s);
      if (mounted) {
        _showSnackBar("Failed to load federations: $e", isError: true);
        setState(() => _availableFederations = []);
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
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }

  void _showCreateClanDialog() {
    _selectedFederationId = widget.federationId;
    _clanNameController.clear();
    _selectedImage = null; // Limpar imagem selecionada

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final currentUser = Provider.of<AuthProvider>(dialogContext, listen: false).currentUser!;
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
                    child: Image.file(_selectedImage!, height: 100, width: 100, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                if (isAdmMaster || _isDesignatedFederationLeader)
                  DropdownButtonFormField<String?>(
                    value: _selectedFederationId,
                    decoration: const InputDecoration(labelText: "Associar a Federação", border: OutlineInputBorder()),
                    items: [
                      if (isAdmMaster && !_isDesignatedFederationLeader)
                        const DropdownMenuItem<String?>(value: null, child: Text("Nenhuma Federação")),
                      ..._availableFederations.map((f) => DropdownMenuItem<String?>(value: f.id, child: Text(f.name))).toList(),
                    ],
                    onChanged: disableFederationSelection ? null : (val) => setState(() => _selectedFederationId = val),
                    disabledHint: disableFederationSelection ? Text(_availableFederations.first.name) : null,
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text("Criar"),
              onPressed: () async {
                final clanName = _clanNameController.text.trim();
                if (clanName.isEmpty) {
                  _showSnackBar("O nome do clã não pode ser vazio.", isError: true);
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  String? logoUrl;
                  if (_selectedImage != null) {
                    // Usando uploadAvatar que parece mais apropriado para logos
                    final uploadResult = await _uploadService.uploadAvatar(_selectedImage!);
                    if (uploadResult["success"] && uploadResult["data"] != null) {
                      logoUrl = uploadResult["data"]["url"];
                    } else {
                      _showSnackBar("Falha ao fazer upload do logo: ${uploadResult["message"]}", isError: true);
                      return;
                    }
                  }
                  
                  // ==================== INÍCIO DA CORREÇÃO ====================
                  // O serviço agora espera (String name, String? tag).
                  // Vamos passar o nome e a URL do logo como a "tag" por enquanto.
                  // O ideal seria ajustar o serviço para aceitar um logoUrl.
                  final newClan = await _clanService.createClan(clanName, logoUrl);
                  // ===================== FIM DA CORREÇÃO ======================

                  if (newClan != null) {
                    _showSnackBar("Clã \"${newClan.name}\" criado com sucesso!");
                    _loadClans();
                  } else {
                    _showSnackBar("Falha ao criar clã.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Error creating clan:", error: e, stackTrace: s);
                  _showSnackBar("Falha ao criar clã: ${e.toString()}", isError: true);
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
    if (!_canEditClan(clan)) {
      _showPermissionDeniedDialog("Você não tem permissão para editar este clã.");
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Editar Clã: ${clan.name}"),
          content: TextField(controller: _editClanNameController, decoration: const InputDecoration(hintText: "Novo Nome do Clã")),
          actions: <Widget>[
            TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text("Salvar"),
              onPressed: () async {
                final newName = _editClanNameController.text.trim();
                if (newName.isEmpty) {
                  _showSnackBar("O nome do clã não pode ser vazio.", isError: true);
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  final updatedClan = await _clanService.updateClanDetails(clan.id, name: newName);
                  if (updatedClan != null) {
                    _showSnackBar("Clã \"${updatedClan.name}\" atualizado com sucesso!");
                    _loadClans();
                  } else {
                    _showSnackBar("Falha ao atualizar clã.", isError: true);
                  }
                } catch (e, s) {
                   Logger.error("Error updating clan ${clan.id}:", error: e, stackTrace: s);
                   _showSnackBar("Falha ao atualizar clã: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showTransferLeadershipDialog(Clan clan) {
    final newLeaderController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Transferir Liderança do Clã: ${clan.name}"),
          content: TextField(controller: newLeaderController, decoration: const InputDecoration(hintText: "Nome de usuário do novo líder")),
          actions: <Widget>[
            TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text("Transferir"),
              onPressed: () async {
                final newLeaderId = newLeaderController.text.trim();
                if (newLeaderId.isEmpty) {
                  _showSnackBar("O nome de usuário não pode ser vazio.", isError: true);
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  final success = await _clanService.transferClanLeadership(clan.id, newLeaderId);
                  if (success) {
                    _showSnackBar("Liderança do clã \"${clan.name}\" transferida com sucesso!");
                    _loadClans();
                  } else {
                    _showSnackBar("Falha ao transferir liderança.", isError: true);
                  }
                } catch (e, s) {
                  Logger.error("Error transferring clan leadership:", error: e, stackTrace: s);
                  _showSnackBar("Falha ao transferir liderança: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteClanConfirmationDialog(Clan clan) {
    if (!_canDeleteClan(clan)) {
      _showPermissionDeniedDialog("Você não tem permissão para excluir este clã.");
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: Text("Tem certeza que deseja excluir o clã \"${clan.name}\"?"),
          actions: <Widget>[
            TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              child: const Text("Excluir", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  bool success = await _clanService.deleteClan(clan.id);
                  if (success) {
                    _showSnackBar("Clã \"${clan.name}\" excluído com sucesso!");
                    _loadClans();
                  } else {
                    _showSnackBar("Falha ao excluir clã.", isError: true);
                  }
                } catch (e, s) {
                   Logger.error("Error deleting clan ${clan.id}:", error: e, stackTrace: s);
                   _showSnackBar("Falha ao excluir clã: ${e.toString()}", isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Permissão Negada"),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("OK"))],
        );
      },
    );
  }

  bool _canEditClan(Clan clan) => _permissionService.canManageClan(clan);
  bool _canDeleteClan(Clan clan) => _permissionService.canAccessAdminPanel();
  bool _canTransferLeadership(Clan clan) => _permissionService.canAccessAdminPanel();
  bool _canDeclareWar(Clan clan) => _permissionService.canDeclareWar(clan);
  bool _canCreateClans() => _permissionService.canCreateClan();

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null && !_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Gerenciar Clãs")),
        body: const Center(child: Text("Por favor, faça login para gerenciar clãs.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Gerenciar Clãs")),
      body: _isLoading && _clans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _clans.isEmpty
              ? const Center(child: Text("Nenhum clã encontrado."))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _clans.length,
                  itemBuilder: (context, index) {
                    final clan = _clans[index];
                    return ListTile(
                      title: Text(clan.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_canTransferLeadership(clan))
                            IconButton(icon: const Icon(Icons.transfer_within_a_station), onPressed: () => _showTransferLeadershipDialog(clan), tooltip: "Transferir Liderança"),
                          if (_canEditClan(clan))
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditClanDialog(clan), tooltip: "Editar Clã"),
                          if (_canDeleteClan(clan))
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteClanConfirmationDialog(clan), tooltip: "Excluir Clã"),
                          if (_canDeclareWar(clan))
                            IconButton(icon: const Icon(Icons.gavel), onPressed: () => {}, tooltip: "Declarar Guerra"),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: _canCreateClans()
          ? FloatingActionButton(onPressed: _showCreateClanDialog, tooltip: "Criar Novo Clã", child: const Icon(Icons.add))
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
