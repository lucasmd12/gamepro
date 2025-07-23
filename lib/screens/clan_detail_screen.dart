import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/screens/tabs/members_tab.dart';
import 'package:lucasbeatsfederacao/screens/tabs/settings_tab.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/services/permission_service.dart'; //  IMPORT ADICIONADO
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';

class ClanDetailScreen extends StatefulWidget {
  final Clan clan;

  const ClanDetailScreen({super.key, required this.clan});

  @override
  State<ClanDetailScreen> createState() => _ClanDetailScreenState();
}

class _ClanDetailScreenState extends State<ClanDetailScreen> {
  List<Clan> _clans = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Apenas carrega a lista de clãs se for necessário para a declaração de guerra
    final permissionService = Provider.of<PermissionService>(context, listen: false);
    if (permissionService.canDeclareWar(widget.clan)) {
      _loadClans();
    }
  }

  Future<void> _loadClans() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final clans = await clanService.getAllClans();
      if (mounted) {
        setState(() {
          _clans = clans.whereType<Clan>().toList();
        });
      }
    } catch (e, s) {
      Logger.error("Erro ao carregar clãs:", error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao carregar clãs: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeclareWarDialog() {
    String? targetClanId;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Declarar Guerra de ${widget.clan.name}"),
          content: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String?>(
                  value: targetClanId,
                  decoration: const InputDecoration(
                    labelText: "Selecione o Clã Alvo",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text("Selecione um Clã"),
                    ),
                    ..._clans.where((clan) => clan.id != widget.clan.id).map((clan) {
                      return DropdownMenuItem<String?>(
                        value: clan.id,
                        child: Text(clan.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (val) {
                    targetClanId = val;
                  },
                ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Declarar Guerra"),
              onPressed: () async {
                if (targetClanId == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text("Por favor, selecione um clã alvo."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  final clanService = Provider.of<ClanService>(context, listen: false);
                  final clanWar = await clanService.declareWar(widget.clan.id, targetClanId!);
                  if (clanWar != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Guerra declarada com sucesso!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Falha ao declarar guerra."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e, s) {
                  Logger.error("Erro ao declarar guerra:", error: e, stackTrace: s);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro ao declarar guerra: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //  Obtém os serviços necessários do Provider
    final permissionService = Provider.of<PermissionService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Verifica se o usuário tem permissão para gerenciar o clã
    final bool canManage = permissionService.canManageClan(widget.clan);
    final bool canDeclareWar = permissionService.canDeclareWar(widget.clan);

    // Define as abas com base na permissão
    final List<Widget> tabs = [
      const Tab(text: 'Membros'),
      if (canManage) const Tab(text: 'Configurações'), //  Aba condicional
    ];

    final List<Widget> tabViews = [
      MembersTab(clanId: widget.clan.id, clan: widget.clan),
      if (canManage) SettingsTab(clanId: widget.clan.id), //  View da aba condicional
    ];

    return DefaultTabController(
      length: tabs.length, // O tamanho agora é dinâmico
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.clan.name),
          actions: [
                        // Botão para iniciar chamada Jitsi (apenas áudio)
            if (canManage)
              IconButton(
                icon: const Icon(Icons.call_end, color: Colors.green), // Ícone de chamada
                onPressed: () async {
                  final voipService = Provider.of<VoIPService>(context, listen: false);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final currentUser = authProvider.currentUser;

                  if (currentUser != null) {
                    try {
                      // Gerar um roomId único para o clã
                      final roomId = VoIPService.generateRoomId(prefix: 'clan', entityId: widget.clan.id);
                      await voipService.startVoiceCall(
                        roomId: roomId,
                        displayName: currentUser.username,
                        isAudioOnly: true, // Forçar áudio apenas
                      );
                    } catch (e, s) {
                      Logger.error("Erro ao iniciar chamada Jitsi para o clã:", error: e, stackTrace: s);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erro ao iniciar chamada: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                tooltip: 'Iniciar Chamada de Voz do Clã',
              ),
            //  Botão condicional para declarar guerra
            if (canDeclareWar)
              IconButton(
                icon: const Icon(Icons.gavel),
                onPressed: _showDeclareWarDialog,
                tooltip: 'Declarar Guerra',
              ),
            //  Poderíamos adicionar um menu com mais ações de gerenciamento aqui
            if (canManage)
              PopupMenuButton<String>(
                onSelected: (value) {
                  // Lógica para cada ação do menu
                  if (value == 'edit') {
                    // Navegar para a tela de edição do clã
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Editar Detalhes'),
                  ),
                  // Adicionar mais opções aqui
                ],
              ),
          ],
          bottom: TabBar(
            tabs: tabs, // Usa a lista de abas dinâmica
          ),
        ),
        body: TabBarView(
          children: tabViews, // Usa a lista de views dinâmica
        ),
      ),
    );
  }
}
