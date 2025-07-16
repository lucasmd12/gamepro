import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // 👈 ADICIONADO
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Import Screens
import 'screens/animation_showcase_screen.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/call_page.dart';
import 'screens/clan_management_screen.dart';
import 'screens/call_history_page.dart';
import 'screens/call_contacts_screen.dart';
import 'screens/qrr_create_screen.dart';
import 'screens/qrr_edit_screen.dart';
import 'screens/qrr_participants_screen.dart';
import 'screens/admin_panel_screen.dart'; // Import the admin panel screen

// Import Services, Providers and Models
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/federation_service.dart';
import 'services/clan_service.dart';
import 'services/socket_service.dart';
import 'services/chat_service.dart';
import 'services/signaling_service.dart';
import 'services/notification_service.dart';
import 'services/mission_service.dart';
import 'services/firebase_service.dart';
import 'services/qrr_service.dart';
import 'services/user_service.dart'; // Importando UserService
import 'services/upload_service.dart'; // Importando UploadService
import 'services/post_service.dart'; // Importando PostService
import 'services/voip_service.dart';
import 'services/clan_war_service.dart'; // Importando ClanWarService
import 'models/qrr_model.dart';
import 'models/role_model.dart'; // Import Role enum
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/call_provider.dart';
import 'providers/mission_provider.dart';
import 'utils/logger.dart';
import 'utils/theme_constants.dart';
import 'widgets/app_lifecycle_reactor.dart';
import 'widgets/incoming_call_overlay.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 👇 ATIVA O APP CHECK COM TOKEN DE DEPURAÇÃO
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  await dotenv.load(fileName: ".env");

  final packageInfo = await PackageInfo.fromPlatform();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env["SENTRY_DSN"];
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
      options.debug = !kReleaseMode;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.release = 'lucasbeatsfederacao@${packageInfo.version}+${packageInfo.buildNumber}';

      FlutterError.onError = (details) {
        Sentry.captureException(details.exception, stackTrace: details.stack);
        Logger.error('Flutter Error:', error: details.exception, stackTrace: details.stack);
        FirebaseCrashlytics.instance.recordFlutterError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        Sentry.captureException(error, stackTrace: stack);
        Logger.error('Platform Error:', error: error, stackTrace: stack);
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    },
    appRunner: () async {
      Logger.info("App Initialization Started.");

      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        Logger.info('Screen orientation set to portrait.');
      } catch (e, stackTrace) {
        Logger.error('Failed to set screen orientation', error: e, stackTrace: stackTrace);
        await Sentry.captureException(e, stackTrace: stackTrace);
        FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      }

      Logger.info("Running FEDERACAOMAD App.");
      try {
        runApp(const FEDERACAOMADApp());
      } catch (e, stackTrace) {
        Logger.error("Error during app initialization or running FEDERACAOMAD App", error: e, stackTrace: stackTrace);
        FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: true);
      }
    },
  );
}

class FEDERACAOMADApp extends StatelessWidget {
  const FEDERACAOMADApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.info("Building FEDERACAOMADApp Widget.");

    final apiService = ApiService();
    final authService = AuthService();
    final socketService = SocketService();
    final signalingService = SignalingService(socketService);
    final missionService = MissionService(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<UserService>(create: (context) => UserService(apiService)),
        Provider<UploadService>(create: (_) => UploadService()),
        Provider<SocketService>.value(value: socketService),
        ChangeNotifierProvider<SignalingService>.value(value: SignalingService(socketService)),
        Provider<PostService>(create: (context) => PostService(apiService)),
        Provider<ClanWarService>(create: (context) => ClanWarService(apiService)),
        ChangeNotifierProvider<FederationService>(create: (context) => FederationService(apiService)),
        ChangeNotifierProvider<ClanService>(create: (context) => ClanService(apiService, authService)),
        Provider<MissionService>.value(value: missionService),
        ChangeNotifierProvider<NotificationService>(create: (context) => NotificationService()),
        ChangeNotifierProvider<VoIPService>(create: (context) {
          final voipService = VoIPService();
          final socketService = context.read<SocketService>();
          final authService = context.read<AuthService>();
          voipService.init(socketService, authService);
          voipService.initialize(); // Initialize Jitsi listeners and permissions
          return voipService;
        }),
        ChangeNotifierProvider<FirebaseService>(create: (context) => FirebaseService(context.read<ApiService>())),
        ChangeNotifierProvider<ChatService>(create: (context) => ChatService(
          firebaseService: context.read<FirebaseService>(),
          authService: context.read<AuthService>(),
          socketService: context.read<SocketService>(),
          uploadService: context.read<UploadService>()))),        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<SocketService>(),
            context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<CallProvider>(
          create: (context) => CallProvider(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider<MissionProvider>(
          create: (context) => MissionProvider(context.read<MissionService>()),
        ),
        ChangeNotifierProvider<QRRService>(create: (context) => QRRService(context.read<ApiService>())),
      ],
      child: AppLifecycleReactor(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'FEDERACAOMAD',
          debugShowCheckedModeBanner: false,
          theme: ThemeConstants.darkTheme,
          home: IncomingCallManager(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.authStatus == AuthStatus.unknown) {
                  return const SplashScreen();
                } else if (authProvider.authStatus == AuthStatus.authenticated) {
                  // Check user role after authentication
                  if (authProvider.currentUser?.role == Role.admMaster) {
                    return const AdminPanelScreen();
                  }
                  return const HomeScreen(); // Default to HomeScreen for other roles
                } else {
                  return const LoginScreen();
                }
              },
            ),
          ),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/call': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final roomName = args?['roomName'] ?? 'default_room';
              final contactName = args?['contactName'];
              final contactId = args?['contactId'];
              final isIncomingCall = args?['isIncomingCall'] ?? false;

              // Passar argumentos EXCLUSIVAMENTE como nomeados para o construtor CallPage
              return CallPage(
                roomName: roomName,
                contactName: contactName,
                contactId: contactId,
              );
            },
            '/call-history': (context) => const CallHistoryPage(),
            '/call-contacts': (context) => const CallContactsScreen(),
            '/clan-management': (context) {
              final String? clanId = ModalRoute.of(context)?.settings.arguments as String?;
              if (clanId != null) {
                return ClanManagementScreen(clanId: clanId);
              } else {
                return Scaffold(
                  appBar: AppBar(title: const Text('Erro')),
                  body: const Center(child: Text('ID do Clã não fornecido.')),
                );
              }
            },
            '/qrr-create': (context) => const QRRCreateScreen(),
            '/qrr-edit': (context) {
              final qrr = ModalRoute.of(context)?.settings.arguments as QRRModel?;
              if (qrr != null) {
                return QRREditScreen(qrr: qrr);
              } else {
                return Scaffold(
                  appBar: AppBar(title: const Text('Erro')),
                  body: const Center(child: Text('QRR não fornecida para edição.')),
                );
              }
            },
            '/qrr-participants': (context) {
              final qrr = ModalRoute.of(context)?.settings.arguments as QRRModel?;
              if (qrr != null) {
                return QRRParticipantsScreen(qrr: qrr);
              } else {
                return Scaffold(
                  appBar: AppBar(title: const Text('Erro')),
                  body: const Center(child: Text('QRR não fornecida para participantes.')),
                );
              }
            },
            '/animation-showcase': (context) => const AnimationShowcaseScreen(),
          },
        ),
      ),
    );
  }
}

