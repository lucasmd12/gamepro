import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/models/call_history_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/screens/call_page.dart';

class CallHistoryFeedWidget extends StatefulWidget {
  final String? clanId;
  final String? federationId;

  const CallHistoryFeedWidget({super.key, this.clanId, this.federationId});

  @override
  State<CallHistoryFeedWidget> createState() => _CallHistoryFeedWidgetState();
}

class _CallHistoryFeedWidgetState extends State<CallHistoryFeedWidget> {
  List<CallHistoryModel> _callHistory = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndCallHistory();
  }

  Future<void> _loadUserIdAndCallHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _currentUserId = authProvider.currentUser?.id;
      });
    }
    await _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final voipService = Provider.of<VoIPService>(context, listen: false);
      final history = await voipService.getCallHistory(
        clanId: widget.clanId,
        federationId: widget.federationId,
      );
      if (mounted) {
        setState(() {
          _callHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error("Error loading call history: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _callHistory.isEmpty
            ? _buildEmptyState()
            : _buildCallHistoryList();
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
            'Nenhuma atividade de chamada encontrada',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'As chamadas do clã/federação aparecerão aqui',
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

  Widget _buildCallHistoryItem(CallHistoryModel call) {
    final isOutgoing = call.callerId == _currentUserId;
    final contactName = isOutgoing
        ? call.receiverUsername ?? 'Usuário Desconhecido'
        : call.callerUsername ?? 'Usuário Desconhecido';
    final duration = call.duration ?? 0;
    final timestamp = call.startTime;
    final status = call.status;

    final isMissed = status == 'rejected' || (status == 'pending' && !isOutgoing);
    final isCompleted = status == 'completed';

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
        color: iconColor.withOpacity(0.2),
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
      return 'Chamada perdida';
    }

    switch (status) {
      case 'completed':
        return isIncoming ? 'Chamada recebida' : 'Chamada realizada';
      case 'missed':
        return 'Chamada perdida';
      case 'cancelled':
        return 'Chamada cancelada';
      case 'failed':
        return 'Chamada falhou';
      default:
        return 'Chamada';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Agora';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _makeCall(CallHistoryModel call) {
    final contactId = call.callerId == _currentUserId ? call.receiverId : call.callerId;
    final contactName = call.callerId == _currentUserId ? call.receiverUsername : call.callerUsername;
    final roomName = call.roomId;

    final voipService = Provider.of<VoIPService>(context, listen: false);
    
    voipService.startVoiceCall(
      roomId: roomName,
      displayName: contactName ?? 'Usuário',
    );

    // CORREÇÃO APLICADA AQUI:
    // O parâmetro 'isIncomingCall' foi removido da chamada do construtor.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          contactId: contactId,
          contactName: contactName ?? 'Usuário',
          roomName: roomName,
        ),
      ),
    );
  }
}
