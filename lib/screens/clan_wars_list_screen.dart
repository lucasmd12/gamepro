import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/clan_war_model.dart';
import 'package:lucasbeatsfederacao/services/clan_war_service.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class ClanWarsListScreen extends StatefulWidget {
  final String? clanId;
  final String? federationId;

  const ClanWarsListScreen({super.key, this.clanId, this.federationId});

  @override
  State<ClanWarsListScreen> createState() => _ClanWarsListScreenState();
}

class _ClanWarsListScreenState extends State<ClanWarsListScreen> {
  List<ClanWarModel> _clanWars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClanWars();
  }

  Future<void> _fetchClanWars() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final clanWarService = Provider.of<ClanWarService>(context, listen: false);
      _clanWars = await clanWarService.getClanWars(
        clanId: widget.clanId,
        federationId: widget.federationId,
      );
    } catch (e, st) {
      Logger.error('Error fetching clan wars', error: e, stackTrace: st);
      if (mounted) {
        CustomSnackbar.showError(context, 'Erro ao carregar guerras de clãs: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guerras de Clãs'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () {
              // TODO: Implement navigation to create new clan war screen/dialog
              CustomSnackbar.showInfo(context, 'Funcionalidade de criar guerra de clã em desenvolvimento.');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchClanWars,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clanWars.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma guerra de clã encontrada. Desafie um clã agora!',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: _clanWars.length,
                  itemBuilder: (context, index) {
                    final clanWar = _clanWars[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      color: Colors.grey[850],
                      child: ListTile(
                        title: Text(
                          '${clanWar.challengerClan?.name ?? 'Clã Desafiante'} vs ${clanWar.challengedClan?.name ?? 'Clã Desafiado'}\n',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), 
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${clanWar.status.toString().split('.').last}', style: const TextStyle(color: Colors.white70)),
                            Text('Início: ${clanWar.startTime.toLocal().toString().split('.')[0]}', style: const TextStyle(color: Colors.white70)),
                            Text('Fim: ${clanWar.endTime.toLocal().toString().split('.')[0]}', style: const TextStyle(color: Colors.white70)),
                            // Display result if war has ended or is completed (for draws)
                            if (clanWar.winnerClanId != null) // If there's a winner
                              Text(
                                'Vencedor: ${clanWar.challengerClan?.id == clanWar.winnerClanId ? clanWar.challengerClan?.name ?? 'Clã Desafiante' : clanWar.challengedClan?.name ?? 'Clã Desafiado'}',
                                style: const TextStyle(color: Colors.greenAccent),
                              )
                            else if (clanWar.status == ClanWarStatus.completed) // Check if completed for draw
                              const Text('Resultado: Empate', style: TextStyle(color: Colors.orangeAccent)),
                            // Display description if available
                            if (clanWar.description != null)
                              Text('Descrição: ${clanWar.description}', style: const TextStyle(color: Colors.white54)),
                          ],

                        ),
                        // TODO: Implement navigation to clan war detail screen
                        onTap: () { // Adiciona o callback onTap aqui
                          CustomSnackbar.showInfo(context, 'Detalhes da guerra de clã em desenvolvimento.');
                        }, // Fecha o callback onTap
                      ),
                    );
                  },
                ),
    );
  }
}


