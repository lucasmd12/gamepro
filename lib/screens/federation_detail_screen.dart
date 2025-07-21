import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/services/permission_service.dart'; // IMPORT ADICIONADO
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/clan_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/clan_detail_screen.dart';
import 'package:lucasbeatsfederacao/screens/federation_text_chat_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_clans_screen.dart';

// Uma nova aba para os detalhes da federação, para manter a UI limpa
class FederationDetailsTab extends StatelessWidget {
  final Federation federation;
  const FederationDetailsTab({super.key, required this.federation});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (federation.banner != null && federation.banner!.isNotEmpty)
            Image.network(
              federation.banner!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 100),
            ),
          const SizedBox(height: 16),
          Text(
            'Líder: ${federation.leader.username}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            federation.description ?? 'Nenhuma descrição disponível.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Regras:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            federation.rules ?? 'Nenhuma regra definida.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              onPressed: () {
                Logger.info(
                    "Botão Chat da Federação pressionado para federação ${federation.name}");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FederationTextChatScreen(
                      federationId: federation.id,
                      federationName: federation.name,
                    ),
                  ),
                );
              },
              label: const Text("Entrar no Chat da Federação"),
            ),
          ),
        ],
      ),
    );
  }
}

// Uma nova aba para as configurações da federação, visível apenas para quem tem permissão
class FederationSettingsTab extends StatelessWidget {
  final Federation federation;
  const FederationSettingsTab({super.key, required this.federation});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar Detalhes da Federação'),
            onTap: () {
              // TODO: Navegar para a tela de edição da federação
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Gerenciar Clãs'),
            subtitle: const Text('Adicionar ou remover clãs da federação'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AdminManageClansScreen(
                    federationId: federation.id,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.handshake),
            title: const Text('Gerenciar Diplomacia'),
            subtitle: const Text('Definir aliados e inimigos'),
            onTap: () {
              // TODO: Navegar para a tela de gerenciamento de diplomacia
            },
          ),
        ],
      ),
    );
  }
}


class FederationDetailScreen extends StatefulWidget {
  final Federation federation;

  const FederationDetailScreen({super.key, required this.federation});

  @override
  State<FederationDetailScreen> createState() => _FederationDetailScreenState();
}

class _FederationDetailScreenState extends State<FederationDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // Obtém o PermissionService
    final permissionService = Provider.of<PermissionService>(context);

    // Verifica se o usuário pode gerenciar a federação
    final bool canManage = permissionService.canManageFederation(widget.federation);

    // Define as abas com base na permissão
    final List<Widget> tabs = [
      const Tab(text: 'Detalhes'),
      const Tab(text: 'Clãs'),
      if (canManage) const Tab(text: 'Gerenciamento'), // Aba condicional
    ];

    final List<Widget> tabViews = [
      FederationDetailsTab(federation: widget.federation),
      ClanListScreen(federationId: widget.federation.id), // Reutiliza a ClanListScreen como uma aba
      if (canManage) FederationSettingsTab(federation: widget.federation), // View da aba condicional
    ];

    return DefaultTabController(
      length: tabs.length, // O tamanho agora é dinâmico
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.federation.name),
          actions: [
            if (widget.federation.tag != null && widget.federation.tag!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '[${widget.federation.tag!}]',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
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
