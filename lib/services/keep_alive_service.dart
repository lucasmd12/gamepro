import 'dart:async';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class KeepAliveService {
  static final KeepAliveService _instance = KeepAliveService._internal();
  factory KeepAliveService() => _instance;
  KeepAliveService._internal();

  final ApiService _apiService = ApiService();
  Timer? _keepAliveTimer;
  bool _isActive = false;

  // Ping a cada 10 minutos para manter o servidor ativo
  static const Duration _pingInterval = Duration(minutes: 10);

  void startKeepAlive() {
    if (_isActive) return;
    
    Logger.info('Starting keep-alive service...');
    _isActive = true;
    
    // Fazer um ping inicial
    _pingServer();
    
    // Configurar timer para pings regulares
    _keepAliveTimer = Timer.periodic(_pingInterval, (timer) {
      _pingServer();
    });
  }

  void stopKeepAlive() {
    if (!_isActive) return;
    
    Logger.info('Stopping keep-alive service...');
    _isActive = false;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  Future<void> _pingServer() async {
    try {
      Logger.info('Sending keep-alive ping...');
      await _apiService.keepServerAlive();
      Logger.info('Keep-alive ping successful');
    } catch (e) {
      Logger.warning('Keep-alive ping failed: ${e.toString()}');
    }
  }

  // Método para fazer um ping manual (útil antes de operações importantes)
  Future<bool> ensureServerAwake() async {
    try {
      Logger.info('Ensuring server is awake...');
      await _apiService.keepServerAlive();
      Logger.info('Server is awake and responsive');
      return true;
    } catch (e) {
      Logger.warning('Failed to wake server: ${e.toString()}');
      return false;
    }
  }

  bool get isActive => _isActive;
}

