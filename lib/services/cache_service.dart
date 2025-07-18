import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class CacheService {
  static final CacheService instance = CacheService._internal();

  CacheService._internal();
  static const String _keyPrefix = 'cache_';
  static const String _timestampSuffix = '_timestamp';
  static const String _metricsSuffix = '_metrics';
  
  // TTL padrão em segundos
  static const int _defaultTTL = 1800; // 30 minutos
  static const int _shortTTL = 300;    // 5 minutos
  static const int _longTTL = 3600;    // 1 hora
  static const int _imageTTL = 7200;   // 2 horas para URLs de imagem
  
  // Métricas de cache
  int _hits = 0;
  int _misses = 0;
  int _sets = 0;
  int _invalidations = 0;

  /// Armazena dados no cache com TTL
  Future<bool> set(String key, dynamic data, {int? ttlSeconds}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _keyPrefix + key;
      final timestampKey = cacheKey + _timestampSuffix;
      
      final ttl = ttlSeconds ?? _defaultTTL;
      final expirationTime = DateTime.now().millisecondsSinceEpoch + (ttl * 1000);
      
      // Serializar dados
      String serializedData;
      if (data is String) {
        serializedData = data;
      } else {
        serializedData = jsonEncode(data);
      }
      
      // Armazenar dados e timestamp
      final dataStored = await prefs.setString(cacheKey, serializedData);
      final timestampStored = await prefs.setInt(timestampKey, expirationTime);
      
      if (dataStored && timestampStored) {
        _sets++;
        Logger.info('Cache SET: $key (TTL: ${ttl}s)');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erro ao armazenar no cache: ${e.toString()}');
      return false;
    }
  }

  /// Recupera dados do cache
  Future<T?> get<T>(String key, {T? Function(Map<String, dynamic>)? fromJson}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _keyPrefix + key;
      final timestampKey = cacheKey + _timestampSuffix;
      
      // Verificar se existe
      if (!prefs.containsKey(cacheKey) || !prefs.containsKey(timestampKey)) {
        _misses++;
        Logger.debug('Cache MISS: $key (não encontrado)');
        return null;
      }
      
      // Verificar expiração
      final expirationTime = prefs.getInt(timestampKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      if (currentTime > expirationTime) {
        _misses++;
        Logger.debug('Cache MISS: $key (expirado)');
        // Remover dados expirados
        await _removeKey(key);
        return null;
      }
      
      // Recuperar dados
      final serializedData = prefs.getString(cacheKey);
      if (serializedData == null) {
        _misses++;
        return null;
      }
      
      _hits++;
      Logger.debug('Cache HIT: $key');
      
      // Deserializar dados
      if (T == String) {
        return serializedData as T;
      } else if (fromJson != null) {
        final jsonData = jsonDecode(serializedData) as Map<String, dynamic>;
        return fromJson(jsonData);
      } else {
        return jsonDecode(serializedData) as T;
      }
    } catch (e) {
      Logger.error('Erro ao recuperar do cache: ${e.toString()}');
      _misses++;
      return null;
    }
  }

  /// Remove uma chave específica do cache
  Future<bool> remove(String key) async {
    try {
      final removed = await _removeKey(key);
      if (removed) {
        _invalidations++;
        Logger.info('Cache REMOVE: $key');
      }
      return removed;
    } catch (e) {
      Logger.error('Erro ao remover do cache: ${e.toString()}');
      return false;
    }
  }

  /// Remove chave interna
  Future<bool> _removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _keyPrefix + key;
    final timestampKey = cacheKey + _timestampSuffix;
    
    final dataRemoved = await prefs.remove(cacheKey);
    final timestampRemoved = await prefs.remove(timestampKey);
    
    return dataRemoved || timestampRemoved;
  }

  /// Invalida cache por padrão (ex: 'user_*')
  Future<int> invalidatePattern(String pattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Converter padrão para regex
      final regexPattern = pattern.replaceAll('*', '.*');
      final regex = RegExp('^' + _keyPrefix + regexPattern + r'($|_timestamp$)');
      
      final keysToRemove = keys.where((key) => regex.hasMatch(key)).toList();
      
      int removedCount = 0;
      for (final key in keysToRemove) {
        if (await prefs.remove(key)) {
          removedCount++;
        }
      }
      
      if (removedCount > 0) {
        _invalidations += removedCount ~/ 2; // Dividir por 2 porque cada entrada tem data + timestamp
        Logger.info('Cache INVALIDATE PATTERN: $pattern ($removedCount chaves removidas)');
      }
      
      return removedCount ~/ 2;
    } catch (e) {
      Logger.error('Erro ao invalidar padrão do cache: ${e.toString()}');
      return 0;
    }
  }

  /// Limpa todo o cache
  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final cacheKeys = keys.where((key) => key.startsWith(_keyPrefix)).toList();
      
      int removedCount = 0;
      for (final key in cacheKeys) {
        if (await prefs.remove(key)) {
          removedCount++;
        }
      }
      
      if (removedCount > 0) {
        Logger.info('Cache CLEAR: $removedCount chaves removidas');
        _invalidations += removedCount;
      }
      
      return true;
    } catch (e) {
      Logger.error('Erro ao limpar cache: ${e.toString()}');
      return false;
    }
  }

  /// Verifica se uma chave existe e não está expirada
  Future<bool> exists(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _keyPrefix + key;
      final timestampKey = cacheKey + _timestampSuffix;
      
      if (!prefs.containsKey(cacheKey) || !prefs.containsKey(timestampKey)) {
        return false;
      }
      
      final expirationTime = prefs.getInt(timestampKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      return currentTime <= expirationTime;
    } catch (e) {
      Logger.error('Erro ao verificar existência no cache: ${e.toString()}');
      return false;
    }
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() { // Renomeado para evitar conflito
    final total = _hits + _misses;
    final hitRate = total > 0 ? (_hits / total * 100).toStringAsFixed(2) : '0.00';
    
    return {
      'hits': _hits,
      'misses': _misses,
      'sets': _sets,
      'invalidations': _invalidations,
      'hitRate': '$hitRate%',
      'total': total,
    };
  }

  /// Reseta estatísticas
  void resetStats() {
    _hits = 0;
    _misses = 0;
    _sets = 0;
    _invalidations = 0;
    Logger.info('Cache stats reset');
  }

  /// Métodos específicos para diferentes tipos de dados

  /// Cache para dados de usuário
  Future<bool> setUser(String userId, Map<String, dynamic> userData) async {
    return await set('user_$userId', userData, ttlSeconds: _longTTL);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    return await get<Map<String, dynamic>>('user_$userId');
  }

  /// Cache para listas de federações
  Future<bool> setFederations(List<Map<String, dynamic>> federations) async {
    return await set('federations_list', federations, ttlSeconds: _defaultTTL);
  }

  Future<List<Map<String, dynamic>>?> getFederations() async {
    final result = await get<List<dynamic>>('federations_list');
    return result?.cast<Map<String, dynamic>>();
  }

  /// Cache para listas de clãs
  Future<bool> setClans(List<Map<String, dynamic>> clans) async {
    return await set('clans_list', clans, ttlSeconds: _defaultTTL);
  }

  Future<List<Map<String, dynamic>>?> getClans() async {
    final result = await get<List<dynamic>>('clans_list');
    return result?.cast<Map<String, dynamic>>();
  }

  /// Cache para URLs de imagem do Cloudinary
  Future<bool> setImageUrl(String imageId, String url, {String? preset}) async {
    final key = preset != null ? 'image_${imageId}_$preset' : 'image_$imageId';
    return await set(key, url, ttlSeconds: _imageTTL);
  }

  Future<String?> getImageUrl(String imageId, {String? preset}) async {
    final key = preset != null ? 'image_${imageId}_$preset' : 'image_$imageId';
    return await get<String>(key);
  }

  // Adicionando os métodos getCachedImageUrl e cacheImageUrl



  /// Cache para dados de missões
  Future<bool> setMission(String missionId, Map<String, dynamic> missionData) async {
    return await set('mission_$missionId', missionData, ttlSeconds: _shortTTL);
  }

  Future<Map<String, dynamic>?> getMission(String missionId) async {
    return await get<Map<String, dynamic>>('mission_$missionId');
  }

  /// Cache para estatísticas
  Future<bool> setStats(String statsType, Map<String, dynamic> stats) async {
    return await set('stats_$statsType', stats, ttlSeconds: _shortTTL);
  }

  Future<Map<String, dynamic>?> getStats(String statsType) async { // Mantido o nome original para este método
    return await get<Map<String, dynamic>>('stats_$statsType');
  }

  /// Cache para configurações
  Future<bool> setConfig(String configKey, dynamic configValue) async {
    return await set('config_$configKey', configValue, ttlSeconds: _longTTL);
  }

  Future<T?> getConfig<T>(String configKey) async {
    return await get<T>('config_$configKey');
  }

  /// Limpeza automática de cache expirado
  Future<int> cleanExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final timestampKeys = keys.where((key) => key.endsWith(_timestampSuffix)).toList();
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      int cleanedCount = 0;
      
      for (final timestampKey in timestampKeys) {
        final expirationTime = prefs.getInt(timestampKey) ?? 0;
        
        if (currentTime > expirationTime) {
          // Remover timestamp e dados correspondentes
          final dataKey = timestampKey.replaceAll(_timestampSuffix, '');
          
          if (await prefs.remove(timestampKey)) cleanedCount++;
          if (await prefs.remove(dataKey)) cleanedCount++;
        }
      }
      
      if (cleanedCount > 0) {
        Logger.info('Cache CLEAN: $cleanedCount chaves expiradas removidas');
      }
      
      return cleanedCount ~/ 2;
    } catch (e) {
      Logger.error('Erro na limpeza automática do cache: ${e.toString()}');
      return 0;
    }
  }

  /// Obtém informações sobre o tamanho do cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final cacheKeys = keys.where((k) => k.startsWith(_keyPrefix)).toList();
      final dataKeys = cacheKeys.where((k) => !k.endsWith(_timestampSuffix)).toList();
      
      int totalSize = 0;
      for (final key in cacheKeys) {
        final value = prefs.get(key);
        if (value is String) {
          totalSize += value.length;
        }
      }
      
      return {
        'totalKeys': dataKeys.length,
        'totalSize': totalSize,
        'averageSize': dataKeys.isNotEmpty ? (totalSize / dataKeys.length).round() : 0,
        'stats': getCacheStats(), // Usando o método renomeado
      };
    } catch (e) {
      Logger.error('Erro ao obter informações do cache: ${e.toString()}');
      return {
        'totalKeys': 0,
        'totalSize': 0,
        'averageSize': 0,
        'stats': getCacheStats(), // Usando o método renomeado
      };
    }
  }

  // Métodos especializados para sincronização (completando o DNA)
  
  /// Verifica se o cache é válido (não expirado)
  Future<bool> isCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = _keyPrefix + key + _timestampSuffix;
      final expirationTime = prefs.getInt(timestampKey);
      
      if (expirationTime == null) return false;
      
      return DateTime.now().millisecondsSinceEpoch < expirationTime;
    } catch (e) {
      Logger.error('Erro ao verificar validade do cache: ${e.toString()}');
      return false;
    }
  }

  /// Limpa cache expirado
  Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (final key in keys) {
        if (key.startsWith(_keyPrefix) && key.endsWith(_timestampSuffix)) {
          final expirationTime = prefs.getInt(key);
          if (expirationTime != null && now >= expirationTime) {
            final dataKey = key.replaceAll(_timestampSuffix, '');
            await prefs.remove(dataKey);
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      Logger.error('Erro ao limpar cache expirado: ${e.toString()}');
    }
  }

  /// Invalida cache específico
  Future<void> invalidateCache(String type, {String? id}) async {
    try {
      final key = id != null ? '${type}_$id' : type;
      await remove(key);
    } catch (e) {
      Logger.error('Erro ao invalidar cache: ${e.toString()}');
    }
  }

  /// Armazena estatísticas no cache
  Future<void> cacheStats(dynamic stats) async {
    await setStats('global', stats);
  }

  /// Armazena clãs no cache
  Future<void> cacheClans(List<Map<String, dynamic>> clans, {String? federationId}) async {
    await setClans(clans);
  }

  /// Armazena federações no cache
  Future<void> cacheFederations(List<Map<String, dynamic>> federations) async {
    await setFederations(federations);
  }

  /// Invalida cache relacionado a clã
  Future<void> invalidateClanRelated(String clanId) async {
    await invalidatePattern('clan_$clanId');
    await remove('clans');
  }

  /// Invalida cache relacionado a federação
  Future<void> invalidateFederationRelated(String federationId) async {
    await invalidatePattern('federation_$federationId');
    await remove('federations');
  }

  /// Limpa todo o cache
  Future<void> clearAllCache() async {
    await clear();
  }

  /// Obtém informações de saúde do cache
  Future<Map<String, dynamic>> getHealthInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now().millisecondsSinceEpoch;
      int expiredEntries = 0;
      
      for (final key in keys) {
        if (key.startsWith(_keyPrefix) && key.endsWith(_timestampSuffix)) {
          final expirationTime = prefs.getInt(key);
          if (expirationTime != null && now >= expirationTime) {
            expiredEntries++;
          }
        }
      }
      
      return {
        'expiredEntries': expiredEntries,
        'totalEntries': keys.where((k) => k.startsWith(_keyPrefix) && !k.endsWith(_timestampSuffix)).length,
        'health': expiredEntries < 10 ? 'good' : 'needs_cleanup',
      };
    } catch (e) {
      Logger.error('Erro ao obter informações de saúde: ${e.toString()}');
      return {
        'totalEntries': 0,
        'health': 'unknown',
      };
    }
  }
}

