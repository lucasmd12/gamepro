import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/qrr_model.dart';
import 'package:lucasbeatsfederacao/services/qrr_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
// Importar o modelo User
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Importar o modelo Role

class QRRParticipantsScreen extends StatefulWidget {
  final QRRModel qrr;

  const QRRParticipantsScreen({super.key, required this.qrr});

  @override
  State<QRRParticipantsScreen> createState() => _QRRParticipantsScreenState();
}

class _QRRParticipantsScreenState extends State<QRRParticipantsScreen> {
  late QRRModel _qrr;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _qrr = widget.qrr;
    _refreshQRR(); // Carregar os participantes mais recentes
  }

  Future<void> _refreshQRR() async {
    try {
      setState(() => _isLoading = true);
      final qrrService = Provider.of<QRRService>(context, listen: false);
      final updatedQRR = await qrrService.getQRRById(_qrr.id);
      if (mounted) {
        setState(() {
          _qrr = updatedQRR!;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao atualizar QRR para participantes', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar participantes: ${e.toString()}')),
        );
      }
    }
  }

  // Função auxiliar para verificar se um participante está presente
  bool _isParticipantPresent(String userId) {
    if (_qrr.performanceMetrics == null) return false;
    return _qrr.performanceMetrics!.any((metric) =>
        metric['userId'] == userId && metric['isPresent'] == true);
  }

  Future<void> _togglePresence(String userId, bool isPresent) async {
    setState(() => _isLoading = true);
    try {
      final qrrService = Provider.of<QRRService>(context, listen: false);
      // A API de markParticipantPresent provavelmente precisa de um campo para isPresent
      // Assumindo que a API aceita um payload como {'userId': userId, 'isPresent': isPresent}
      await qrrService.markParticipantPresent(_qrr.id, userId, isPresent); // Corrigido para 3 argumentos
      await _refreshQRR();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presença de ${isPresent ? 'marcada' : 'desmarcada'} com sucesso!')),
        );
      }
    } catch (e) {
      Logger.error('Erro ao marcar presença', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar presença: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // Verificar se o usuário tem permissão para gerenciar (ADM, Leader, SubLeader)
    final canManage = currentUser != null && (
      currentUser.role == Role.admMaster || // Use Role.admMaster for unified admin
      currentUser.role == Role.leader || // Keep leader
      currentUser.role == Role.subLeader // Keep subLeader
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Participantes da QRR: ${_qrr.title}'),
        backgroundColor: Colors.grey[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshQRR,
              child: _qrr.participants.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum participante ainda.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _qrr.participants.length,
                      itemBuilder: (context, index) {
                        final participant = _qrr.participants[index];
                        final isPresent = _isParticipantPresent(participant.id); // Usar participant.id

                        return Card(
                          color: Colors.grey[850],
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: participant.avatar != null // Check if avatar is not null
                                      ? NetworkImage(participant.avatar!) as ImageProvider<Object>? // Use NetworkImage and cast to ImageProvider<Object>?
 : const AssetImage('assets/images_png/default_avatar.png'), // Otherwise use AssetImage

                                  child: participant.avatar == null
                                      ? Text(participant.username.isNotEmpty ? participant.username[0].toUpperCase() : '?')
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        participant.username,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        participant.role.displayName, // Usar displayName do enum Role
                                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                      ),
                                      Text(
                                        'Cargo no Clã: ${participant.clanRole.displayName}', // Usar displayName do enum Role
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (canManage) // Apenas líderes/ADMs podem marcar presença
                                  Switch(
                                    value: isPresent,
                                    onChanged: (value) {
                                      _togglePresence(participant.id, value); // Usar participant.id
                                    },
                                    activeColor: Colors.green,
                                  )
                                else if (isPresent)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}


