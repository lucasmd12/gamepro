import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
// ✅ AÇÃO 1: IMPORT CORRETO PARA O 'jitsi_meet_wrapper'
import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../models/call_history_model.dart';
import '../models/call_model.dart';
import '../utils/logger.dart';
import 'auth_service.dart';
import 'signaling_service.dart';
import 'socket_service.dart';

class VoIPService extends ChangeNotifier {
  VoIPService();

  // --- DEPENDÊNCIAS ---
  late SocketService _socketService;
  late AuthService _authService;
  late SignalingService _signalingService;

  // --- ESTADO DO JITSI ---
  // Não há instância _jitsiMeet, pois o wrapper usa métodos estáticos.

  // --- ESTADO DO WEBRTC ---
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? get localStream => _localStream;
  MediaStream? _remoteStream;
  MediaStream? get remoteStream => _remoteStream;

  // --- ESTADO GERAL DA CHAMADA ---
  bool _isInCall = false;
  bool get isInCall => _isInCall;

  bool _isCalling = false;
  bool get isCalling => _isCalling;

  String? _currentRoomId;
  String? get currentRoomId => _currentRoomId;

  Call? _currentCall;
  Call? get currentCall => _currentCall;

  // --- CALLBACKS E HELPERS ---
  Function(String)? _onCallEnded;
  Function(String)? _onCallStarted;
  Function(String)? onCallStateChanged;
  final Uuid _uuid = const Uuid();

  void init(
      SocketService socketService,
      AuthService authService,
      SignalingService signalingService) {
    _socketService = socketService;
    _authService = authService;
    _signalingService = signalingService;
    _setupSocketListeners();
    _setupSignalingListeners();
    // Não há _setupJitsiListeners, pois o wrapper não tem um sistema de listeners persistente.
  }

