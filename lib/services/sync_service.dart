// lib/services/sync_service.dart
import 'dart:async';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/services/cache_service.dart';
import 'package:lucasbeatsfederacao/services/socket_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class SyncService {
  final ApiService _apiService;
  final SocketService _socketService;
  
  // Controle de sincronização
  bool _isInitialized = false;
  bool _isSyncing = false;
  Timer? _periodicSyncTimer;
  Timer? _healthCheckTimer;
  
  // Configurações
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _healthCheckInterval = Duration(minutes: 2);
  /// Define o tempo limite para operações de sincronização e chamadas de API críticas.
  /// Este timeout deve ser aplicado a operações assíncronas para evitar bloqueios.

  static const Duration _syncTimeout = Duration(seconds: 30);
  
  // Métricas
  int _syncCount = 0;
  int _syncErrors = 0;
  DateTime? _lastSyncTime;
  String _syncStatus = 'idle';

  SyncService(this._apiService, this._socketService);

  /// Inicializa o serviço de sincronização
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Logger.info('Initializing sync service...');
      
      // Configurar listeners de eventos do Socket.IO
      _setupSocketListeners();
      
      // Iniciar sincronização periódica
      _startPeriodicSync();
      
      // Iniciar health check
      _startHealthCheck();
      
      // Sincronização inicial
      await _performInitialSync();
      
      _isInitialized = true;
      Logger.info('Sync service initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize sync service: $e');
      rethrow;
    }
  }

  /// Configura listeners para eventos de invalidação do Socket.IO
  void _setupSocketListeners() {
    try {
      // Evento de invalidação de cache
      _socketService.cacheInvalidatedStream.listen((data) {
        _handleCacheInvalidation(data);
      });
      
      _socketService.dataUpdatedStream.listen((data) {
        _handleDataUpdate(data);
      });
      
      _socketService.userOnlineStream.listen((userId) {
        _handleUserStatusChange(userId, true);
      });
      
      _socketService.userOfflineStream.listen((userId) {
        _handleUserStatusChange(userId, false);
      });
      
      _socketService.clanUpdatedStream.listen((data) {
        _handleClanUpdate(data);
      });
      
      _socketService.federationUpdatedStream.listen((data) {
        _handleFederationUpdate(data);
      });
      
      _socketService.missionUpdatedStream.listen((data) {
        _handleMissionUpdate(data);
      });
      
      Logger.info('Socket listeners configured for sync service');
    } catch (e) {
      Logger.error('Error setting up socket listeners: $e');
    }
  }

  /// Inicia sincronização periódica
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) {
      _performPeriodicSync();
    });
    Logger.info('Periodic sync started (interval: ${_syncInterval.inMinutes}min)');
  }

  /// Inicia health check periódico
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) {
      _performHealthCheck();
    });
    Logger.info('Health check started (interval: ${_healthCheckInterval.inMinutes}min)');
  }

  /// Realiza sincronização inicial
  Future<void> _performInitialSync() async {
    try {
      _syncStatus = 'initial_sync';
      Logger.info('Performing initial sync...');
      
      // Verificar dados essenciais em cache
      final needsUserSync = !await CacheService.instance.isCacheValid("user");
      final needsStatsSync = !await CacheService.instance.isCacheValid("stats");
      final needsFederationsSync = !await CacheService.instance.isCacheValid("federations");
      
      // Sincronizar dados essenciais, se necessário
      if (needsUserSync || needsStatsSync || needsFederationsSync) {
        await _syncEssentialData();
      }
      
      _syncStatus = 'idle';
      Logger.info('Initial sync completed');
    } catch (e) {
      _syncStatus = 'error';
      Logger.error('Initial sync failed: $e');
    }
  }

  /// Realiza sincronização periódica
  Future<void> _performPeriodicSync() async {
    if (_isSyncing) {
      Logger.debug('Sync already in progress, skipping periodic sync');
      return;
    }
    
    try {
      _isSyncing = true;
      _syncStatus = 'syncing';
      _syncCount++;
      
      Logger.info('Performing periodic sync...');
      
      // Limpar cache expirado
      await CacheService.instance.clearExpiredCache();
      
      // Sincronizar dados que podem ter mudado
      await _syncVolatileData();
      
      _lastSyncTime = DateTime.now();
      _syncStatus = 'idle';
      Logger.debug('Periodic sync completed');
    } catch (e) {
      _syncErrors++;
      _syncStatus = 'error';
      Logger.error('Periodic sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Realiza health check
  Future<void> _performHealthCheck() async {
    try {
      // Verificar conectividade com backend
      await _apiService.get('/health', requireAuth: false, timeout: _syncTimeout);
      
      // Verificar saúde do cache local
      final cacheHealth = await CacheService.instance.getHealthInfo();
      
      if (cacheHealth['expiredEntries'] > 10) {
        Logger.info('Found ${cacheHealth['expiredEntries']} expired cache entries, cleaning up...');
        await CacheService.instance.clearExpiredCache();
      }
      
    } catch (e) {
      Logger.warning('Health check failed: $e');
    }
  }

  /// Sincroniza dados essenciais
  Future<void> _syncEssentialData() async {
    try {
      // Sincronizar estatísticas globais
      await _syncGlobalStats();
      
      // Sincronizar federações
      await _syncFederations();

      // Sincronizar clãs
      await _syncClans();
      
      Logger.info('Essential data sync completed');
    } catch (e) {
      Logger.error('Essential data sync failed: $e');
      rethrow;
    }
  }

  /// Sincroniza dados voláteis
  Future<void> _syncVolatileData() async {
    try {
      // Sincronizar apenas se cache estiver próximo do vencimento
      final statsValid = await CacheService.instance.isCacheValid('stats');
      if (!statsValid) { // Adiciona verificação explícita para null
        await _syncGlobalStats();
      }
      
    } catch (e) {
      Logger.error('Volatile data sync failed: $e');
    }
  }

  /// Sincroniza estatísticas globais
  Future<void> _syncGlobalStats() async {
    try {
      final response = await _apiService.get('/cache/global', timeout: _syncTimeout);
      if (response['success'] == true) {
        await CacheService.instance.cacheStats(response['data']);
        Logger.info('Global stats synced successfully');
      }
    } catch (e) {
      Logger.error('Failed to sync global stats: $e');
    }
  }

  /// Sincroniza federações
  Future<void> _syncFederations() async {
    try {
      final response = await _apiService.get('/federations', timeout: _syncTimeout);
      if (response['success'] == true) {
        await CacheService.instance.cacheFederations(
          List<Map<String, dynamic>>.from(response['data'])
        );
        Logger.info('Federations synced successfully');
      }
    } catch (e) {
      Logger.error('Failed to sync federations: $e');
    }
  }

  /// Sincroniza clãs
  Future<void> _syncClans({String? federationId}) async {
    try {
      final endpoint = federationId != null 
        ? '/clans?federationId=$federationId'
        : '/clans';
      
      final response = await _apiService.get(endpoint, timeout: _syncTimeout);
      if (response['success'] == true) {
        await CacheService.instance.cacheClans(
          List<Map<String, dynamic>>.from(response['data']),
          federationId: federationId
        );
        Logger.info('Clans synced successfully${federationId != null ? ' for federation $federationId' : ''}');
      }
    } catch (e) {
      Logger.error('Failed to sync clans: $e');
    }
  }

  /// Manipula invalidação de cache
  Future<void> _handleCacheInvalidation(dynamic data) async {
    try {
      final invalidationData = data as Map<String, dynamic>;
      final type = invalidationData['type'] as String?;
      final id = invalidationData['id'] as String?;
      
      if (type != null) {
        await CacheService.instance.invalidateCache(type, id: id);
        Logger.info('Cache invalidated for type: $type${id != null ? ' (id: $id)' : ''}');
      }
    } catch (e) {
      Logger.error('Error handling cache invalidation: $e');
    }
  }

  /// Manipula atualização de dados
  Future<void> _handleDataUpdate(dynamic data) async {
    try {
      final updateData = data as Map<String, dynamic>;
      final type = updateData['type'] as String?;
      final payload = updateData['data'];
      
      switch (type) {
        case 'stats':
          if (payload != null) {
            await CacheService.instance.cacheStats(payload);
          }
          break;
        case 'user':
          // Invalidar cache do usuário para forçar recarregamento
 await CacheService.instance.invalidateCache('user');
          break;
        default:
          Logger.info('Unhandled data update type: $type');
      }
    } catch (e) {
      Logger.error('Error handling data update: $e');
    }
  }

  /// Manipula mudança de status de usuário
  Future<void> _handleUserStatusChange(String userId, bool isOnline) async {
    try {
      // Invalidar estatísticas para refletir mudança
      CacheService.instance.invalidateCache('stats');
      Logger.info('User $userId status changed to ${isOnline ? 'online' : 'offline'}');
    } catch (e) {
      Logger.error('Error handling user status change: $e');
    }
  }

  /// Manipula atualização de clã
  Future<void> _handleClanUpdate(dynamic data) async {
    try {
      final clanData = data as Map<String, dynamic>;
      final clanId = clanData['clanId'] as String?;
      
      if (clanId != null) {
        await CacheService.instance.invalidateClanRelated(clanId);
        Logger.info('Clan cache invalidated for clan: $clanId');
      }
    } catch (e) {
      Logger.error('Error handling clan update: $e');
    }
  }

  /// Manipula atualização de federação
  Future<void> _handleFederationUpdate(dynamic data) async {
    try {
      final federationData = data as Map<String, dynamic>;
      final federationId = federationData['federationId'] as String?;
      
      if (federationId != null) {
        await CacheService.instance.invalidateFederationRelated(federationId);
        Logger.info('Federation cache invalidated for federation: $federationId');
      }
    } catch (e) {
      Logger.error('Error handling federation update: $e');
    }
  }

  /// Manipula atualização de missão
  Future<void> _handleMissionUpdate(dynamic data) async {
    try {
      final missionData = data as Map<String, dynamic>;
      final clanId = missionData['clanId'] as String?;
      
      if (clanId != null) {
        await CacheService.instance.invalidateCache('missions', id: clanId);
        await CacheService.instance.invalidateCache('stats'); // Missões podem afetar estatísticas
        Logger.info('Mission cache invalidated for clan: $clanId');
      }
    } catch (e) {
      Logger.error('Error handling mission update: $e');
    }
  }

  /// Força sincronização manual
  Future<void> forceSync() async {
    if (_isSyncing) {
      Logger.warning('Sync already in progress');
      return;
    }

    try {
      _isSyncing = true;
      _syncStatus = 'manual_sync';
      
      // Limpar todo o cache e recarregar
      await CacheService.instance.clearAllCache();
      await _syncEssentialData();
      
      _lastSyncTime = DateTime.now();
      _syncStatus = 'idle';
      Logger.info('Manual sync completed');
    } catch (e) {
      _syncErrors++;
      _syncStatus = 'error';
      Logger.error('Manual sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Obtém status da sincronização
  Map<String, dynamic> getSyncStatus() {
    return {
      'isInitialized': _isInitialized,
      'isSyncing': _isSyncing,
      'status': _syncStatus,
      'syncCount': _syncCount,
      'syncErrors': _syncErrors,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'nextSyncIn': _periodicSyncTimer != null 
        ? _syncInterval.inSeconds - (DateTime.now().millisecondsSinceEpoch ~/ 1000) % _syncInterval.inSeconds
        : null,
    };
  }

  /// Para o serviço de sincronização
  void dispose() {
    _periodicSyncTimer?.cancel();
    _healthCheckTimer?.cancel();
    _isInitialized = false;
    Logger.info('Sync service disposed');
  }
}

