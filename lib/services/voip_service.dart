import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
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
  late AuthService _authService;
  late SignalingService _signalingService; // Adicionar SignalingService

  bool get isInCall => _isInCall;
  String? get currentRoomId => _currentRoomId;

  void init(SocketService socketService, AuthService authService, SignalingService signalingService) {
    _socketService = socketService;
    _authService = authService;
    _signalingService = signalingService; // Inicializar SignalingService
    _setupSocketListeners();
    _setupSignalingListeners(); // Configurar listeners do SignalingService
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
    _jitsiMeet.addListener(
      JitsiMeetingListener(
        onConferenceJoined: (url) {
          Logger.info("Jitsi Conference Joined: $url");
          _isInCall = true;
          _onCallStarted?.call(_currentRoomId ?? "");
          notifyListeners();
        },
        onConferenceTerminated: (url, error) {
          Logger.info("Jitsi Conference Terminated: $url, error: $error");
          endCall(); // Encerrar a chamada quando a conferência termina
        },
        onConferenceWillJoin: (url) {
          Logger.info("Jitsi Conference Will Join: $url");
        },
        onParticipantJoined: (participant) {
          Logger.info("Jitsi Participant Joined: ${participant.displayName}");
        },
        onParticipantLeft: (participant) {
          Logger.info("Jitsi Participant Left: ${participant.displayName}");
        },
        onReadyToClose: () {
          Logger.info("Jitsi Ready to Close");
        },
      ),
    );
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




  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final Uuid _uuid = const Uuid();




  // --- WebRTC P2P Methods ---

  Future<void> _initiateWebRTCCall({required String targetId, required String callId}) async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true, 'video': false
      });

      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          // Adicionar mais STUN/TURN servers se necessário
        ]
      }, {});

      _peerConnection!.addStream(_localStream!);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate != null) {
          _socketService.sendWebRTCSignal({
            'targetUserId': targetId,
            'signalType': 'iceCandidate',
            'signalData': candidate.toMap(),
          });
        }
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        _remoteStream = stream;
        Logger.info("Remote stream added");
        // TODO: Notificar UI para exibir o stream remoto (apenas áudio)
      };

      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });
      await _peerConnection!.setLocalDescription(offer);

      _socketService.sendWebRTCSignal({
        'targetUserId': targetId,
        'signalType': 'offer',
        'signalData': offer.toMap(),
      });

      Logger.info("WebRTC offer sent to $targetId");
    } catch (e, stackTrace) {
      Logger.error("Error initiating WebRTC call", error: e, stackTrace: stackTrace);
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    }
  }

  Future<void> _handleWebRTCSignal(Map<String, dynamic> signalData) async {
    final signalType = signalData['signalType'];
    final data = signalData['signalData'];
    final senderUserId = signalData['senderUserId'];

    if (_peerConnection == null) {
      // Se não há peerConnection, é uma oferta inicial
      await _initiateWebRTCCall(targetId: senderUserId, callId: _uuid.v4()); // Criar um callId temporário para o setup
    }

    switch (signalType) {
      case 'offer':
        final offer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(offer);
        final answer = await _peerConnection!.createAnswer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': false,
        });
        await _peerConnection!.setLocalDescription(answer);
        _socketService.sendWebRTCSignal({
          'targetUserId': senderUserId,
          'signalType': 'answer',
          'signalData': answer.toMap(),
        });
        Logger.info("WebRTC answer sent to $senderUserId");
        break;
      case 'answer':
        final answer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(answer);
        Logger.info("WebRTC answer received from $senderUserId");
        break;
      case 'iceCandidate':
        final candidate = RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
        Logger.info("WebRTC ICE candidate received from $senderUserId");
        break;
      default:
        Logger.warn("Unknown WebRTC signal type: $signalType");
    }
  }

  Future<void> _closeWebRTCCall() async {
    _peerConnection?.close();
    _peerConnection = null;
    _localStream?.dispose();
    _localStream = null;
    _remoteStream?.dispose();
    _remoteStream = null;
    Logger.info("WebRTC call closed");
  }

  // Modificar _setupSocketListeners para lidar com sinais WebRTC
  @override
  void _setupSocketListeners() {
    super._setupSocketListeners(); // Chamar o método pai para manter listeners existentes
    _socketService.webrtcSignalStream.listen((signalData) {
      Logger.info("Received WebRTC signal via Socket: $signalData");
      _handleWebRTCSignal(signalData);
    });
  }

  // Modificar endCall para fechar também a conexão WebRTC
  @override
  Future<void> endCall() async {
    await _closeWebRTCCall();
    super.endCall();
  }

  // Modificar initiateCall para diferenciar Jitsi de WebRTC P2P
  @override
  Future<void> initiateCall({required String targetId, required String displayName, bool isVideoCall = false}) async {
    if (isVideoCall) {
      Logger.warn("Video calls are currently inhibited. Initiating audio-only call.");
      // return; // Ou lançar um erro se não quiser permitir de forma alguma
    }

    Logger.info("Initiating call to $targetId");
    try {
      final token = await _authService.token;
      if (token == null) {
        throw Exception("Token de autenticação não encontrado.");
      }

      // Lógica para decidir se é Jitsi ou WebRTC P2P
      // Por enquanto, vamos assumir que chamadas 1x1 são WebRTC P2P
      // e chamadas de clã/federação são Jitsi
      // Para 1x1, o Backend ainda precisa criar o registro da chamada
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/voip/initiate-call"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "receiverId": targetId, // Backend espera receiverId
          "callType": "voice", // Sempre voz, conforme a observação
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Logger.info("Call initiation successful: $responseData");
        final callId = responseData['callId'];
        // Iniciar a conexão WebRTC P2P após o Backend registrar a chamada
        await _initiateWebRTCCall(targetId: targetId, callId: callId);
      } else {
        Logger.error("Failed to initiate call: ${response.statusCode} ${response.body}");
        throw Exception("Falha ao iniciar chamada: ${response.body}");
      }
    } catch (e, stackTrace) {
      Logger.error("Error initiating call: $e", stackTrace: stackTrace);
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    }
  }

  // Modificar acceptCall para lidar com WebRTC P2P
  @override
  Future<void> acceptCall({required String callId, required String roomId, required String displayName, bool isVideoCall = false}) async {
    if (isVideoCall) {
      Logger.warn("Video calls are currently inhibited. Accepting as audio-only call.");
    }

    Logger.info("Accepting call for room $roomId");
    try {
      final token = await _authService.token;
      if (token == null) {
        throw Exception("Token de autenticação não encontrado.");
      }

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/voip/accept-call"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "callId": callId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Logger.info("Call acceptance successful: $responseData");
        // Se for uma chamada Jitsi, iniciar Jitsi
        if (responseData['roomName'] != null && responseData['jitsiToken'] != null) {
          await startVoiceCall(roomId: responseData['roomName'], displayName: displayName, token: responseData['jitsiToken'], isAudioOnly: true);
        } else {
          // Se for WebRTC P2P, o _handleWebRTCSignal já deve ter iniciado o peerConnection
          // Apenas garantir que o estado da chamada seja atualizado
          _isInCall = true;
          _currentRoomId = callId; // Usar o callId como roomId para P2P
          _onCallStarted?.call(callId);
          notifyListeners();
          Logger.info("WebRTC P2P call accepted.");
        }
      } else {
        Logger.error("Failed to accept call: ${response.statusCode} ${response.body}");
        throw Exception("Falha ao aceitar chamada: ${response.body}");
      }
    } catch (e, stackTrace) {
      Logger.error("Error accepting call: $e", stackTrace: stackTrace);
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      rethrow;
    }
  }

  // Modificar startVoiceCall para inibir vídeo no Jitsi
  @override
  Future<void> startVoiceCall({
    required String roomId,
    required String displayName,
    String? serverUrl,
    String? token,
    bool isAudioOnly = true, // Forçar true para inibir vídeo
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
          'startWithVideoMuted': true, // Forçar vídeo mudo
          'requireDisplayName': true,
          'enableWelcomePage': false,
          'enableClosePage': false,
          'prejoinPageEnabled': false,
          'enableInsecureRoomNameWarning': false
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
          'video-mute.enabled': true, // Garantir que o botão de vídeo mudo esteja disponível
          'video-share.enabled': false, // Desabilitar compartilhamento de vídeo
          'screen-sharing.enabled': true, // Habilitar compartilhamento de tela
        },
        userInfo: JitsiMeetUserInfo(displayName: displayName),
      );

      await _jitsiMeet.join(options);
      _isInCall = true;
      _onCallStarted?.call(roomId);
      notifyListeners();
      Logger.info("Voice call started for room: $roomId");
    } catch (e, stackTrace) {
      _currentRoomId = null;
      Logger.error('Failed to start voice call: $e', stackTrace: stackTrace);
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
      throw Exception('Falha ao iniciar chamada de voz: $e');
    }
  }

  // Remover startVideoCall, pois o vídeo está inibido
  @override
  Future<void> startVideoCall({
    required String roomId,
    required String displayName,
    String? serverUrl,
    String? token,
  }) async {
    Logger.warn("startVideoCall foi chamado, mas chamadas de vídeo estão inibidas. Iniciando como áudio-apenas.");
    await startVoiceCall(
      roomId: roomId,
      displayName: displayName,
      serverUrl: serverUrl,
      token: token,
      isAudioOnly: true,
    );
  }

  // Modificar joinJitsiMeeting para inibir vídeo
  @override
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
          'startWithVideoMuted': true, // Forçar vídeo mudo
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
      Logger.error('Erro ao entrar na reunião Jitsi: $error', stackTrace: stackTrace);
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      rethrow;
    }
  }

  // Remover toggleVideo, pois o vídeo está inibido
  @override
  Future<void> toggleVideo() async {
    Logger.warn("toggleVideo foi chamado, mas chamadas de vídeo estão inibidas.");
    // Não faz nada ou lança um erro, dependendo da necessidade
  }

  // Adicionar método para obter o stream de áudio local
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  // Adicionar dispose para WebRTC
  @override
  void dispose() {
    _closeWebRTCCall(); // Fechar conexão WebRTC ao descartar o serviço
    super.dispose();
  }






  void _setupSignalingListeners() {
    _signalingService.onRemoteSdp = (RTCSessionDescription sdp) {
      _peerConnection?.setRemoteDescription(sdp);
      Logger.info("Remote SDP set from SignalingService.");
    };

    _signalingService.onRemoteIceCandidate = (RTCIceCandidate candidate) {
      _peerConnection?.addCandidate(candidate);
      Logger.info("Remote ICE candidate added from SignalingService.");
    };
  }


