import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // Importar Provider
import '../services/api_service.dart';
import '../services/auth_service.dart';

class FederationTagManagementScreen extends StatefulWidget {
  final String federationId;
  final String federationName;
  final String currentTag;
  final Function(String) onTagUpdated;

  const FederationTagManagementScreen({
    super.key,
    required this.federationId,
    required this.federationName,
    required this.currentTag,
    required this.onTagUpdated,
  });

  @override
  _FederationTagManagementScreenState createState() => _FederationTagManagementScreenState();
}

class _FederationTagManagementScreenState extends State<FederationTagManagementScreen> {
  final TextEditingController _tagController = TextEditingController();
  bool _isUpdating = false;
  String _previewTag = '';

  @override
  void initState() {
    super.initState();
    _tagController.text = widget.currentTag;
    _previewTag = widget.currentTag;
    _tagController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _tagController.removeListener(_updatePreview);
    _tagController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    setState(() {
      _previewTag = _tagController.text.toUpperCase();
    });
  }

  Future<void> _updateTag() async {
    final tag = _tagController.text.trim();
    
    if (tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TAG não pode estar vazia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (tag.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TAG deve ter no máximo 10 caracteres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      final token = authService.token;
      if (token == null) {
        throw Exception("Token de autenticação não encontrado");
      }

      final response = await http.put(
        Uri.parse("${apiService.baseUrl}/upload/federation-tag/${widget.federationId}"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'tag': tag}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        widget.onTagUpdated(responseData['tag']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TAG da federação atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } else {
        throw Exception(responseData['error'] ?? 'Erro ao atualizar TAG');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar TAG: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'TAG - ${widget.federationName}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isUpdating)
            TextButton(
              onPressed: _updateTag,
              child: const Text(
                'Salvar',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Preview da TAG
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Preview da TAG',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _previewTag.isEmpty ? 'TAG' : '[$_previewTag]',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nome do Usuário',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Campo de entrada da TAG
            const Text(
              'TAG da Federação',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagController,
              enabled: !_isUpdating,
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Digite a TAG da federação',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF2D2D2D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                counterStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.tag, color: Colors.blue),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Indicador de carregamento
            if (_isUpdating)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Atualizando TAG...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            
            // Botão de atualizar
            if (!_isUpdating)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _updateTag,
                  icon: const Icon(Icons.save),
                  label: const Text('Atualizar TAG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 30),
            
            // Informações sobre a TAG
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sobre a TAG da federação:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• A TAG aparece antes do nome de todos os membros\n'
                    '• Máximo de 10 caracteres\n'
                    '• Deve ser única (não pode repetir)\n'
                    '• Aparece automaticamente convertida para maiúsculas\n'
                    '• Representa a identidade da federação no aplicativo',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Aviso sobre permissões
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Apenas ADM e líderes de clã da federação podem alterar a TAG. Esta mudança afetará todos os membros da federação.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Exemplo de como aparece
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Como aparece no aplicativo:',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_previewTag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '[$_previewTag]',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Text(
                        'Nome do Usuário',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

