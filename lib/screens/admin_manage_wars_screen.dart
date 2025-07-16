import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/clan_war_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';

class AdminManageWarsScreen extends StatefulWidget {
  const AdminManageWarsScreen({super.key});

  @override
  State<AdminManageWarsScreen> createState() => _AdminManageWarsScreenState();
}

class _AdminManageWarsScreenState extends State<AdminManageWarsScreen> {
  List<ClanWarModel> _activeWars = [];
  bool _isLoading = false;
  late final ClanService _clanService;

  @override
  void initState() {
    super.initState();
    _loadActiveWars();
  }

  Future<void> _loadActiveWars() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _clanService = Provider.of<ClanService>(context, listen: false);
      final wars = await _clanService.getActiveWars(); // Assuming getActiveWars returns List<ClanWarModel>
      if (mounted) {
        setState(() {
          _activeWars = wars;
        });
      }
    } catch (e, s) {
      Logger.error('Error loading active wars:', error: e, stackTrace: s);
      if (mounted) {
        CustomSnackbar.showError(context, 'Erro ao carregar guerras ativas: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleWarAction(String warId, String action) async {
    try {
 ClanWarModel? warResult = null;
      String message = '';
      // Placeholder values - TODO: Implement UI to collect actual data
      String placeholderWinnerId = 'placeholder_winner_id';
      String placeholderLoserId = 'placeholder_loser_id';
      Map<String, int> placeholderScore = {'placeholder_key': 0};

      switch (action) {
        case 'accept':
 warResult = await _clanService.acceptWar(warId);
          message = 'Guerra aceita com sucesso!';
          break;
        case 'reject':
 warResult = await _clanService.rejectWar(warId);
          message = 'Guerra rejeitada com sucesso!';
          break;
        case 'cancel':
 warResult = await _clanService.cancelWar(warId, 'Cancelled by Admin'); // TODO: Allow admin to provide a reason
          message = 'Guerra cancelada com sucesso!';
          break;
        case 'report_win':
 warResult = await _clanService.reportWarResult(warId, placeholderWinnerId, placeholderLoserId, placeholderScore); // TODO: Implement UI to select winner/loser and input score
          message = 'Resultado de vitória reportado com sucesso!';
          break;
        case 'report_loss':
 warResult = await _clanService.reportWarResult(warId, placeholderWinnerId, placeholderLoserId, placeholderScore); // TODO: Implement UI to select winner/loser and input score
          message = 'Resultado de derrota reportado com sucesso!';
          break;
        case 'report_draw':
 warResult = await _clanService.reportWarResult(warId, placeholderWinnerId, placeholderLoserId, placeholderScore); // TODO: Implement UI to select winner/loser and input score
          message = 'Resultado de empate reportado com sucesso!';
          break;
      }

      if (warResult != null) {
        // Refine success message based on action for clarity
        String specificMessage = '';
        if (action == 'accept') specificMessage = 'Guerra aceita!';
        else if (action == 'reject') specificMessage = 'Guerra rejeitada!';
        else if (action == 'cancel') specificMessage = 'Guerra cancelada!';
        else if (action.startsWith('report')) specificMessage = 'Resultado reportado!';
        CustomSnackbar.showSuccess(context, specificMessage);
        CustomSnackbar.showSuccess(context, message);
        _loadActiveWars(); // Refresh list
      } else {
        CustomSnackbar.showError(context, 'Falha na ação: $message');
      }
    } catch (e, s) {
      Logger.error('Error handling war action:', error: e, stackTrace: s);
      CustomSnackbar.showError(context, 'Erro ao executar ação: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Guerras'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeWars.isEmpty
              ? const Center(child: Text('Nenhuma guerra ativa encontrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _activeWars.length,
                  itemBuilder: (context, index) {
                    final war = _activeWars[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${war.challengerClan?.name ?? 'Clã Desafiante'} vs ${war.challengedClan?.name ?? 'Clã Desafiado'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text('Status: ${war.status}'),
                            Text('Início: ${war.startTime.toLocal().toString().split('.')[0]}'),
                            Text('Fim: ${war.endTime.toLocal().toString().split('.')[0]}'),
                            // Display result if war has ended
                            if (war.winnerClanId != null) // Use winnerClanId to determine the winner
                              Text('Vencedor: ${war.challengerClan?.id == war.winnerClanId ? war.challengerClan?.name ?? 'Clã Desafiante' : war.challengedClan?.name ?? 'Clã Desafiado'}')
                            else if (war.status == ClanWarStatus.completed) // Check if completed for draw
                              const Text('Resultado: Empate'),
                            const SizedBox(height: 16.0),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: [
                                if (war.status == ClanWarStatus.pending) ...[
                                  ElevatedButton(
                                    onPressed: () => _handleWarAction(war.id, 'accept'),
                                    child: const Text('Aceitar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _handleWarAction(war.id, 'reject'), // Keep action as string for handler logic
                                    child: const Text('Rejeitar'),
                                  ),
                                ],
                                if (war.status == 'active') ...[
                                  ElevatedButton(
                                    onPressed: () => _handleWarAction(war.id, 'report_win'),
                                    child: const Text('Reportar Vitória'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _handleWarAction(war.id, 'report_loss'),
                                    child: const Text('Reportar Derrota'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _handleWarAction(war.id, 'report_draw'),
                                    child: const Text('Reportar Empate'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _handleWarAction(war.id, 'cancel'),
                                    child: const Text('Cancelar'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


