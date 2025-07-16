import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/services/firebase_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart' show User;
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/widgets/permission_widget.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:uuid/uuid.dart';

class VoiceRoomWidget extends StatefulWidget {
  final String roomType; // 'clan', 'federation', 'global', 'admin'
  final String? clanId;
  final String? federationId;
  final String? context; // Para salas admin
  final int? roomNumber; // Para salas de clã e federação

  const VoiceRoomWidget({
    super.key,
    required this.roomType,
    this.clanId,
    this.federationId,
    this.context,
    this.roomNumber,
  });

  @override
  State<VoiceRoomWidget> createState() => _VoiceRoomWidgetState();
}

class _VoiceRoomWidgetState extends State<VoiceRoomWidget> {
  final Uuid _uuid = const Uuid();
  bool _isCreatingRoom = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<FirebaseService, AuthService>(
      builder: (context, firebaseService, authService, child) {
        final user = authService.currentUser;
        if (user == null) {
          return const Center(child: Text('Usuário não autenticado'));
        }

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRoomTypeTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRoomDescription(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    PermissionWidget(
                      requiredAction: 'create_${widget.roomType}_voice_room',
                      clanId: widget.clanId,
                      federationId: widget.federationId,
                      child: Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCreatingRoom ? null : () => _createRoom(firebaseService, user),
                          icon: _isCreatingRoom
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add),
                          label: Text(_isCreatingRoom ? 'Criando...' : 'Criar Sala'),
                        ),
                      ),
                    ),
                    PermissionWidget(
                      requiredAction: 'create_${widget.roomType}_voice_room',
                      clanId: widget.clanId,
                      federationId: widget.federationId,
                      child: PermissionWidget(
                        requiredAction: 'join_${widget.roomType}_voice_room',
                        clanId: widget.clanId,
                        federationId: widget.federationId,
                        child: const SizedBox(width: 8),
                      ),
                    ),
                    PermissionWidget(
                      requiredAction: 'join_${widget.roomType}_voice_room',
                      clanId: widget.clanId,
                      federationId: widget.federationId,
                      child: Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showJoinRoomDialog(firebaseService, user),
                          icon: const Icon(Icons.login),
                          label: const Text('Entrar em Sala'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRoomTypeTitle() {
    switch (widget.roomType) {
      case 'clan':
        return 'Salas de Voz do Clã';
      case 'federation':
        return 'Salas de Voz da Federação';
      case 'global':
        return 'Salas Globais';
      case 'admin':
        return 'Salas Administrativas';
      default:
        return 'Salas de Voz';
    }
  }

  String _getRoomDescription() {
    switch (widget.roomType) {
      case 'clan':
        return 'Até 5 salas por clã. Apenas líderes podem criar, membros podem entrar.';
      case 'federation':
        return 'Até 3 salas por federação. Apenas líderes de clã podem criar e entrar.';
      case 'global':
        return 'Qualquer usuário pode criar. Limitado a 10 participantes.';
      case 'admin':
        return 'Salas administrativas. Apenas ADMs podem criar e gerenciar.';
      default:
        return '';
    }
  }

  bool _canCreateRoom(User user) {
    switch (widget.roomType) {
      case 'clan':
        return user.role == Role.leader || user.role == Role.admMaster;
      case 'federation':
        return user.role == Role.leader || user.role == Role.admMaster;
      case 'global':
        return true; // Qualquer usuário pode criar salas globais
      case 'admin':
        return user.role == Role.admMaster;
      default:
        return false;
    }
  }

  bool _canJoinRoom(User user) {
    switch (widget.roomType) {
      case 'clan':
        return true; // Membros do clã podem entrar
      case 'federation':
        // Federation leader and members can join federation voice rooms.
        return user.role == Role.admMaster ||
            user.role == Role.leader || user.role == Role.member;
      case 'global':
        return true; // Qualquer usuário pode entrar
      case 'admin':
        return user.role == Role.admMaster;
      default:
        return false;
    }
  }

  Future<void> _createRoom(FirebaseService firebaseService, User user) async {
    setState(() {
      _isCreatingRoom = true;
    });

    try {
      final roomName = _generateRoomName(user);
      final displayName = user.username ?? 'Usuário Anônimo';
      final voipService = Provider.of<VoIPService>(context, listen: false);

      // Criar sala no Firebase
      await firebaseService.createVoiceRoom(
        roomName,
        widget.roomType,
        user.id,
        clanId: widget.clanId,
        federationId: widget.federationId,
      );

      // Entrar na sala Jitsi
      await voipService.joinJitsiMeeting(
        roomName: roomName,
        userDisplayName: displayName,
      );

      // Adicionar participante no Firebase
      await firebaseService.joinVoiceRoom(roomName, user.id, displayName);

      Logger.info('Sala criada e usuário entrou: $roomName');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sala "$roomName" criada com sucesso!')),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao criar sala', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar sala. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRoom = false;
        });
      }
    }
  }

  void _showJoinRoomDialog(FirebaseService firebaseService, User user) {
    final TextEditingController roomController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Entrar em Sala'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Digite o nome da sala ou escolha uma sala ativa:'),
              const SizedBox(height: 16),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Sala',
                  hintText: 'Ex: voz_clan_1_1',
                ),
              ),
              const SizedBox(height: 16),
              // Lista de salas ativas (implementar StreamBuilder aqui se necessário)
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final roomName = roomController.text.trim();
                if (roomName.isNotEmpty) {
                  Navigator.of(context).pop();
                  _joinRoom(firebaseService, user, roomName);
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinRoom(FirebaseService firebaseService, User user, String roomName) async {
    try {
      final displayName = user.username ?? 'Usuário Anônimo';
      final voipService = Provider.of<VoIPService>(context, listen: false);

      // Entrar na sala Jitsi
      await voipService.joinJitsiMeeting(
        roomName: roomName,
        userDisplayName: displayName,
      );

      // Adicionar participante no Firebase
      await firebaseService.joinVoiceRoom(roomName, user.id, displayName);

      Logger.info('Usuário entrou na sala: $roomName');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entrou na sala "$roomName"!')),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao entrar na sala', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao entrar na sala. Verifique o nome e tente novamente.')),
        );
      }
    }
  }

  String _generateRoomName(User user) {
    final uuid = _uuid.v4().substring(0, 8);
    
    switch (widget.roomType) {
      case 'clan':
        final roomNum = widget.roomNumber ?? 1;
        return 'voz_clan_${widget.clanId}_$roomNum';
      case 'federation':
        final roomNum = widget.roomNumber ?? 1;
        return 'voz_fed_${widget.federationId}_$roomNum';
      case 'global':
        return 'voz_global_${user.id}_$uuid';
      case 'admin':
        final context = widget.context ?? 'general';
        final id = widget.clanId ?? widget.federationId ?? user.id;
        return 'voz_adm_${context}_${id}_$uuid';
      default:
        return 'voz_default_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  String _getRoomDisplayName(String roomName) {
    switch (widget.roomType) {
      case 'clan':
        return 'Sala do Clã ${widget.clanId} - ${widget.roomNumber ?? 1}';
      case 'federation':
        return 'Sala da Federação ${widget.federationId} - ${widget.roomNumber ?? 1}';
      case 'global':
        return 'Sala Global';
      case 'admin':
        return 'Sala Admin - ${widget.context ?? 'Geral'}';
      default:
        return roomName;
    }
  }
}


