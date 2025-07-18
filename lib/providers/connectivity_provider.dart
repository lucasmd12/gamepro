import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../utils/logger.dart';

/// Provider para monitorar o estado da conexão com a internet.
class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Retorna `true` se o dispositivo estiver conectado à internet.
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    Logger.info('ConnectivityProvider Initialized.');
    _checkInitialConnection();
    _listenToConnectivityChanges();
  }

  /// Verifica a conexão inicial.
  Future<void> _checkInitialConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateStatus(result);
      Logger.info('Initial connectivity check result: $result');
    } catch (e, stackTrace) {
      Logger.error('Error checking initial connectivity', error: e, stackTrace: stackTrace);
      _updateStatus([ConnectivityResult.none]);
    }
  }

  /// Ouve as mudanças no estado da conectividade.
  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      Logger.info('Connectivity changed: $result');
      _updateStatus(result);
    }, onError: (e, stackTrace) {
      Logger.error('Error listening to connectivity changes', error: e, stackTrace: stackTrace);
      _updateStatus([ConnectivityResult.none]);
    });
  }

  /// Atualiza o status da conexão e notifica os listeners se houver mudança.
  void _updateStatus(List<ConnectivityResult> result) {
    bool newStatus = result.isNotEmpty && !result.contains(ConnectivityResult.none);

    if (_isOnline != newStatus) {
      _isOnline = newStatus;
      Logger.info('Connectivity status changed: ${_isOnline ? 'Online' : 'Offline'}');
      notifyListeners();
    }
  }

  /// Cancela a inscrição do listener ao descartar o provider.
  @override
  void dispose() {
    Logger.info('Disposing ConnectivityProvider.');
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}