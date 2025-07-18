import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/screens/tabs/members_tab.dart'; // Import MembersTab
import 'package:lucasbeatsfederacao/screens/tabs/settings_tab.dart'; // Import SettingsTab
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';

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
    _loadClans();
  }

  bool _isAdmMaster() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.currentUser?.role == Role.admMaster;
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
      builder: (BuildContext dialogContext) { // Usar dialogContext para evitar conflito
        return AlertDialog(
          title: Text("Declarar Guerra de ${widget.clan.name}"),
          content: DropdownButtonFormField<String?>(
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
                  final clanService = Provider.of<ClanService>(dialogContext, listen: false);
                  final clanWar = await clanService.declareWar(widget.clan.id, targetClanId!);
                  if (clanWar != null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text("Guerra declarada com sucesso!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Opcional: Atualizar a lista de guerras ou navegar para a tela de guerras
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text("Falha ao declarar guerra."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e, s) {
                  Logger.error("Erro ao declarar guerra:", error: e, stackTrace: s);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
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
    return DefaultTabController( // Mover DefaultTabController para fora do Scaffold
      length: 2, // Número de tabs
      child: Scaffold( // Scaffold agora é filho do DefaultTabController
        appBar: AppBar( 
          title: Text(widget.clan.name), // Título com o nome do clã
          actions: [
            if (_isAdmMaster()) // Show declare war button only for ADM_MASTER
              IconButton(
                icon: const Icon(Icons.gavel),
                onPressed: _showDeclareWarDialog,
                tooltip: 'Declarar Guerra',
              ),
          ],
          bottom: const TabBar( // TabBar continua no bottom do AppBar
            tabs: [
              Tab(text: 'Membros'),
              Tab(text: 'Configurações'),
            ],
          ),
        ),
        body: TabBarView( // TabBarView continua no body
          children: [
            MembersTab(clanId: widget.clan.id, clan: widget.clan), // Apenas uma instância, passando o clan
            SettingsTab(clanId: widget.clan.id), // Passa o clanId para SettingsTab
          ],
        ),
      ),
    );
  }
}

