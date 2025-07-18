import 'package:flutter/foundation.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/services/context_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

enum AppContextType {
  global,
  federation,
  clan,
  privateChat,
  adminPanel,
  voipRoom,
}

class ContextProvider extends ChangeNotifier {
  final ContextService _contextService;

  AppContextType _currentContextType = AppContextType.global;
  String? _currentFederationId;
  Federation? _currentFederation;
  String? _currentClanId;
  Clan? _currentClan;
  String? _currentChatRecipientId; // Para chat privado

  AppContextType get currentContextType => _currentContextType;
  String? get currentFederationId => _currentFederationId;
  Federation? get currentFederation => _currentFederation;
  String? get currentClanId => _currentClanId;
  Clan? get currentClan => _currentClan;
  String? get currentChatRecipientId => _currentChatRecipientId;

  ContextProvider(this._contextService) {
    _loadLastContext();
  }

  Future<void> _loadLastContext() async {
    final lastClanId = await _contextService.getLastClanId();
    final lastFederationId = await _contextService.getLastFederationId();

    if (lastClanId != null) {
      // Tentar carregar o clã e definir o contexto
      // Nota: Para carregar o objeto Clan/Federation completo, você precisaria de um ClanService/FederationService aqui.
      // Por simplicidade, estamos apenas definindo o ID e o tipo de contexto.
      _currentClanId = lastClanId;
      _currentContextType = AppContextType.clan;
      Logger.info('ContextProvider: Loaded last clan context: $lastClanId');
    } else if (lastFederationId != null) {
      _currentFederationId = lastFederationId;
      _currentContextType = AppContextType.federation;
      Logger.info('ContextProvider: Loaded last federation context: $lastFederationId');
    } else {
      _currentContextType = AppContextType.global;
      Logger.info('ContextProvider: Defaulting to global context.');
    }
    notifyListeners();
  }

  Future<void> setGlobalContext() async {
    _currentContextType = AppContextType.global;
    _currentFederationId = null;
    _currentFederation = null;
    _currentClanId = null;
    _currentClan = null;
    _currentChatRecipientId = null;
    await _contextService.clearAllContext();
    Logger.info('ContextProvider: Context set to Global.');
    notifyListeners();
  }

  Future<void> setFederationContext(String federationId, {Federation? federation}) async {
    _currentContextType = AppContextType.federation;
    _currentFederationId = federationId;
    _currentFederation = federation;
    _currentClanId = null;
    _currentClan = null;
    _currentChatRecipientId = null;
    await _contextService.saveLastFederationId(federationId);
    Logger.info('ContextProvider: Context set to Federation: $federationId');
    notifyListeners();
  }

  Future<void> setClanContext(String clanId, {Clan? clan, String? federationId, Federation? federation}) async {
    _currentContextType = AppContextType.clan;
    _currentClanId = clanId;
    _currentClan = clan;
    _currentFederationId = federationId ?? _currentFederationId;
    _currentFederation = federation ?? _currentFederation;
    _currentChatRecipientId = null;
    await _contextService.saveLastClanId(clanId);
    await _contextService.saveLastFederationId(_currentFederationId); // Salva a federação também
    Logger.info('ContextProvider: Context set to Clan: $clanId');
    notifyListeners();
  }

  void setPrivateChatContext(String recipientId) {
    _currentContextType = AppContextType.privateChat;
    _currentChatRecipientId = recipientId;
    _currentFederationId = null;
    _currentFederation = null;
    _currentClanId = null;
    _currentClan = null;
    Logger.info('ContextProvider: Context set to Private Chat with: $recipientId');
    notifyListeners();
  }

  void setAdminPanelContext() {
    _currentContextType = AppContextType.adminPanel;
    _currentFederationId = null;
    _currentFederation = null;
    _currentClanId = null;
    _currentClan = null;
    _currentChatRecipientId = null;
    Logger.info('ContextProvider: Context set to Admin Panel.');
    notifyListeners();
  }

  void setVoipRoomContext(String roomId) {
    _currentContextType = AppContextType.voipRoom;
    // Você pode armazenar o ID da sala VoIP aqui se necessário
    Logger.info('ContextProvider: Context set to VoIP Room: $roomId');
    notifyListeners();
  }

  // Métodos para atualizar os objetos completos de Clan e Federation, se já tiver os IDs
  void updateCurrentFederation(Federation federation) {
    if (_currentFederationId == federation.id) {
      _currentFederation = federation;
      notifyListeners();
      Logger.info('ContextProvider: Current Federation object updated.');
    }
  }

  void updateCurrentClan(Clan clan) {
    if (_currentClanId == clan.id) {
      _currentClan = clan;
      notifyListeners();
      Logger.info('ContextProvider: Current Clan object updated.');
    }
  }

  // Helper para obter o ID do contexto atual para chamadas de API ou UI
  String? get currentContextId {
    switch (_currentContextType) {
      case AppContextType.federation:
        return _currentFederationId;
      case AppContextType.clan:
        return _currentClanId;
      case AppContextType.privateChat:
        return _currentChatRecipientId;
      default:
        return null;
    }
  }

  // Helper para obter o nome do contexto atual para exibição na UI
  String get currentContextName {
    switch (_currentContextType) {
      case AppContextType.global:
        return 'Global';
      case AppContextType.federation:
        return _currentFederation?.name ?? 'Federação';
      case AppContextType.clan:
        return _currentClan?.name ?? 'Clã';
      case AppContextType.privateChat:
        return 'Chat Privado'; // Pode ser o nome do destinatário se disponível
      case AppContextType.adminPanel:
        return 'Painel ADM';
      case AppContextType.voipRoom:
        return 'Sala de Voz';
      default:
        return 'Desconhecido';
    }
  }
}


