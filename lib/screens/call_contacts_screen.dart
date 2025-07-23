import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart'; // ✅ AÇÃO 1: ADICIONADO O IMPORT QUE FALTAVA

class CallContactsScreen extends StatefulWidget {
  const CallContactsScreen({super.key});

  @override
  State<CallContactsScreen> createState() => _CallContactsScreenState();
}

class _CallContactsScreenState extends State<CallContactsScreen> {
  List<User> _membros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOnlineUsers();
  }

  Future<void> _loadOnlineUsers() async {
    try {
      setState(() => _isLoading = true);

      final socketService = Provider.of<SocketService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Solicitar a lista de usuários online do backend via API REST
      final response = await apiService.get("/api/users/online");

      if (response != null && response["membros"] != null) {
        _membros = (response["membros"] as List).map((userJson) {
          final Map<String, dynamic> userMap = Map<String, dynamic>.from(userJson);
          if (userMap.containsKey("fotoPerfil")) {
            userMap["avatar"] = userMap["fotoPerfil"];
          }
          return User.fromJson(userMap);
        }).toList();
      }

      // Atualizar o status online/offline com base no SocketService
      // ✅ AÇÃO 2: ADICIONADA VERIFICAÇÃO DE NULIDADE PARA connectedUsers (BOA PRÁTICA)
      final connectedUserIds = socketService.connectedUsers?.keys.toList() ?? [];
      for (var user in _membros) {
        user.isOnline = connectedUserIds.contains(user.id);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      Logger.error("Erro ao carregar usuários online: $e");
      if(mounted) { // ✅ AÇÃO 3: ADICIONADA VERIFICAÇÃO 'mounted' (BOA PRÁTICA)
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initiateCall(User user) async {
    try {
      final voipService = Provider.of<VoIPService>(context, listen: false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Iniciando Chamada', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chamando ${user.username}...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      await voipService.initiateCall(
        targetId: user.id,
        displayName: user.username,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        Logger.error('Erro ao iniciar chamada: $e');
        _showErrorDialog('Erro ao iniciar chamada: $e');
      }
    }
  }

  Future<void> _initiateVideoCall(User user) async {
    _showErrorDialog('Chamadas de vídeo ainda não estão disponíveis.');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Erro', style: TextStyle(color: Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer Chamada'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _membros.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum usuário online no momento',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _membros.length,
                  itemBuilder: (context, index) {
                    final user = _membros[index];
                    return Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          backgroundImage:
                              user.avatar != null ? NetworkImage(user.avatar!) : null,
                          child: user.avatar == null
                              ? Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user.isOnline ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(color: user.isOnline ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.call, color: Colors.green),
                              onPressed: () => _initiateCall(user),
                              tooltip: 'Chamada de voz',
                            ),
                            IconButton(
                              icon: const Icon(Icons.videocam, color: Colors.blue),
                              onPressed: () => _initiateVideoCall(user),
                              tooltip: 'Chamada de vídeo',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOnlineUsers,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
