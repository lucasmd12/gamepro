import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/clan_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/clan_detail_screen.dart';
import 'package:lucasbeatsfederacao/screens/federation_text_chat_screen.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_clans_screen.dart'; // Import AdminManageClansScreen

class FederationDetailScreen extends StatefulWidget {
  final Federation federation;

  const FederationDetailScreen({super.key, required this.federation});

  @override
  State<FederationDetailScreen> createState() => _FederationDetailScreenState();
}

class _FederationDetailScreenState extends State<FederationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch current user in initState
  }

  @override
  void dispose() {
    // Dispose any controllers if added later
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get AuthProvider for conditional visibility
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // Determine if the current user is the federation leader or ADM
    bool isFederationLeaderOrAdm = currentUser != null &&
        (currentUser.id == widget.federation.leader.id ||
            currentUser.role == Role.admMaster);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.federation.name ?? 'Federação sem nome'),
        actions: [
          if (widget.federation.tag != null && widget.federation.tag!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                  child: Text('[${widget.federation.tag!}]',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.federation.banner != null && widget.federation.banner!.isNotEmpty)
              Image.network(
                widget.federation.banner!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 100),
              ),
            const SizedBox(height: 16),
            Text(
              'Líder: ${widget.federation.leader.username}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.federation.description ?? 'Nenhuma descrição disponível.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Regras:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.federation.rules ?? 'Nenhuma regra definida.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Logger.info(
                    "Botão Ver Clãs pressionado para federação ${widget.federation.name}");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ClanListScreen(federationId: widget.federation.id),
                  ),
                );
              },
              child: const Text("Ver Clãs desta Federação"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Logger.info(
                    "Botão Chat da Federação pressionado para federação ${widget.federation.name}");
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FederationTextChatScreen(
                      federationId: widget.federation.id,
                      federationName: widget.federation.name,
                    ),
                  ),
                );
              },
              child: const Text("Chat da Federação"),
            ),
            const SizedBox(height: 16),
            Text(
              "Clãs na Federação:",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (widget.federation.clans.isEmpty)
              const Text('Nenhum clã nesta federação ainda.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.federation.clans.length,
                itemBuilder: (context, index) {
                  final clan = widget.federation.clans[index];
                  return ListTile(
                    title: Text(clan.name ?? 'Clã sem nome'),
                    subtitle: Text('Tag: ${clan.tag ?? 'N/A'}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ClanDetailScreen(
                              clan: clan.toClan(
                                  leaderId: widget.federation.leader.id)),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Aliados:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (widget.federation.allies.isEmpty)
              const Text('Nenhum aliado definido.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.federation.allies.length,
                itemBuilder: (context, index) {
                  final ally = widget.federation.allies[index];
                  return ListTile(
                    title: Text(ally.name ?? 'Aliado sem nome'),
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              'Inimigos:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (widget.federation.enemies.isEmpty)
              const Text('Nenhum inimigo definido.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.federation.enemies.length,
                itemBuilder: (context, index) {
                  final enemy = widget.federation.enemies[index];
                  return ListTile(
                    title: Text(enemy.name ?? 'Inimigo sem nome'),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: isFederationLeaderOrAdm
          ? FloatingActionButton(
              onPressed: () {
                Logger.info(
                    'Botão Criar Clã pressionado para federação ${widget.federation.name}');
                // Navigate to AdminManageClansScreen, passing the current federation ID
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminManageClansScreen(
                      federationId: widget.federation.id,
                    ),
                  ),
                );
              },
              tooltip: 'Criar Novo Clã nesta Federação',
              child: const Icon(Icons.add),
            )
          : null, // Hide FAB for users who are not the leader or ADM
    );
  }
}