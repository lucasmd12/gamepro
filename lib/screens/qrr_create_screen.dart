import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/qrr_model.dart';
import 'package:lucasbeatsfederacao/services/qrr_service.dart';
import 'package:lucasbeatsfederacao/services/upload_service.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart'; // Import Clan
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Import Role
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';

class QRRCreateScreen extends StatefulWidget {
  const QRRCreateScreen({super.key});

  @override
  State<QRRCreateScreen> createState() => _QRRCreateScreenState();
}

class _QRRCreateScreenState extends State<QRRCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  QRRType _selectedType = QRRType.mission;
  QRRPriority _selectedPriority = QRRPriority.medium;
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;
  XFile? _imageFile;
  bool _canSelectEntity = false;
  String? _userClanName; // To display current clan for non-admins
  String? _selectedEntityType; // 'clan' or 'federation'
  String? _selectedEntityId;
  List<dynamic> _availableEntities = []; // Use dynamic for now, will refine later
  List<Clan> _availableClansForEnemy = []; // Lista de clãs para seleção de inimigo
  String? _selectedEnemyClanId;
  String? _selectedEnemyClanFlagUrl;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _canSelectEntity = user.role == Role.admMaster || user.role == Role.leader || user.role == Role.clanLeader;

      // If the user is not an admin and belongs to a clan, pre-select their clan
      if (user.role != Role.admMaster && user.clanId != null) {
        // For non-admins with a clan, pre-select their clan
        _selectedEntityType = 'clan';
        _selectedEntityId = user.clanId;
        _userClanName = user.clanName; // Initialize _userClanName here
      }
      if (_canSelectEntity) {
        // For admins, fetch all clans and federations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchAvailableEntities();
          _fetchAllClansForEnemySelection(); // Fetch all clans for enemy selection
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      final selected = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (isStart) {
        _selectedStartTime = selected;
      } else {
        _selectedEndTime = selected;
      }
    });
  }

  Future<void> _createQRR() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    // Validate that an entity is selected if the user can select one
    if (_canSelectEntity && (_selectedEntityType == null || _selectedEntityId == null)) {
      CustomSnackbar.showError(context, 'Selecione um Clã ou Federação.');
      setState(() => _isLoading = false);
      return;
    }
    if (!_canSelectEntity && (user == null || user.clanId == null)) {
       CustomSnackbar.showError(context, 'Você precisa estar em um clã para criar um QRR.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final qrrService = Provider.of<QRRService>(context, listen: false);
      final uploadService = Provider.of<UploadService>(context, listen: false);

      String? imageUrl;
      if (_imageFile != null) {
        final uploadResult = await uploadService.uploadMissionImage(File(_imageFile!.path));
        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          imageUrl = uploadResult["data"][0]["url"]; // Acessa o primeiro elemento do array 'data'
        } else {
          // Tratar o erro de upload
          Logger.error('Erro no upload da imagem: ${uploadResult['message']}');
          CustomSnackbar.showError(context, 'Erro no upload da imagem: ${uploadResult['message']}');
          setState(() => _isLoading = false);
          return;
        }
      }

      final Map<String, dynamic> newQRR = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'type': _selectedType.toString().split('.').last,
        'priority': _selectedPriority.toString().split('.').last,
        'startTime': _selectedStartTime?.toIso8601String(),
        'endTime': _selectedEndTime?.toIso8601String(),
        'maxParticipants': _maxParticipantsController.text.isEmpty
            ? null
            : int.tryParse(_maxParticipantsController.text),
        'enemyClanId': _selectedEnemyClanId, // Adiciona o ID do clã inimigo
        'enemyClanFlagUrl': _selectedEnemyClanFlagUrl, // Adiciona a URL da bandeira do clã inimigo
      };

      // Include either clanId or federationId based on selection or user's affiliation
      if (_selectedEntityType == 'clan' && _selectedEntityId != null) {
        newQRR['clanId'] = _selectedEntityId;
      } else if (_selectedEntityType == 'federation' && _selectedEntityId != null) {
        newQRR['federationId'] = _selectedEntityId!;
      } else if (!_canSelectEntity && user?.clanId != null) {
         newQRR['clanId'] = user!.clanId!;
      }


      await qrrService.createQRR(newQRR);
      CustomSnackbar.showSuccess(context, 'QRR criada com sucesso!');
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      Logger.error('Erro ao criar QRR', error: e, stackTrace: st);
      CustomSnackbar.showError(context, 'Erro ao criar QRR: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAvailableEntities() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final clanService = Provider.of<ClanService>(context, listen: false);
      final federationService = Provider.of<FederationService>(context, listen: false);

      // This call assumes getAllClans() exists and returns a List<Clan>.
      final clans = await clanService.getAllClans();
      final federations = await federationService.getAllFederations(); // Assuming getAllFederations() exists

      if (mounted) {
        setState(() {
          _availableEntities = [...clans, ...federations];
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao buscar clãs/federações', error: e);
      if (mounted) {
         CustomSnackbar.showError(context, 'Erro ao buscar clãs/federações: ${e.toString()}');
      }
    }
  }

  Future<void> _fetchAllClansForEnemySelection() async {
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final clans = await clanService.getAllClans();
      if (mounted) {
        setState(() {
          _availableClansForEnemy = clans;
        });
      }
    } catch (e) {
      Logger.error('Erro ao buscar clãs para seleção de inimigo', error: e);
      if (mounted) {
        CustomSnackbar.showError(context, 'Erro ao buscar clãs para seleção de inimigo: ${e.toString()}');
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Nova Missão QRR'),
        backgroundColor: Colors.grey[900],
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Título da Missão',
                      validator: (v) => (v == null || v.isEmpty) ? 'Insira um título' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Descrição da Missão',
                      maxLines: 3,
                      validator: (v) => (v == null || v.isEmpty) ? 'Insira uma descrição' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_imageFile == null)
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Selecionar Imagem (Opcional)'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      )
                    else
                      Column(
                        children: [
                          Image.file(File(_imageFile!.path), height: 150, fit: BoxFit.cover),
                          TextButton(onPressed: _pickImage, child: const Text("Trocar Imagem")),
                        ],
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<QRRType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Missão',
                        border: OutlineInputBorder(),
                      ),
                      items: QRRType.values
                          .map((type) => DropdownMenuItem(value: type, child: Text(type.displayName)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<QRRPriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        border: OutlineInputBorder(),
                      ),
                      items: QRRPriority.values
                          .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedPriority = val!),
                    ),
                    const SizedBox(height: 16),
                    // Dropdown para seleção de Clã/Federação (visível para admins)
                    if (_canSelectEntity && !_isLoading)
                      DropdownButtonFormField<String?>(
                        value: _selectedEntityId,
                        decoration: const InputDecoration(
                          labelText: 'Associar a',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Selecione Clã ou Federação'),
                          ),
                          ..._availableEntities.map((entity) {
                            final isClan = entity is Clan;
                            final name = isClan ? entity.name : entity.name; // Assuming Federation model has a 'name'
                            final id = isClan ? entity.id : entity.id; // Assuming both have an 'id'
                            final type = isClan ? 'clan' : 'federation';

                            return DropdownMenuItem<String?>(
                              value: id,
                              child: Text('$name ($type)'),
                              onTap: () {
                                setState(() {
                                  _selectedEntityType = type;
                                });
                              },
                            );
                          }).toList(),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedEntityId = val;
                            // _selectedEntityType is set in onTap of DropdownMenuItem
                          });
                        },
                      ),
                    if (!_canSelectEntity && _userClanName != null)
                       Padding(
                         padding: const EdgeInsets.symmetric(vertical: 8.0),
                         child: Text(
                           'Associado ao Clã: $_userClanName',
                           style: TextStyle(fontSize: 16, color: Colors.white70),
                         ),
                       ),

                    const SizedBox(height: 16),
                    // Dropdown para seleção de Clã Inimigo (opcional)
                    DropdownButtonFormField<String?>(
                      value: _selectedEnemyClanId,
                      decoration: const InputDecoration(
                        labelText: 'Clã Inimigo (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Nenhum Clã Inimigo'),
                        ),
                        ..._availableClansForEnemy.map((clan) {
                          return DropdownMenuItem<String?>(
                            value: clan.id,
                            child: Text(clan.name),
                            onTap: () {
                              setState(() {
                                _selectedEnemyClanFlagUrl = clan.bannerImageUrl; // Assume bannerImageUrl é a flag
                              });
                            },
                          );
                        }).toList(),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedEnemyClanId = val;
                          if (val == null) {
                            _selectedEnemyClanFlagUrl = null;
                          } else {
                            // Encontrar a URL da bandeira do clã selecionado
                            final selectedClan = _availableClansForEnemy.firstWhere((clan) => clan.id == val);
                            _selectedEnemyClanFlagUrl = selectedClan.bannerImageUrl; // Assume bannerImageUrl é a flag
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_selectedStartTime == null
                          ? 'Selecionar Data e Hora de Início'
                          : 'Início: ${_formatDateTime(_selectedStartTime!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateTime(context, true),
                    ),
                    ListTile(
                      title: Text(_selectedEndTime == null
                          ? 'Selecionar Data e Hora de Término'
                          : 'Término: ${_formatDateTime(_selectedEndTime!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateTime(context, false),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _maxParticipantsController,
                      label: 'Máximo de Participantes (Opcional)',
                      type: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                          return 'Insira um número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _createQRR,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('Criar Missão QRR', style: TextStyle(fontSize: 18)),
                            ),
                    ), // Added back ElevatedButton
                  ],
                ),
              ),
            ),
             if (_isLoading)
                Container(
                  color: Colors.black54, // Escurece o fundo
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

