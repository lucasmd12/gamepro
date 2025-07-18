import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/invite_model.dart';
import 'package:lucasbeatsfederacao/services/invite_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:provider/provider.dart'; // Importar Provider

class InviteListScreen extends StatefulWidget {
  const InviteListScreen({super.key});

  @override
  State<InviteListScreen> createState() => _InviteListScreenState();
}

class _InviteListScreenState extends State<InviteListScreen> {
  List<InviteModel> _invites = [];
  bool _isLoading = true;
  String? _error;

  // Adicionar referência ao InviteService
  late final InviteService _inviteService;

  @override
  void initState() {
    super.initState();
    // Inicializar InviteService usando Provider
    _inviteService = Provider.of<InviteService>(context, listen: false);
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final invites = await _inviteService.getMyInvites();

      if (mounted) {
        setState(() {
          _invites = invites;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar convites', error: e);
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar convites: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvite(String inviteId) async {
    try {
      await _inviteService.acceptInvite(inviteId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convite aceito com sucesso!')), 
      );
      _loadInvites(); // Recarregar a lista
    } catch (e) {
      Logger.error('Erro ao aceitar convite', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar convite: ${e.toString()}')), 
      );
    }
  }

  Future<void> _rejectInvite(String inviteId) async {
    try {
      await _inviteService.rejectInvite(inviteId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convite rejeitado com sucesso!')), 
      );
      _loadInvites(); // Recarregar a lista
    } catch (e) {
      Logger.error('Erro ao rejeitar convite', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao rejeitar convite: ${e.toString()}')), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Convites'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            onPressed: _loadInvites,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvites,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_invites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum convite pendente.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invites.length,
      itemBuilder: (context, index) {
        final invite = _invites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey[850],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convite para ${invite.type == 'clan' ? 'o clã' : 'a federação'} ${invite.targetName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'De: ${invite.senderName}',
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _rejectInvite(invite.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Rejeitar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _acceptInvite(invite.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Aceitar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
