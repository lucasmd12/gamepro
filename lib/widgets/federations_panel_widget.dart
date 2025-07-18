import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class FederationsPanelWidget extends StatefulWidget {
  const FederationsPanelWidget({super.key});

  @override
  State<FederationsPanelWidget> createState() => _FederationsPanelWidgetState();
}

class _FederationsPanelWidgetState extends State<FederationsPanelWidget> {
  List<Federation> _federations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
 _loadFederations();
 });
  }

  Future<void> _loadFederations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
 });    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      final federations = await federationService.getAllFederations();
      if (mounted) {
        setState(() {
          _federations = federations;
        });
      }
    } catch (e, s) {
      Logger.error('Error loading federations for panel:', error: e, stackTrace: s);
      // Optionally show an error message
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
    return Card(
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Federações',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _federations.isEmpty
                    ? const Text(
                        'Nenhuma federação encontrada.',
                        style: TextStyle(color: Colors.white70),
                      )
                    : ListView.builder(
                        shrinkWrap: true, // Important for ListView inside Column
                        physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
                        itemCount: _federations.length,
                        itemBuilder: (context, index) {
                          final federation = _federations[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              federation.name ?? 'Federação sem nome',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}