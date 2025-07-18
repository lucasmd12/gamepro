import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/user_model.dart'; // Import User model
import '../../services/auth_service.dart';
import '../../services/clan_service.dart'; // Service to get clan/channel data
import '../../providers/call_provider.dart'; // To join/leave voice calls
// VoIP service
import '../../utils/logger.dart';
import '../../models/channel_model.dart'; // Use Channel
// Voice call screen

class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key});
  
  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  ClanService? _clanService;
  AuthService? _authService;
  CallProvider? _callProvider;

  String? _currentVoiceChannelId;
  bool _isLoadingChannels = false;
  List<Channel> _voiceChannels = [];
  String? _errorLoadingChannels;
  
  // Controller para pull-to-refresh
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initServicesAndLoadData();
        _callProvider?.addListener(_updateCurrentChannelState);
      }
    });
  }

  void _initServicesAndLoadData() {
    if (!mounted) return;
    _authService = Provider.of<AuthService>(context, listen: false);
    _clanService = Provider.of<ClanService>(context, listen: false);
    _callProvider = Provider.of<CallProvider>(context, listen: false);
    _updateCurrentChannelState(); // Initial state
    _loadVoiceChannels(); // Load channels initially
  }

  @override
  void dispose() {
    _callProvider?.removeListener(_updateCurrentChannelState);
    _refreshController.dispose();
    super.dispose();
  }

  void _updateCurrentChannelState() {
    if (!mounted) return;
    final newChannelId = _callProvider?.currentChannelId;
    if (_currentVoiceChannelId != newChannelId) {
      setState(() {
        _currentVoiceChannelId = newChannelId;
        Logger.info("ChatListTab updated current channel ID: $_currentVoiceChannelId");
      });
    }
  }

  Future<void> _loadVoiceChannels() async {
    if (_isLoadingChannels || _clanService == null || _authService == null || !mounted) return;

    final User? currentUser = _authService!.currentUser;

    if (currentUser?.clanId == null) { // Usando clanId
      Logger.warning("Cannot load channels: User not in a clan.");
      if (mounted) {
        setState(() {
          _errorLoadingChannels = "Você não está em um clã para ver os canais.";
          _voiceChannels = [];
        });
      }
      return;
    }

    final String clanId = currentUser!.clanId!; // Usando clanId

    setState(() {
      _isLoadingChannels = true;
      _errorLoadingChannels = null;
    });

    try {
      final List<Channel> channels = await _clanService!.getClanChannels(clanId);

      if (mounted) {
        setState(() {
          _voiceChannels = channels;
        });
      }
      Logger.info("Loaded ${_voiceChannels.length} voice channels for clan $clanId.");
    } catch (e, s) {
      Logger.error("Erro ao carregar canais de voz", error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _errorLoadingChannels = "Erro ao carregar canais: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChannels = false;
        });
      }
    }
  }

  void _onRefresh() async {
    await _loadVoiceChannels();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // Implementar carregamento de mais canais se necessário
    _refreshController.loadComplete();
  }

  Future<void> _entrarNoCanal(String channelId, String channelName) async {
    if (_callProvider == null || !mounted) return;
    Logger.info("Attempting to join voice channel: $channelId ($channelName)");
    
    // Mostrar feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text("Entrando no canal $channelName..."),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    try {
      await _callProvider!.joinChannel(channelId);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text("Conectado ao canal $channelName"),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.error("Error joining channel $channelId from UI", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text("Erro ao entrar no canal: ${e.toString()}")),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sairDoCanal() async {
    if (_callProvider == null || !mounted) return;
    Logger.info("Attempting to leave current voice channel: $_currentVoiceChannelId");
    
    try {
      await _callProvider!.leaveChannel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.logout, color: Colors.orange),
                SizedBox(width: 8),
                Text("Desconectado do canal"),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.error("Error leaving channel $_currentVoiceChannelId from UI", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text("Erro ao sair do canal: ${e.toString()}")),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showChannelOptions(Channel channel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF212121),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              channel.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text("Informações do Canal", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Implementar tela de informações do canal
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text("Configurar Notificações", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Implementar configurações de notificação
              },
            ),
            if (channel.id == _currentVoiceChannelId)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Sair do Canal", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _sairDoCanal();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login, color: Colors.green),
                title: const Text("Entrar no Canal", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _entrarNoCanal(channel.id, channel.name);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingChannels) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFF44336)),
            SizedBox(height: 16),
            Text(
              "Carregando canais...",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorLoadingChannels != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorLoadingChannels!,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadVoiceChannels,
                icon: const Icon(Icons.refresh),
                label: const Text("Tentar Novamente"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_voiceChannels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.voice_chat,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                "Nenhum canal de voz encontrado",
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Seu clã ainda não possui canais de voz configurados.",
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadVoiceChannels,
                icon: const Icon(Icons.refresh),
                label: const Text("Atualizar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      enablePullDown: true,
      enablePullUp: false,
      header: const WaterDropMaterialHeader(
        backgroundColor: Color(0xFFF44336),
        color: Colors.white,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _voiceChannels.length,
        itemBuilder: (context, index) {
          final canal = _voiceChannels[index];
          final bool estouNesteCanal = canal.id == _currentVoiceChannelId;

          return Slidable(
            key: ValueKey(canal.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => _showChannelOptions(canal),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.settings,
                  label: 'Opções',
                ),
                if (!estouNesteCanal)
                  SlidableAction(
                    onPressed: (context) => _entrarNoCanal(canal.id, canal.name),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    icon: Icons.login,
                    label: 'Entrar',
                  )
                else
                  SlidableAction(
                    onPressed: (context) => _sairDoCanal(),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.logout,
                    label: 'Sair',
                  ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: estouNesteCanal 
                    ? const Color(0xFFF44336).withOpacity(0.2) 
                    : const Color(0xFF424242),
                borderRadius: BorderRadius.circular(12),
                border: estouNesteCanal 
                    ? Border.all(color: const Color(0xFFF44336), width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: estouNesteCanal 
                        ? const Color(0xFFF44336) 
                        : Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.headset_mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  canal.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: estouNesteCanal ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${canal.activeUsers.length} ${canal.activeUsers.length == 1 ? 'participante' : 'participantes'}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    if (canal.topic != null && canal.topic!.isNotEmpty)
                      Text(
                        'Tópico: ${canal.topic}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: estouNesteCanal
                    ? const Icon(Icons.volume_up, color: Colors.green, size: 20)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}