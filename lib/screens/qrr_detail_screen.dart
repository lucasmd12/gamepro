import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/qrr_model.dart';
import 'package:lucasbeatsfederacao/services/qrr_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/qrr_edit_screen.dart';
import 'package:lucasbeatsfederacao/screens/qrr_participants_screen.dart';
// Importar User
import 'package:lucasbeatsfederacao/models/role_model.dart'; // Importar Role

class QRRDetailScreen extends StatefulWidget {
  final QRRModel qrr;

  const QRRDetailScreen({
    super.key,
    required this.qrr,
  });

  @override
  State<QRRDetailScreen> createState() => _QRRDetailScreenState();
}

class _QRRDetailScreenState extends State<QRRDetailScreen> {
  late QRRModel _qrr;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _qrr = widget.qrr;
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
      Logger.error("Erro ao atualizar QRR", error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _joinQRR() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception("Usuário não autenticado");
      }

      final qrrService = Provider.of<QRRService>(context, listen: false);
      await qrrService.joinQRR(_qrr.id, currentUser.id);
      await _refreshQRR();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Você entrou na missão!")),
        );
      }
    } catch (e) {
      Logger.error("Erro ao entrar na QRR", error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao entrar na missão: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _leaveQRR() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception("Usuário não autenticado");
      }

      final qrrService = Provider.of<QRRService>(context, listen: false);
      await qrrService.leaveQRR(_qrr.id, currentUser.id);
      await _refreshQRR();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Você saiu da missão!")),
        );
      }
    }
    catch (e) {
      Logger.error("Erro ao sair da QRR", error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao sair da missão: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _updateQRRStatus(QRRStatus newStatus) async {
    try {
      setState(() => _isLoading = true);
      final qrrService = Provider.of<QRRService>(context, listen: false);
      await qrrService.updateQRRStatus(_qrr.id, newStatus);
      await _refreshQRR();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status atualizado para ${newStatus.displayName}")),
        );
      }
    } catch (e) {
      Logger.error("Erro ao atualizar status da QRR", error: e);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar status: ${e.toString()}")),
        );
      }
    }
  }

  void _navigateToEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRREditScreen(qrr: _qrr),
      ),
    ).then((_) => _refreshQRR()); // Atualiza a QRR após retornar da tela de edição
  }

  void _navigateToParticipants() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRRParticipantsScreen(qrr: _qrr),
      ),
    ).then((_) => _refreshQRR()); // Atualiza a QRR após retornar da tela de participantes
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'activate':
        _updateQRRStatus(QRRStatus.active);
        break;
      case 'complete':
        _updateQRRStatus(QRRStatus.completed);
        break;
      case 'cancel':
        _updateQRRStatus(QRRStatus.cancelled);
        break;
      case 'participants':
        _navigateToParticipants();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isParticipant = currentUser != null && _qrr.participants.any((p) => p.id == currentUser.id);
    final canManage = currentUser != null && (
      currentUser.role == Role.admMaster ||
      currentUser.role == Role.leader ||
      currentUser.role == Role.subLeader ||
      currentUser.role == Role.clanLeader ||
      currentUser.role == Role.clanSubLeader
    );
    final canJoin = currentUser != null && _qrr.canUserJoin(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_qrr.title),
        backgroundColor: Colors.grey[900],
        actions: [
          if (canManage) ...[
            IconButton(
              onPressed: () => _navigateToEdit(),
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                if (_qrr.status == QRRStatus.pending)
                  const PopupMenuItem(
                    value: 'activate',
                    child: Text('Ativar'),
                  ),
                if (_qrr.status == QRRStatus.active)
                  const PopupMenuItem(
                    value: 'complete',
                    child: Text('Concluir'),
                  ),
                if (_qrr.status != QRRStatus.completed && _qrr.status != QRRStatus.cancelled)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancelar'),
                  ),
                const PopupMenuItem(
                  value: 'participants',
                  child: Text('Gerenciar Participantes'),
                ),
              ],
            ),
          ],
          IconButton(
            onPressed: _refreshQRR,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildDetails(),
                  const SizedBox(height: 24),
                  _buildParticipants(),
                  if (_qrr.result != null) ...[
                    const SizedBox(height: 24),
                    _buildResult(),
                  ],
                  const SizedBox(height: 100), // Espaço para o FAB
                ],
              ),
            ),
      floatingActionButton: _buildActionButton(isParticipant, canJoin),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _qrr.displayIcon ?? Icons.assignment, // Usar displayIcon ou um ícone padrão
                  color: _qrr.displayColor ?? Colors.blue, // Usar displayColor ou uma cor padrão
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _qrr.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _qrr.status.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _qrr.status.color),
                            ),
                            child: Text(
                              _qrr.status.displayName,
                              style: TextStyle(
                                color: _qrr.status.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _qrr.priority.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _qrr.priority.color),
                            ),
                            child: Text(
                              _qrr.priority.displayName,
                              style: TextStyle(
                                color: _qrr.priority.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_qrr.imageUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _qrr.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[700],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descrição',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _qrr.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalhes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Tipo', _qrr.type.displayName, _qrr.displayIcon ?? Icons.assignment),
            _buildDetailRow('Prioridade', _qrr.priority.displayName, Icons.flag, color: _qrr.priority.color),
            _buildDetailRow('Participantes', '${_qrr.participants.length}${_qrr.maxParticipants != null ? '/${_qrr.maxParticipants}' : ''}', Icons.people),
            _buildDetailRow('Início', _formatDateTime(_qrr.startDate), Icons.schedule),
            _buildDetailRow('Fim', _formatDateTime(_qrr.endDate), Icons.schedule_send),
            if (_qrr.duration != null)
              _buildDetailRow('Duração', _formatDuration(_qrr.duration!), Icons.timer),
            if (_qrr.requiredRoles != null && _qrr.requiredRoles!.isNotEmpty)
              _buildDetailRow('Roles Necessários', _qrr.requiredRoles!.join(', '), Icons.security),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipants() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participantes (${_qrr.participants.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_qrr.participants.isNotEmpty)
                  TextButton(
                    onPressed: () => _navigateToParticipants(),
                    child: const Text('Ver Todos'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _qrr.participants.isEmpty
                ? Text(
                    'Nenhum participante ainda.',
                    style: TextStyle(color: Colors.grey[300]),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _qrr.participants.length > 3 ? 3 : _qrr.participants.length,
                    itemBuilder: (context, index) {
                      final participant = _qrr.participants[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: participant.avatar != null
                                  ? NetworkImage(participant.avatar!) as ImageProvider<Object>?
                                  : const AssetImage("assets/images_png/default_avatar.png"),
                              radius: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              participant.username, // Usando a String diretamente
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            // Comentado temporariamente: Avaliar necessidade futura do widget Text aninhado
                            // Text(
                            //   Text(participant.username, // Acessando username do objeto User
                            //   style: const TextStyle(color: Colors.white, fontSize: 16),
                            // ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _qrr.result! ,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isParticipant, bool canJoin) {
    if (_qrr.status == QRRStatus.completed || _qrr.status == QRRStatus.cancelled) {
      return const SizedBox.shrink(); // Não mostra botão se a QRR estiver concluída ou cancelada
    }

    if (isParticipant) {
      return FloatingActionButton.extended(
        onPressed: _leaveQRR,
        label: const Text('Sair da Missão'),
        icon: const Icon(Icons.logout),
        backgroundColor: Colors.red[700],
      );
    } else if (canJoin) {
      return FloatingActionButton.extended(
        onPressed: _joinQRR,
        label: const Text('Entrar na Missão'),
        icon: const Icon(Icons.login),
        backgroundColor: Colors.green[700],
      );
    } else {
      return const SizedBox.shrink(); // Não mostra botão se não puder entrar
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}\n';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
  }
}