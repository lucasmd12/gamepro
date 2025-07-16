import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class FederationManagementScreen extends StatefulWidget {
  final String federationId;

  const FederationManagementScreen({super.key, required this.federationId});

  @override
  State<FederationManagementScreen> createState() => _FederationManagementScreenState();
}

class _FederationManagementScreenState extends State<FederationManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Federation? _federation;
  bool _isLoadingFederation = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFederationDetails();
  }

  Future<void> _loadFederationDetails() async {
    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      final federationDetails = await federationService.getFederationDetails(widget.federationId);
      if (mounted) {
        setState(() {
          _federation = federationDetails;
          _isLoadingFederation = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar detalhes da federação', error: e);
      if (mounted) {
        setState(() {
          _isLoadingFederation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentUser;

        // Verificar se o usuário é líder de federação ou admin geral
        if (currentUser?.role != Role.federationLeader && currentUser?.role != Role.admMaster) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Acesso Negado'),
              backgroundColor: Colors.red,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Acesso restrito a líderes de federação ou ADM Master',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_tree,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Gerenciamento da Federação'),
              ],
            ),
            backgroundColor: Colors.purple.shade900,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade400,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Dashboard', icon: Icon(Icons.dashboard, size: 16)),
                Tab(text: 'Clãs', icon: Icon(Icons.groups, size: 16)),
                Tab(text: 'Configurações', icon: Icon(Icons.settings, size: 16)),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade900,
                  Colors.black,
                ],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: _isLoadingFederation
                  ? [const Center(child: CircularProgressIndicator())]
                  : _federation == null
                      ? [const Center(child: Text('Federação não encontrada', style: TextStyle(color: Colors.white)))]
                      : [
                          // TODO: Implementar FederationInfoWidget
                          Center(child: Text('Dashboard da Federação para ${_federation!.name}', style: TextStyle(color: Colors.white))),
                          // TODO: Implementar FederationClansTab
                          Center(child: Text('Lista de Clãs da Federação ${_federation!.name}', style: TextStyle(color: Colors.white))),
                          // TODO: Implementar FederationSettingsTab
                          Center(child: Text('Configurações da Federação ${_federation!.name}', style: TextStyle(color: Colors.white))),
                        ],
            ),
          ),
        );
      },
    );
  }
}


