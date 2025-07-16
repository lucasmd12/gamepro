import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  User? _currentUser;
  String? _token;
  String? _lastErrorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  String? get token => _token;
  String? get errorMessage => _lastErrorMessage;
  bool get isAdmin => _currentUser?.role == Role.admMaster || _currentUser?.role == Role.idcloned;
  ApiService get apiService => _apiService;

  AuthService() {
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    Logger.info("CIRURGIA: Verificando pulso inicial (status de autenticação)...");
    _setLoading(true);

    final storedToken = await _secureStorage.read(key: "jwt_token");
    if (storedToken != null) {
      Logger.info("Token encontrado no armazenamento seguro. Tentando reanimar sessão.");
      _token = storedToken;
      try {
        await fetchUserProfile(); // Tenta buscar o perfil com o token armazenado
        if (_currentUser != null) {
          _setAuthenticated(true);
          Logger.info("Sessão reanimada com sucesso para: ${_currentUser?.username}.");
          _setSentryUser();
        } else {
          // Se o perfil for nulo, o token é inválido ou expirado.
          Logger.warning("Token encontrado era um 'fantasma' (inválido). Realizando limpeza completa.");
          await _performFullLogout(); // Limpa o estado inválido
        }
      } catch (e) {
        Logger.error("Falha ao buscar perfil com token armazenado: ${e.toString()}. Expurgando token fantasma.");
        _lastErrorMessage = "Sua sessão expirou. Por favor, faça login novamente.";
        await _performFullLogout();
      }
    } else {
      Logger.info("Nenhum token encontrado. Paciente está em estado de 'não autenticado'.");
      _isAuthenticated = false;
    }
    _setLoading(false);
  }

  Future<void> fetchUserProfile() async {
    if (_token == null) {
      Logger.warning("Tentativa de buscar perfil sem token. Abortando.");
      throw Exception("Não autenticado");
    }
    try {
      final response = await _apiService.get("/api/auth/profile", requireAuth: true);
      if (response != null && response is Map<String, dynamic>) {
        _currentUser = User.fromJson(response);
        Logger.info("Perfil do usuário obtido com sucesso: ${_currentUser?.username}");
        _lastErrorMessage = null;
      } else {
        Logger.warning("A resposta do perfil foi nula ou em formato inválido.");
        _currentUser = null;
        throw Exception("Falha ao obter perfil do usuário");
      }
    } catch (e) {
      Logger.error("Erro ao buscar perfil do usuário: ${e.toString()}");
      _currentUser = null;
      _lastErrorMessage = e.toString();
      rethrow; // Propaga o erro para quem chamou
    }
  }

  Future<bool> login(String username, String password) async {
    Logger.info("CIRURGIA: Iniciando procedimento de login para '$username'.");
    _setLoading(true);
    _lastErrorMessage = null;

    // Limpeza preventiva para evitar fusão de identidades
    await _clearAuthData();

    try {
      final response = await _apiService.post(
        "/api/auth/login",
        {"username": username, "password": password},
        requireAuth: false,
      );

      if (response != null && response is Map<String, dynamic> && response.containsKey("token")) {
        final newToken = response["token"] as String?;
        if (newToken != null) {
          await _secureStorage.write(key: "jwt_token", value: newToken);
          _token = newToken;
          
          // Imediatamente busca o perfil para confirmar a identidade
          await fetchUserProfile(); 
          
          if (_currentUser != null) {
             _setAuthenticated(true);
             Logger.info("Login bem-sucedido. Nova identidade assumida: ${_currentUser?.username}");
             _setSentryUser();
             _setLoading(false);
             return true;
          } else {
            throw Exception("Autenticação bem-sucedida, mas falha ao buscar o perfil do usuário.");
          }
        }
      }
      // Se chegou aqui, a resposta não continha um token ou era inválida
      _lastErrorMessage = response?["msg"] ?? "Credenciais inválidas ou resposta inesperada do servidor.";
      throw Exception(_lastErrorMessage);

    } catch (e) {
      Logger.error("Falha crítica no procedimento de login: ${e.toString()}");
      _lastErrorMessage = e.toString().replaceFirst("Exception: ", "");
      await _performFullLogout(); // Garante que o estado falho seja completamente limpo
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    _setLoading(true);
    _lastErrorMessage = null;
    try {
      await _apiService.post(
        "/api/auth/register",
        {"username": username, "password": password},
        requireAuth: false,
      );
      Logger.info("Registro bem-sucedido para '$username'. Tentando login automático.");
      return await login(username, password);
    } catch (e) {
      Logger.error("Erro no registro: ${e.toString()}");
      _lastErrorMessage = e.toString().replaceFirst("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    Logger.info("CIRURGIA: Iniciando procedimento de logout e limpeza de memória.");
    _setLoading(true);
    await _performFullLogout();
    _setLoading(false);
  }

  // Função centralizada para garantir uma limpeza completa
  Future<void> _performFullLogout() async {
    await _clearAuthData();
    _setAuthenticated(false);
    _clearSentryUser();
    Logger.info("Memória de sessão e identidade completamente limpas.");
  }

  // Limpa apenas os dados, sem notificar listeners
  Future<void> _clearAuthData() async {
     _currentUser = null;
     _token = null;
     // Expurga todas as chaves conhecidas do armazenamento seguro
     await _secureStorage.delete(key: "jwt_token");
     await _secureStorage.delete(key: "userId"); // Limpeza adicional, se usada
  }

  void _setSentryUser() {
    if (_currentUser != null) {
      final currentUser = _currentUser!; // Use a local non-nullable variable
      Sentry.configureScope(
        (scope) {
          String? userRoleDisplayName;
          // Access displayName using the RoleExtension.
          userRoleDisplayName = currentUser.role.displayName;

 scope.setUser(
            SentryUser(
              id: currentUser.id,
              username: currentUser.username,
              data: {
                'role': userRoleDisplayName,
                'clan': currentUser.clanName,
                'federation': currentUser.federationName,
              },
            ),
          );
          scope.setTag('user_role', userRoleDisplayName ?? 'unknown');
          if (currentUser.clanName != null) {
            scope.setTag('user_clan', currentUser.clanName!);
          }
          if (currentUser.federationName != null) {
            scope.setTag('user_federation', currentUser.federationName!);
          }
        }
      );
    } else {
      _clearSentryUser();
    }
  }

  void _clearSentryUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
      scope.removeTag('user_role');
      scope.removeTag('user_clan');
      scope.removeTag('user_federation');
    });
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setAuthenticated(bool authenticated) {
    if (_isAuthenticated != authenticated) {
        _isAuthenticated = authenticated;
        notifyListeners();
    }
  }

  @override
  void dispose() {
    Logger.info("Disposing AuthService.");
    super.dispose();
  }
}


