import 'package:flutter/foundation.dart';
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

enum CallState { idle, connecting, active, ended, failed }

class CallProvider with ChangeNotifier {
  final AuthService _authService;

  CallState _callState = CallState.idle;
  String? _errorMessage;
  String? _currentChannelId; // Adicionado para rastrear o canal de voz atual

  CallState get callState => _callState;
  String? get errorMessage => _errorMessage;
  String? get currentChannelId => _currentChannelId; // Getter para o ID do canal atual

  CallProvider({
    required AuthService authService,
  }) : _authService = authService {
    _initialize();
  }

  void _initialize() {
    Logger.info("CallProvider initialized.");
  }

  // Método para entrar em um canal de voz
  Future<void> joinChannel(String channelId) async {
    Logger.info('Attempting to join channel: $channelId');
 if (_authService.currentUser == null) {
      Logger.warning('Cannot join channel: User not authenticated.');
      updateCallState(CallState.failed, message: 'User not authenticated.');
      return;
    }
    updateCallState(CallState.connecting);
    try {
      // Lógica para realmente entrar no canal (ex: Jitsi Meet, WebRTC, etc.)
      // Por enquanto, apenas simula a entrada
      await Future.delayed(const Duration(seconds: 2)); // Simula um atraso de rede
      _currentChannelId = channelId;
      updateCallState(CallState.active);
      Logger.info('Successfully joined channel: $channelId');
    } catch (e) {
      Logger.error('Failed to join channel: $e');
      updateCallState(CallState.failed, message: 'Failed to join channel: $e');
    }
  }

  // Método para sair do canal de voz atual
  Future<void> leaveChannel() async {
    if (_currentChannelId == null) {
      Logger.warning('Not in a channel to leave.');
      return;
    }
    Logger.info('Attempting to leave channel: $_currentChannelId');
    updateCallState(CallState.ended);
    try {
      // Lógica para realmente sair do canal
      await Future.delayed(const Duration(seconds: 1)); // Simula um atraso de rede
      _currentChannelId = null;
      updateCallState(CallState.idle);
      Logger.info('Successfully left channel.');
    } catch (e) {
      Logger.error('Failed to leave channel: $e');
      updateCallState(CallState.failed, message: 'Failed to leave channel: $e');
    }
  }

  void updateCallState(CallState newState, {String? message}) {
    _callState = newState;
    _errorMessage = message;
    notifyListeners();
    Logger.info('Call state updated to: $newState${message != null ? ' - $message' : ''}');
  }

  @override
  void dispose() {
    Logger.info('Disposing CallProvider...');
    super.dispose();
  }
}


