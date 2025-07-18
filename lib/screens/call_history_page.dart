import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart'; // Importar AuthProvider

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  List<dynamic> _callHistory = []; // Alterado para List<dynamic>
  bool _isLoading = true;
  String? _currentUserId; // Para armazenar o ID do usuário logado

  @override
  void initState() {
    super.initState();
    _loadUserIdAndCallHistory();
  }

  Future<void> _loadUserIdAndCallHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.currentUser?.id; // Obter o ID do usuário logado
    await _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final voipService = Provider.of<VoIPService>(context, listen: false); // Corrigido para VoIPService
      final history = await voipService.getCallHistory();
      setState(() {
        _callHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading call history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Chamadas'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade900,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _callHistory.isEmpty
              ? _buildEmptyState()
              : _buildCallHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call,
            size: 80,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma chamada encontrada',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas chamadas aparecerão aqui',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      child: ListView.builder(
        itemCount: _callHistory.length,
        itemBuilder: (context, index) {
          final call = _callHistory[index];
          return _buildCallHistoryItem(call);
        },
      ),
    );
  }

  Widget _buildCallHistoryItem(dynamic call) {
    final isOutgoing = call['caller']['_id'] == _currentUserId;
    final contactName = isOutgoing 
        ? call['callee']['username'] 
        : call['caller']['username'];
    final duration = call['duration'] as int? ?? 0;
    final timestamp = call['startTime'] as String?; // Usar startTime
    final status = call['status'] as String? ?? 'completed';

    final isMissed = status == 'rejected' || (status == 'pending' && !isOutgoing); // Considerar 'pending' incoming como perdida
    final isCompleted = status == 'ended';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildCallIcon(!isOutgoing, isMissed),
        title: Text(
          contactName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getCallTypeText(!isOutgoing, status),
              style: TextStyle(
                color: isMissed ? Colors.red.shade300 : Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            if (timestamp != null)
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted && duration > 0)
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.blue),
              onPressed: () => _makeCall(call),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallIcon(bool isIncoming, bool isMissed) {
    IconData iconData;
    Color iconColor;

    if (isMissed) {
      iconData = isIncoming ? Icons.call_received : Icons.call_made;
      iconColor = Colors.red;
    } else {
      iconData = isIncoming ? Icons.call_received : Icons.call_made;
      iconColor = isIncoming ? Colors.green : Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withValues(alpha: 0.2),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _getCallTypeText(bool isIncoming, String status) {
    if (status == 'rejected') {
      return isIncoming ? 'Chamada perdida' : 'Chamada rejeitada';
    } else if (status == 'pending' && isIncoming) {
      return 'Chamada perdida'; // Chamada recebida não atendida
    }
    
    switch (status) {
      case 'accepted':
        return isIncoming ? 'Chamada recebida' : 'Chamada realizada';
      case 'ended':
        return isIncoming ? 'Chamada recebida' : 'Chamada realizada';
      default:
        return 'Chamada';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
      } else {
        return 'Agora';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _makeCall(dynamic call) {
    final contactId = call['callee']['_id'] == _currentUserId ? call['caller']['_id'] : call['callee']['_id'];
    final contactName = call['callee']['_id'] == _currentUserId ? call['caller']['username'] : call['callee']['username'];
    final roomName = call['roomName']; // Obter o roomName da chamada

    if (contactId != null && roomName != null) {
      // Iniciar a chamada (re-chamada)
      final voipService = Provider.of<VoIPService>(context, listen: false); // Corrigido para VoIPService

      // Usar argumentos nomeados conforme a assinatura em VoIPService
      voipService.initiateCall(targetId: contactId, displayName: contactName ?? 'Usuário');

      // A navegação para CallPage deve ser tratada pela VoIPService
      // ou por um listener que reaja ao início da chamada.
    }
  }
}


