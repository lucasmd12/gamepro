import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:lucasbeatsfederacao/services/auth_service.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final SocketService _socketService;
  final AuthService _authService; // Usar instância passada em vez de criar nova

  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  User? get currentUser => _authService.currentUser;
  AuthService get authService => _authService;

  AuthProvider(this._socketService, this._authService) {
    Logger.info('AuthProvider initialized. Listening to AuthService changes.');
    _authService.addListener(_authListener);
    _updateAuthStatus();
  }

  void _authListener() {
    Logger.info('AuthProvider received notification from AuthService.');
    _updateAuthStatus();
  }

  void _updateAuthStatus() {
    if (_authService.isAuthenticated) {
      if (_authStatus != AuthStatus.authenticated) {
        Logger.info('AuthProvider: Status changed to Authenticated.');
        _authStatus = AuthStatus.authenticated;
        Logger.info('AuthProvider: Connecting SocketService...');
        _socketService.connect();
        notifyListeners();
      }
    } else {
      if (_authStatus != AuthStatus.unauthenticated) {
        Logger.info('AuthProvider: Status changed to Unauthenticated.');
        _authStatus = AuthStatus.unauthenticated;
        Logger.info('AuthProvider: Disconnecting SocketService...');
        _socketService.disconnect();
        notifyListeners();
      }
    }
    if (_authStatus == AuthStatus.unknown && !_authService.isAuthenticated && !_authService.isLoading) {
      Logger.info('AuthProvider: Initial status resolved to Unauthenticated.');
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final success = await _authService.login(username, password);
      return success;
    } catch (e) {
      Logger.error('AuthProvider login failed: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final success = await _authService.register(username, password);
      return success;
    } catch (e) {
      Logger.error('AuthProvider register failed: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> logout() async {
    Logger.info('AuthProvider: Initiating logout.');
    await _authService.logout();
  }

  @override
  void dispose() {
    Logger.info('Disposing AuthProvider.');
    _authService.removeListener(_authListener);
    super.dispose();
  }
}




