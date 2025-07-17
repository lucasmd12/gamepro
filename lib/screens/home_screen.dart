import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/tabs/home_tab.dart';
import 'package:lucasbeatsfederacao/screens/chat/contextual_chat_screen.dart';
import 'package:lucasbeatsfederacao/screens/voip/contextual_voice_screen.dart';
import 'package:lucasbeatsfederacao/screens/exploration/federation_explorer_screen.dart';
import 'package:lucasbeatsfederacao/screens/settings_screen.dart';
import 'package:lucasbeatsfederacao/screens/invite_list_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:lucasbeatsfederacao/screens/instaclan_feed_screen.dart';
import 'package:lucasbeatsfederacao/screens/clan_wars_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/federation_management_screen.dart';
import 'package:lucasbeatsfederacao/screens/qrr_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late AudioPlayer _audioPlayer;

  List<Widget> _widgetOptions = [];

  final List<String> _backgroundImages = [
    'assets/images_png/backgrounds/bg_mercedes_forest.png',
    'assets/images_png/backgrounds/bg_bmw_smoke_01.png',
    'assets/images_png/backgrounds/bg_joker_smoke.png',
    'assets/images_png/backgrounds/bg_cards_dice.png',
    'assets/images_png/backgrounds/bg_audi_autumn.png',
    'assets/images_png/backgrounds/bg_mustang_autumn.png',
    'assets/images_png/backgrounds/bg_gtr_night.png',
    'assets/images_png/backgrounds/bg_bmw_smoke_02.png',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      setState(() {
        _widgetOptions = <Widget>[
          const HomeTab(),
          const FederationExplorerScreen(),
          // CORREÇÃO APLICADA AQUI:
          // Usamos o operador '??' para fornecer uma string vazia se federationId for nulo.
          FederationManagementScreen(federationId: currentUser?.federationId ?? ''),
          const ContextualChatScreen(chatContext: 'global'),
          const ContextualVoiceScreen(voiceContext: 'global'),
          const InstaClanFeedScreen(),
          const ClanWarsListScreen(),
          const QRRListScreen(),
          const SettingsScreen(),
        ];
      });
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    final transaction = Sentry.startTransaction(
      'requestPermissions',
      'permission_request',
      description: 'Requesting necessary permissions',
    );
    Logger.info("Requesting necessary permissions...");
    try {
      final notificationSpan = transaction.startChild(
        'requestNotificationPermission',
        description: 'Requesting notification permission',
      );
      PermissionStatus notificationStatus = await Permission.notification.request();
      notificationSpan.finish(status: SpanStatus.ok());

      if (notificationStatus.isGranted) {
        Logger.info("Notification permission granted.");
      } else if (notificationStatus.isDenied) {
        Logger.warning("Notification permission denied.");
      } else if (notificationStatus.isPermanentlyDenied) {
        Logger.error("Notification permission permanently denied.");
        _showSettingsDialog("Notificações");
      }

      final storageSpan = transaction.startChild(
        'requestStoragePermission',
        description: 'Requesting storage permission',
      );
      PermissionStatus storageStatus = await Permission.storage.request();
      storageSpan.finish(status: SpanStatus.ok());

      if (storageStatus.isGranted) {
        Logger.info("Storage permission granted.");
      } else if (storageStatus.isDenied) {
        Logger.warning("Storage permission denied.");
      } else if (storageStatus.isPermanentlyDenied) {
        Logger.error("Storage permission permanently denied.");
        _showSettingsDialog("Armazenamento");
      }

      final microphoneSpan = transaction.startChild(
        'requestMicrophonePermission',
        description: 'Requesting microphone permission',
      );
      PermissionStatus microphoneStatus = await Permission.microphone.request();
      microphoneSpan.finish(status: SpanStatus.ok());

      if (microphoneStatus.isGranted) {
        Logger.info("Microphone permission granted.");
      } else if (microphoneStatus.isDenied) {
        Logger.warning("Microphone permission denied.");
      } else if (microphoneStatus.isPermanentlyDenied) {
        Logger.error("Microphone permission permanently denied.");
        _showSettingsDialog("Microfone");
      }
      transaction.finish(status: SpanStatus.ok());
    } catch (e, stackTrace) {
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(e, stackTrace: stackTrace);
      Logger.error("Error requesting permissions", error: e, stackTrace: stackTrace);
    }
  }

  void _showSettingsDialog(String permissionName) {
     if (!mounted) return;
     showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Permissão Necessária"),
          content: Text("A permissão de $permissionName foi negada permanentemente. Por favor, habilite-a nas configurações do aplicativo para usar todas as funcionalidades."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Abrir Configurações"),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
  }

  Future<void> _initializeAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAsset('assets/audio/intro_music.mp3');
      _audioPlayer.play();
      Logger.info("Intro music started playing.");
    } catch (e, stackTrace) {
      Logger.error("Error loading or playing intro music", error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Logger.info("Switched to tab index: $index");
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final textTheme = Theme.of(context).textTheme;

    if (authProvider.authStatus == AuthStatus.unknown || authProvider.authService.isLoading) {
       return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
             valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      );
    }

    if (currentUser == null) {
       Logger.warning("HomeScreen build: User is null after authentication check. This shouldn't happen.");
       return Scaffold(
         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
         body: Center(child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text("Erro crítico ao carregar dados do usuário. Por favor, tente reiniciar o aplicativo.", textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
         )),
       );
    }

    IconData displayIcon = Icons.person;
    String displayText = currentUser.username ?? 'Usuário';

    if (currentUser.role == Role.admMaster) {
      displayIcon = Icons.admin_panel_settings;
      displayText = "ADM MASTER: ${currentUser.username ?? 'N/A'}";
    } else if (currentUser.clanName != null && currentUser.clanTag != null) {
      displayIcon = Icons.flag;
      displayText = "${currentUser.clanName} [${currentUser.clanTag}] ${currentUser.username ?? 'N/A'}";
      if (currentUser.federationTag != null) {
        displayText += " (${currentUser.federationTag})";
      }
    } else if (currentUser.federationName != null && currentUser.federationTag != null) {
      displayIcon = Icons.account_tree;
      displayText = "${currentUser.federationName} (${currentUser.federationTag}) ${currentUser.username ?? 'N/A'}";
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              child: Icon(displayIcon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
           IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notificações',
            onPressed: () {
              Logger.info("Notifications button pressed.");
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const InviteListScreen()),
              );
            },
          ),
        ],
        leading: IconButton(
          icon: StreamBuilder<PlayerState>(
            stream: _audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;
              if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering || !(_audioPlayer.playing)) {
                return const Icon(Icons.play_arrow);
              } else if (playing != true) {
                return const Icon(Icons.play_arrow);
              } else {
                return const Icon(Icons.pause);
              }
            },
          ),
          onPressed: () {
            if (_audioPlayer.playing) {
              _audioPlayer.pause();
            } else {
              _audioPlayer.play();
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImages[_selectedIndex % _backgroundImages.length]),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: IndexedStack(
           index: _selectedIndex,
           children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.travel_explore_outlined), activeIcon: Icon(Icons.travel_explore), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_outlined), activeIcon: Icon(Icons.group_work), label: 'Federação'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.call_outlined), activeIcon: Icon(Icons.call), label: 'Chamadas'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), activeIcon: Icon(Icons.photo_library), label: 'InstaClã'),
          BottomNavigationBarItem(icon: Icon(Icons.military_tech_outlined), activeIcon: Icon(Icons.military_tech), label: 'Guerras'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Config'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).primaryColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
