class SystemSetting {
  bool maintenanceMode;
  bool registrationEnabled;
  String serverRegion;
  bool chatEnabled;
  bool voiceEnabled;
  bool notificationsEnabled;
  int maxUsersPerClan;
  int maxClansPerFederation;

  SystemSetting({
    required this.maintenanceMode,
    required this.registrationEnabled,
    required this.serverRegion,
    required this.chatEnabled,
    required this.voiceEnabled,
    required this.notificationsEnabled,
    required this.maxUsersPerClan,
    required this.maxClansPerFederation,
  });

  // ✅ AÇÃO 1: MÉTODO copyWith ADICIONADO
  SystemSetting copyWith({
    bool? maintenanceMode,
    bool? registrationEnabled,
    String? serverRegion,
    bool? chatEnabled,
    bool? voiceEnabled,
    bool? notificationsEnabled,
    int? maxUsersPerClan,
    int? maxClansPerFederation,
  }) {
    return SystemSetting(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      registrationEnabled: registrationEnabled ?? this.registrationEnabled,
      serverRegion: serverRegion ?? this.serverRegion,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      maxUsersPerClan: maxUsersPerClan ?? this.maxUsersPerClan,
      maxClansPerFederation: maxClansPerFederation ?? this.maxClansPerFederation,
    );
  }

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    return SystemSetting(
      maintenanceMode: json['maintenanceMode'] ?? false,
      registrationEnabled: json['registrationEnabled'] ?? true,
      serverRegion: json['serverRegion'] ?? 'Brasil',
      chatEnabled: json['chatEnabled'] ?? true,
      voiceEnabled: json['voiceEnabled'] ?? true,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      maxUsersPerClan: json['maxUsersPerClan'] ?? 50,
      maxClansPerFederation: json['maxClansPerFederation'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenanceMode': maintenanceMode,
      'registrationEnabled': registrationEnabled,
      'serverRegion': serverRegion,
      'chatEnabled': chatEnabled,
      'voiceEnabled': voiceEnabled,
      'notificationsEnabled': notificationsEnabled,
      'maxUsersPerClan': maxUsersPerClan,
      'maxClansPerFederation': maxClansPerFederation,
    };
  }
}
