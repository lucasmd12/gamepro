import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import '../models/call_model.dart';
import '../models/call_history_model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'socket_service.dart'; // Importar SocketService

class VoIPService extends ChangeNotifier {
  static final VoIPService _instance = VoIPService._internal();
  factory VoIPService() => _instance;
  VoIPService._internal();

  final JitsiMeet _jitsiMeet = JitsiMeet();
  bool _isInCall = false;
  String? _currentRoomId;
  Function(String)? _onCallEnded;
  Function(String)? _onCallStarted;

  late SocketService _socketService;
  late AuthService _authService; // Adicionar AuthService

  bool get isInCall => _isInCall;
  String? get currentRoomId => _currentRoomId;

  void init(SocketService socketService, AuthService authService) {
    _socketService = socketService;
    _authService = authService; // Inicializar AuthService
    _setupSocketListeners();
  }

  // Configurar callbacks
  void setCallbacks({
    Function(String)? onCallEnded,
    Function(String)? onCallStarted,
  }) {
    _onCallEnded = onCallEnded;
    _onCallStarted = onCallStarted;
  }

  // Inicializar o serviço
  Future<void> initialize() async {
    try {
      await _requestPermissions();
      _setupJitsiListeners();
      Logger.info("VoIP Service initialized successfully");
    } catch (e, stackTrace) {
      Logger.error("Failed to initialize VoIP Service", error: e, stackTrace: stackTrace);
      FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: true);
      throw Exception("Falha ao inicializar serviço de VoIP: $e");
    }
  }

  // Solicitar permissões
  Future<void> _requestPermissions() async {
    final permissions = [Permission.camera, Permission.microphone];
    for (final permission in permissions) {
      final status = await permission.request();
      if (status != PermissionStatus.granted) {
        throw Exception("Permissão ${permission.toString()} não concedida");
      }
    }
  }

  void _setupJitsiListeners() {
    Logger.info("Jitsi listeners configured");
  }

  void _setupSocketListeners() {
    _socketService.incomingCallStream.listen((callData) {
      Logger.info("Received incoming call via Socket: $callData");
      // Aqui você pode disparar uma notificação ou UI para o usuário
      // Ex: showIncomingCallNotification(callData);
    });

    _socketService.callAcceptedStream.listen((callData) {
      Logger.info("Call accepted via Socket: $callData");
      // Lógica para iniciar a chamada Jitsi quando aceita
      // Ex: startVoiceCall(roomId: callData['roomId'], displayName: callData['displayName'], token: callData['token']);
    });

    _socketService.callRejectedStream.listen((callData) {
      Logger.info("Call rejected via Socket: $callData");
      // Lógica para notificar o chamador que a chamada foi rejeitada
    });

    _socketService.callEndedStream.listen((callData) {
      Logger.info("Call ended via Socket: $callData");
      // Lógica para encerrar a chamada Jitsi
      endCall();
    });
  }

  // Iniciar chamada de voz
  Future<void> startVoiceCall({
    required String roomId,
    required String displayName,
    String? serverUrl,
    String? token,
    bool isAudioOnly = true,
  }) async {
    try {
      if (_isInCall) throw Exception("Já existe uma chamada em andamento");

      _currentRoomId = roomId;

      final options = JitsiMeetConferenceOptions(
        serverURL: serverUrl ?? 'https://meet.jit.si',
        room: roomId,
        token: token,
        configOverrides: {
          'startWithAudioMuted': false,
          'startWithVideoMuted': isAudioOnly,
          'requireDisplayName': true,
          'enableWelcomePage': false,
          'enableClosePage': false,
          'prejoinPageEnabled': false,
          'enableInsecureRoomNameWarning': false,
          'toolbarButtons': [
            'microphone',
            if (!isAudioOnly) 'camera',
            'hangup',
            'chat',
            'participants-pane',
            'settings',
          ],
        },
        featureFlags: {
          'unsaferoomwarning.enabled': false,
          'security-options.enabled': false,
          'invite.enabled': false,
          'meeting-name.enabled': false,
          'calendar.enabled': false,
          'recording.enabled': false,
          'live-streaming.enabled': false,
          'tile-view.enabled': true,
          'pip.enabled': true,
          'toolbox.alwaysVisible': false,
          'filmstrip.enabled': true,
          'add-people.enabled': false,
          'server-url-change.enabled': false,
          'chat.enabled': true,
          'raise-hand.enabled': true,
          'kick-out.enabled': false,
          'lobby-mode.enabled': false,
          'notifications.enabled': true,
          'meeting-password.enabled': false,
          'close-captions.enabled': false,
          'reactions.enabled': true,
        },
        userInfo: JitsiMeetUserInfo(displayName: displayName),
      );

      await _jitsiMeet.join(options);
      _isInCall = true;
      _onCallStarted?.call(roomId);
      notifyListeners();
      Logger.info("Voice call started for room: $roomId");
    } catch (e) {
      _currentRoomId = null;
      Logger.error('Failed to start voice call: $e');
      throw Exception('Falha ao iniciar chamada de voz: $e');
    }
  }

  // Iniciar chamada de vídeo
  Future<void> startVideoCall({
    required String roomId,
    required String displayName,
    String? serverUrl,
    String? token,
  }) async {
    await startVoiceCall(
      roomId: roomId,
      displayName: displayName,
      serverUrl: serverUrl,
      token: token,
      isAudioOnly: false,
    );
  }

  // Entrar manualmente numa reunião Jitsi
  Future<void> joinJitsiMeeting({
    required String roomName,
    required String userDisplayName,
    String? userAvatarUrl,
    String? password,
  }) async {
    try {
      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: roomName,
        configOverrides: {
          'startWithVideoMuted': false,
          'startWithAudioMuted': false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: userDisplayName,
          avatar: userAvatarUrl,
        ),
      );

      await _jitsiMeet.join(options);
      _isInCall = true;
      _currentRoomId = roomName;
      notifyListeners();
      Logger.info("Joined Jitsi meeting: $roomName");
    } catch (error, stackTrace) {
      Logger.error('Erro ao entrar na reunião Jitsi: $error');
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      rethrow;
    }
  }

  // Encerrar chamada
  Future<void> endCall() async {
    try {
      if (_isInCall) {
        await _jitsiMeet.hangUp();
        Logger.info('Call ended');
        _onCallEnded?.call(_currentRoomId ?? '');
      }
    } catch (e) {
      Logger.error('Failed to end call: $e');
    } finally {
      _isInCall = false;
      _currentRoomId = null;
      notifyListeners();
    }
  }

  // Gerar ID único
  static String generateRoomId({required String prefix, String? entityId}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return entityId != null ? '${prefix}_${entityId}_$random' : '${prefix}_$random';
  }

  // Validar nome de sala
  static bool isValidRoomName(String roomName) {
    final regex = RegExp(r'^[a-zA-Z0-9_-]+$');
    return regex.hasMatch(roomName) && roomName.length >= 3 && roomName.length <= 50;
  }

  // Simular dados
  Call? currentCall;
  bool isCalling = false;
  Function(String)? onCallStateChanged;

  // Toggle mute
  void toggleMute() {
    Logger.info('Toggle mute');
  }

  Future<void> toggleAudio() async {
    try {
      Logger.info('Toggle audio');
    } catch (e) {
      Logger.error('Failed to toggle audio: $e');
      rethrow;
    }
  }

  Future<void> toggleVideo() async {
    try {
      Logger.info('Toggle video');
    } catch (e) {
      Logger.error('Failed to toggle video: $e');
      rethrow;
    }
  }

  Future<void> switchCamera() async {
    Logger.info('Switching camera');
  }

  // Implementação real do histórico de chamadas
  Future<List<CallHistoryModel>> getCallHistory({String? clanId, String? federationId}) async {
    try {
      final token = await AuthService().token;
      if (token == null) {
        throw Exception('Token de autenticação não encontrado.');
      }

      String url = '${ApiConfig.baseUrl}/api/voip/call-history';
      Map<String, String> queryParams = {};
      if (clanId != null) {
        queryParams['clanId'] = clanId;
      }
      if (federationId != null) {
        queryParams['federationId'] = federationId;
      }

      if (queryParams.isNotEmpty) {
        url += '?' + Uri(queryParameters: queryParams).query;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => CallHistoryModel.fromMap(item)).toList();
      } else {
        Logger.error('Falha ao carregar histórico de chamadas: ${response.statusCode} ${response.body}');
        throw Exception('Falha ao carregar histórico de chamadas: ${response.body}');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao obter histórico de chamadas', error: e, stackTrace: stackTrace);
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      return [];
    }
  }

  String formatCallDuration() {
    return '00:00';
  }

  @override
  void dispose() {
    _isInCall = false;
    _currentRoomId = null;
    _onCallEnded = null;
    _onCallStarted = null;
    Logger.info('VoIP service disposed');
    super.dispose();
  }

  // Métodos para iniciar, aceitar e rejeitar chamadas
  Future<void> initiateCall({required String targetId, required String displayName, bool isVideoCall = false}) async {
    Logger.info("Initiating call to $targetId");
    try {
      final token = await AuthService().token;
      if (token == null) {
        throw Exception('Token de autenticação não encontrado.');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/voip/initiate-call'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'targetUserId': targetId,
          'isVideoCall': isVideoCall,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Logger.info("Call initiation successful: $responseData");
        // O Backend deve emitir o evento 'incoming_call' para o targetUserId via Socket.IO
      } else {
        Logger.error('Failed to initiate call: ${response.statusCode} ${response.body}');
        throw Exception('Falha ao iniciar chamada: ${response.body}');
      }
    } catch (e) {
      Logger.error("Error initiating call: $e");
      rethrow;
    }
  }

  Future<void> acceptCall({required String callId, required String roomId, required String displayName, bool isVideoCall = false}) async {
    Logger.info("Accepting call for room $roomId");
    try {
      final token = await AuthService().token;
      if (token == null) {
        throw Exception('Token de autenticação não encontrado.');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/voip/accept-call'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'callId': callId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Logger.info("Call acceptance successful: $responseData");
        await startVoiceCall(roomId: roomId, displayName: displayName, token: responseData['jitsiToken'], isAudioOnly: !isVideoCall);
      } else {
        Logger.error('Failed to accept call: ${response.statusCode} ${response.body}');
        throw Exception('Falha ao aceitar chamada: ${response.body}');
      }
    } catch (e) {
      Logger.error("Error accepting call: $e");
      rethrow;
    }
  }

  Future<void> rejectCall({required String callId}) async {
    Logger.info("Rejecting call for callId $callId");
    try {
      final token = await AuthService().token;
      if (token == null) {
        throw Exception('Token de autenticação não encontrado.');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/voip/reject-call'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'callId': callId,
        }),
      );

      if (response.statusCode == 200) {
        Logger.info("Call rejection successful.");
      } else {
        Logger.error('Failed to reject call: ${response.statusCode} ${response.body}');
        throw Exception('Falha ao rejeitar chamada: ${response.body}');
      }
    } catch (e) {
      Logger.error("Error rejecting call: $e");
      rethrow;
    }
  }

  Future<void> endCallApi({required String callId}) async {
    Logger.info("Ending call for callId $callId");
    try {
      final token = await AuthService().token;
      if (token == null) {
        throw Exception('Token de autenticação não encontrado.');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/voip/end-call'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'callId': callId,
        }),
      );

      if (response.statusCode == 200) {
        Logger.info("Call end successful.");
      } else {
        Logger.error('Failed to end call: ${response.statusCode} ${response.body}');
        throw Exception('Falha ao encerrar chamada: ${response.body}');
      }
    } catch (e) {
      Logger.error("Error ending call: $e");
      rethrow;
    }
  }
}