  Future<void> initialize() async {
    try {
      await _requestPermissions();
      Logger.info("VoIP Service initialized successfully");
    } catch (e, stackTrace) {
      Logger.error("Failed to initialize VoIP Service", error: e, stackTrace: stackTrace);
      FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: true);
      throw Exception("Falha ao inicializar serviço de VoIP: $e");
    }
  }

  void setCallbacks({
    Function(String)? onCallEnded,
    Function(String)? onCallStarted,
  }) {
    _onCallEnded = onCallEnded;
    _onCallStarted = onCallStarted;
  }

  void _setupSocketListeners() {
    _socketService.incomingCallStream.listen((callData) {
      Logger.info("Received incoming call via Socket: $callData");
    });

    _socketService.callAcceptedStream.listen((callData) {
      Logger.info("Call accepted via Socket: $callData");
    });

    _socketService.callRejectedStream.listen((callData) {
      Logger.info("Call rejected via Socket: $callData");
      _isCalling = false;
      notifyListeners();
    });

    _socketService.callEndedStream.listen((callData) {
      Logger.info("Call ended via Socket: $callData");
      endCall();
    });
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

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  // --- MÉTODOS DE CONTROLE DE CHAMADA (API) ---

  Future<void> initiateCall({required String targetId, required String displayName, bool isVideoCall = false}) async {
    if (_isInCall) {
      throw Exception("Você já está em uma chamada.");
    }
    _isCalling = true;
    notifyListeners();

    Logger.info("Initiating call to $targetId");
    try {
      final token = await _authService.token;
      if (token == null) throw Exception('Token de autenticação não encontrado.');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/voip/initiate-call'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'receiverId': targetId, 'callType': isVideoCall ? 'video' : 'voice'}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _currentCall = Call.fromJson(responseData);
        Logger.info("Call initiation successful: $responseData");
      } else {
        throw Exception('Falha ao iniciar chamada: ${response.body}');
      }
    } catch (e) {
      _isCalling = false;
      notifyListeners();
      Logger.error("Error initiating call: $e");
      rethrow;
    }
  }

  Future<void> acceptCall({required String callId, required String roomId, required String displayName, bool isVideoCall = false}) async {
    Logger.info("Accepting call for room $roomId");
    try {
      final token = await _authService.token;
      if (token == null) throw Exception('Token de autenticação não encontrado.');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/voip/accept-call'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'callId': callId}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Logger.info("Call acceptance successful: $responseData");
        await startVoiceCall(
          roomId: responseData['roomName'],
          displayName: displayName,
          // token: responseData['jitsiToken'], // Wrapper não suporta token
          isAudioOnly: !isVideoCall,
        );
      } else {
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
      final token = await _authService.token;
      if (token == null) throw Exception('Token de autenticação não encontrado.');

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/voip/reject-call'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'callId': callId}),
      );
    } catch (e) {
      Logger.error("Error rejecting call: $e");
      rethrow;
    }
  }

  Future<void> endCallApi({required String callId}) async {
    Logger.info("Ending call for callId $callId");
    try {
      final token = await _authService.token;
      if (token == null) throw Exception('Token de autenticação não encontrado.');

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/voip/end-call'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'callId': callId}),
      );
    } catch (e) {
      Logger.error("Error ending call: $e");
      rethrow;
    }
  }

  Future<List<CallHistoryModel>> getCallHistory({String? clanId, String? federationId}) async {
    try {
      final token = await _authService.token;
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
        url += '?${Uri(queryParameters: queryParams).query}';
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

  // --- MÉTODOS DE CONTROLE DE MÍDIA (JITSI E WEBRTC) ---

  // ✅ AÇÃO 2: MÉTODO ADAPTADO PARA A API DO 'jitsi_meet_wrapper'
  Future<void> startVoiceCall({
    required String roomId,
    required String displayName,
    String? serverUrl,
    bool isAudioOnly = true,
  }) async {
    if (_isInCall) throw Exception("Já existe uma chamada em andamento");

    _currentRoomId = roomId;
    _isInCall = true;
    notifyListeners();

    try {
      final options = JitsiMeetingOptions(
        roomNameOrUrl: roomId,
        serverUrl: serverUrl,
        userDisplayName: displayName,
        isAudioOnly: isAudioOnly,
        isAudioMuted: false,
        isVideoMuted: isAudioOnly,
        featureFlags: {
          "invite.enabled": false,
          "recording.enabled": false,
          "live-streaming.enabled": false,
          "toolbox.alwaysVisible": false,
          "welcomepage.enabled": false,
        },
      );
      // O joinMeeting retorna um Future<JitsiMeetingResponse?> que completa quando a chamada termina.
      final response = await JitsiMeetWrapper.joinMeeting(
        options: options,
        listener: JitsiMeetingListener(
          onConferenceJoined: (url) => Logger.info("Wrapper: Conference Joined: $url"),
          onConferenceTerminated: (url, error) => Logger.info("Wrapper: Conference Terminated: $url, error: $error"),
          onConferenceWillJoin: (url) => Logger.info("Wrapper: Conference Will Join: $url"),
        ),
      );
      
      Logger.info("Jitsi call ended with response: ${response?.isSuccess}, ${response?.message}");
      // Quando o future completa, a chamada terminou.
      await endCall();

    } catch (e) {
      Logger.error('Failed to start voice call: $e');
      await endCall();
      throw Exception('Falha ao iniciar chamada de voz: $e');
    }
  }

  Future<void> endCall() async {
    if (_currentCall?.id != null) {
      await endCallApi(callId: _currentCall!.id);
    }

    if (_peerConnection != null) {
      await _closeWebRTCCall();
    }
    // O wrapper não tem um método hangUp(). O encerramento é feito pelo usuário na UI do Jitsi.
    // A limpeza de estado é o mais importante aqui.

    // Evitar chamar notifyListeners se o widget já foi descartado
    if (!_disposed) {
      _isInCall = false;
      _isCalling = false;
      _currentRoomId = null;
      _currentCall = null;
      _onCallEnded?.call("");
      notifyListeners();
      Logger.info('Call ended and state cleaned up.');
    }
  }

  void toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      audioTrack.enabled = !audioTrack.enabled;
      Logger.info("Audio track enabled: ${audioTrack.enabled}");
      notifyListeners();
    }
  }

  // --- LÓGICA WEBRTC ---

  Future<void> _initiateWebRTCCall({required String targetId, required String callId}) async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});

      _peerConnection = await createPeerConnection({
        'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]
      }, {});

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate != null) {
          _signalingService.sendIceCandidate(targetId, candidate);
        }
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'audio') {
          _remoteStream = event.streams[0];
          notifyListeners();
        }
      };

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _signalingService.sendOffer(targetId, offer);

      Logger.info("WebRTC offer sent to $targetId");
    } catch (e, stackTrace) {
      Logger.error("Error initiating WebRTC call", error: e, stackTrace: stackTrace);
      await endCall();
    }
  }

  Future<void> _closeWebRTCCall() async {
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    Logger.info("WebRTC call resources closed");
  }

  // --- MÉTODOS UTILITÁRIOS ---

  static String generateRoomId({required String prefix, String? entityId}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return entityId != null ? '${prefix}_${entityId}_$random' : '${prefix}_$random';
  }

  String formatCallDuration() {
    return '00:00';
  }

  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    _closeWebRTCCall();
    // O wrapper não tem um método de dispose ou removeAllListeners explícito.
    super.dispose();
  }
}
