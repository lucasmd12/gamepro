import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class ContextService {
  static const String _lastClanIdKey = 'last_clan_id';
  static const String _lastFederationIdKey = 'last_federation_id';

  Future<void> saveLastClanId(String? clanId) async {
    final prefs = await SharedPreferences.getInstance();
    if (clanId != null) {
      await prefs.setString(_lastClanIdKey, clanId);
      Logger.info('ContextService: Last clan ID saved: $clanId');
    } else {
      await prefs.remove(_lastClanIdKey);
      Logger.info('ContextService: Last clan ID removed.');
    }
  }

  Future<String?> getLastClanId() async {
    final prefs = await SharedPreferences.getInstance();
    final clanId = prefs.getString(_lastClanIdKey);
    Logger.info('ContextService: Last clan ID retrieved: $clanId');
    return clanId;
  }

  Future<void> saveLastFederationId(String? federationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (federationId != null) {
      await prefs.setString(_lastFederationIdKey, federationId);
      Logger.info('ContextService: Last federation ID saved: $federationId');
    } else {
      await prefs.remove(_lastFederationIdKey);
      Logger.info('ContextService: Last federation ID removed.');
    }
  }

  Future<String?> getLastFederationId() async {
    final prefs = await SharedPreferences.getInstance();
    final federationId = prefs.getString(_lastFederationIdKey);
    Logger.info('ContextService: Last federation ID retrieved: $federationId');
    return federationId;
  }

  Future<void> clearAllContext() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastClanIdKey);
    await prefs.remove(_lastFederationIdKey);
    Logger.info('ContextService: All context data cleared.');
  }
}


