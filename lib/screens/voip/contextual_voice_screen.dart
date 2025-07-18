import 'package:flutter/material.dart';

class ContextualVoiceScreen extends StatefulWidget {
  final String voiceContext; // e.g., 'global', 'federation_id', 'clan_id'

  const ContextualVoiceScreen({super.key, required this.voiceContext});

  @override
  State<ContextualVoiceScreen> createState() => _ContextualVoiceScreenState();
}

class _ContextualVoiceScreenState extends State<ContextualVoiceScreen> {
  bool _isMuted = false;
  bool _isDeafened = false;
  bool _isConnected = false;
  List<Map<String, dynamic>> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  void _loadParticipants() {
    // Simulando participantes para demonstração
    setState(() {
      _participants = [
        {
          'id': '1',
          'username': 'lucasg',
          'isMuted': false,
          'isDeafened': false,
          'isSpeaking': true,
        },
        {
          'id': '2',
          'username': 'admin',
          'isMuted': true,
          'isDeafened': false,
          'isSpeaking': false,
        },
      ];
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleDeafen() {
    setState(() {
      _isDeafened = !_isDeafened;
      if (_isDeafened) {
        _isMuted = true; // Deafen automatically mutes
      }
    });
  }

  void _toggleConnection() {
    setState(() {
      _isConnected = !_isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Voz: ${widget.voiceContext == 'global' ? 'Global' : widget.voiceContext}'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Cabeçalho do contexto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[800],
            child: Text(
              'Conteúdo da Tela de Voz Contextual para: ${widget.voiceContext}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Status da conexão
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isConnected ? Colors.green[800] : Colors.red[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Conectado ao canal de voz' : 'Desconectado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Lista de participantes
          Expanded(
            child: _isConnected
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _participants.length,
                    itemBuilder: (context, index) {
                      final participant = _participants[index];
                      return _buildParticipantCard(participant);
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.voice_over_off,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Conecte-se ao canal de voz para ver os participantes',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),

          // Controles de voz
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botão de conectar/desconectar
                _buildControlButton(
                  icon: _isConnected ? Icons.call_end : Icons.call,
                  label: _isConnected ? 'Desconectar' : 'Conectar',
                  color: _isConnected ? Colors.red : Colors.green,
                  onPressed: _toggleConnection,
                ),

                // Botão de mute
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Desmutado' : 'Mutado',
                  color: _isMuted ? Colors.red : Colors.grey,
                  onPressed: _isConnected ? _toggleMute : null,
                ),

                // Botão de deafen
                _buildControlButton(
                  icon: _isDeafened ? Icons.hearing_disabled : Icons.hearing,
                  label: _isDeafened ? 'Ensurdecido' : 'Ouvindo',
                  color: _isDeafened ? Colors.red : Colors.grey,
                  onPressed: _isConnected ? _toggleDeafen : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant) {
    final isSpeaking = participant['isSpeaking'] ?? false;
    final isMuted = participant['isMuted'] ?? false;
    final isDeafened = participant['isDeafened'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: isSpeaking
            ? Border.all(color: Colors.green, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Avatar do participante
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isSpeaking ? Colors.green : Colors.blue,
                child: Text(
                  participant['username'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isSpeaking)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Nome do participante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant['username'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSpeaking)
                  Text(
                    'Falando...',
                    style: TextStyle(
                      color: Colors.green[300],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Ícones de status
          Row(
            children: [
              if (isMuted)
                Icon(
                  Icons.mic_off,
                  color: Colors.red[300],
                  size: 20,
                ),
              if (isDeafened) ...[
                if (isMuted) const SizedBox(width: 8),
                Icon(
                  Icons.hearing_disabled,
                  color: Colors.red[300],
                  size: 20,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: onPressed != null ? color : Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white : Colors.grey[500],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

