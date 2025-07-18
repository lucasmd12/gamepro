// lib/services/signaling_service.dart
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart'; // Import ChangeNotifier
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'socket_service.dart';

class SignalingService extends ChangeNotifier {
  final SocketService _socketService;

  // Callbacks para o VoipService
  Function(RTCSessionDescription)? onRemoteSdp;
  Function(RTCIceCandidate)? onRemoteIceCandidate;
  Function(Map<String, dynamic>)? onIncomingCall;
  Function(Map<String, dynamic>)? onCallAccepted;
  Function(Map<String, dynamic>)? onCallRejected;
  Function(Map<String, dynamic>)? onCallEnded;

  // Getters para configuração WebRTC
  Map<String, dynamic> get rtcConfiguration => {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'}
        ],
        'sdpSemantics': 'unified-plan',
      };

  Map<String, dynamic> get rtcConstraints => {
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': false,
        },
        'optional': [],
      };

  // Expor o stream de sinalização do SocketService
  Stream<Map<String, dynamic>> get signalStream => _socketService.signalStream;

  SignalingService(this._socketService) {
    _socketService.signalStream.listen((data) {
      final String signalType = data['signalType'];
      final Map<String, dynamic> signalData = data['signalData'];
      final String senderUserId = data['senderUserId'];

      Logger.info('Sinal WebRTC recebido: $signalType de $senderUserId');

      switch (signalType) {
        case 'offer':
        case 'answer':
          onRemoteSdp?.call(RTCSessionDescription(
            signalData['sdp'],
            signalData['type'],
          ));
          break;
        case 'candidate':
          onRemoteIceCandidate?.call(RTCIceCandidate(
            signalData['candidate'],
            signalData['sdpMid'],
            signalData['sdpMLineIndex'],
          ));
          break;
        default:
          Logger.warning('Tipo de sinal WebRTC desconhecido: $signalType');
          break;
      }
    });

    _socketService.incomingCallStream.listen((data) {
      onIncomingCall?.call(data);
    });

    _socketService.callAcceptedStream.listen((data) {
      onCallAccepted?.call(data);
    });

    _socketService.callRejectedStream.listen((data) {
      onCallRejected?.call(data);
    });

    _socketService.callEndedStream.listen((data) {
      onCallEnded?.call(data);
    });
  }

  void sendSignal(String targetUserId, String signalType, Map<String, dynamic> signalData) {
    _socketService.sendSignal(targetUserId, signalType, signalData);
    Logger.info('Sinal WebRTC enviado: $signalType para $targetUserId');
  }

  void sendOffer(String targetUserId, RTCSessionDescription sdp) {
    sendSignal(targetUserId, 'offer', {'sdp': sdp.sdp, 'type': sdp.type});
  }

  void sendAnswer(String targetUserId, RTCSessionDescription sdp) {
    sendSignal(targetUserId, 'answer', {'sdp': sdp.sdp, 'type': sdp.type});
  }

  void sendIceCandidate(String targetUserId, RTCIceCandidate candidate) {
    sendSignal(targetUserId, 'candidate', {
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  // Métodos para conectar/desconectar o socket subjacente
  void connect() {
    _socketService.connect();
  }

  void disconnect() {
    _socketService.disconnect();
  }
}


