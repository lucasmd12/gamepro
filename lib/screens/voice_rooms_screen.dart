import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/firebase_service.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/widgets/voice_room_widget.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:firebase_database/firebase_database.dart';

class VoiceRoomsScreen extends StatefulWidget { 
  const VoiceRoomsScreen({super.key});

  @override
  State<VoiceRoomsScreen> createState() => _VoiceRoomsScreenState();
}

class _VoiceRoomsScreenState extends State<VoiceRoomsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salas de Voz'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Clã', icon: Icon(Icons.group)),
            Tab(text: 'Federação', icon: Icon(Icons.account_tree)),
            Tab(text: 'Global', icon: Icon(Icons.public)),
            Tab(text: 'Admin', icon: Icon(Icons.admin_panel_settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClanTab(),
          _buildFederationTab(),
          _buildGlobalTab(),
          _buildAdminTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildClanTab() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        if (user?.clanId == null) {
          return const Center(
            child: Text('Você precisa estar em um clã para acessar as salas de voz do clã.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Salas do clã (até 5 salas)
              ...List.generate(5, (index) {
                // VoiceRoomWidget requires roomType and roomNumber
                return VoiceRoomWidget(
                  roomType: 'clan',
                  roomNumber: index + 1,
                );
              }),
              const SizedBox(height: 16),
              _buildActiveRoomsList('clan', clanId: user?.clanId),
            ],
          ),
        );
      },
    );
 }
  Widget _buildFederationTab() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        if (user?.federationId == null) {
          return const Center(
            child: Text('Você precisa estar em uma federação para acessar as salas de voz da federação.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Salas da federação (até 3 salas)
              ...List.generate(3, (index) {
                // VoiceRoomWidget requires roomType and roomNumber
                return VoiceRoomWidget(
                  roomType: 'federation',
                  roomNumber: index + 1,
                );
              }),
              const SizedBox(height: 16),
              _buildActiveRoomsList("federation", federationId: user?.federationId),
            ],
          ),
        );
      },
    );
  }
  Widget _buildGlobalTab() {
    // Global rooms do not depend on user clan or federation
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // VoiceRoomWidget requires roomType and roomNumber
          const VoiceRoomWidget(
            roomType: 'global',
            roomNumber: 0, // Global rooms might have a different numbering scheme or a default
          ),
          const SizedBox(height: 16),
          _buildActiveRoomsList('global'),
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        if (user?.role != Role.admMaster) {
          return const Center(
            child: Text('Apenas administradores podem acessar as salas administrativas.'),
          );
        }

 return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // VoiceRoomWidget requires roomType and roomNumber
              const VoiceRoomWidget(
                roomType: 'admin',
                roomNumber: 1, // Assuming admin rooms are numbered
              ),
              const VoiceRoomWidget( // Second admin room example
                roomType: 'admin',
              ),
             const SizedBox(height: 16),
             _buildActiveRoomsList('admin'),
           ],
          ),
        );
      },
    );
  }

  Widget _buildActiveRoomsList(String roomType, {String? clanId, String? federationId}) {
    return Consumer<FirebaseService>( 
      builder: (context, firebaseService, child) {
        return StreamBuilder<List<Map<String, dynamic>>>( 
          stream: firebaseService.listenToActiveVoiceRooms(roomType, clanId: clanId, federationId: federationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              Logger.error('Erro ao carregar salas ativas: ${snapshot.error}');
              return Center(child: Text('Erro ao carregar salas ativas: ${snapshot.error}'));
            }

            // Ensure snapshot has data and the value is not null
            final List<Map<String, dynamic>> roomsData = snapshot.data ?? [];

            if (roomsData.isEmpty) {
 return const Center(child: Text('Nenhuma sala ativa encontrada'));
            }

            final List<Map<String, dynamic>> activeRooms = [];
            for (var room in roomsData) {
              // The filtering should happen here based on the room data itself
              // (though listenToActiveVoiceRooms already filters by roomType)
               activeRooms.add(room); // Add the room directly to the list
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salas Ativas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (activeRooms.isEmpty)
                  const Center(child: Text('Nenhuma sala ativa encontrada')),
                ...activeRooms.map((entry) {
                  return _buildActiveRoomCard(entry['roomId'] as String? ?? 'Desconhecido', entry); // Pass room ID and map
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActiveRoomCard(String roomId, Map<dynamic, dynamic> room) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.record_voice_over),
        title: Text(room['roomName'] ?? roomId),
        subtitle: StreamBuilder<DatabaseEvent>(
          stream: Provider.of<FirebaseService>(context, listen: false)
              .listenToVoiceRoomParticipants(roomId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Text('0 participantes');
            }

            final participants = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            return Text('${participants.length} participante(s)');
          },
        ),
        trailing: ElevatedButton(
          onPressed: () => _joinActiveRoom(roomId, room),
          child: const Text('Entrar'),
        ),
      ),
    );
  }

  Future<void> _joinActiveRoom(String roomId, Map<dynamic, dynamic> room) async {
    try {
      final voipService = Provider.of<VoIPService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final user = authService.currentUser;
      if (user == null) return;

      final displayName = user.username ?? 'Usuário Anônimo';

      // Check if room is private and requires password
      final roomDetails = await firebaseService.getVoiceRoomDetails(roomId);
      String? password; 

      if (roomDetails != null && roomDetails['isPrivate'] == true) {
        password = await _showPasswordDialog(context);
      }

      // Entrar na sala Jitsi
      await voipService.joinJitsiMeeting(
        roomName: roomId,
        userDisplayName: displayName,
        userAvatarUrl: user.avatar, // Usando user.avatar
        password: password, // Pass the password to Jitsi Meet
      );

      // Adicionar participante no Firebase
      await firebaseService.joinVoiceRoom(roomId, user.id, displayName);

      Logger.info('Usuário entrou na sala ativa: $roomId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entrou na sala "${room['roomName'] ?? roomId}"!')),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao entrar na sala ativa', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao entrar na sala. Verifique a senha e tente novamente.')),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    String? password;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Senha da Sala'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Digite a senha da sala'),
            onChanged: (value) {
              password = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Entrar'),
              onPressed: () {
                Navigator.of(context).pop(password);
              },
            ),
          ],
        );
      },
    );
    return password;
  }

  Widget? _buildFloatingActionButton() {
    return Consumer<VoIPService>(
      builder: (context, voipService, child) {
        if (!voipService.isInCall) return const SizedBox.shrink();

        return FloatingActionButton(
          onPressed: () async {
            await voipService.endCall();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saiu da chamada')),
              );
            }
          },
          backgroundColor: Colors.red,
          child: const Icon(Icons.call_end),
        );
      },
    );
  }
}
