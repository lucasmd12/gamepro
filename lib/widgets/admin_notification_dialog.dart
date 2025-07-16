import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/services/segmented_notification_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class AdminNotificationDialog extends StatefulWidget {
  const AdminNotificationDialog({super.key});

  @override
  State<AdminNotificationDialog> createState() => _AdminNotificationDialogState();
}

class _AdminNotificationDialogState extends State<AdminNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _segmentedNotificationService = SegmentedNotificationService();
  
  bool _isLoading = false;
  bool _isPreviewLoading = false;
  Map<String, dynamic>? _recipientPreview;
  String _selectedPriority = 'high';
  String _selectedSound = 'default';

  final List<Map<String, String>> _priorityOptions = [
    {'value': 'high', 'label': 'Alta'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'low', 'label': 'Baixa'},
  ];

  final List<Map<String, String>> _soundOptions = [
    {'value': 'default', 'label': 'Padrão'},
    {'value': 'notification', 'label': 'Notificação'},
    {'value': 'alert', 'label': 'Alerta'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipientPreview();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipientPreview() async {
    setState(() {
      _isPreviewLoading = true;
    });

    try {
      final preview = await _segmentedNotificationService.previewAdminRecipients();
      setState(() {
        _recipientPreview = preview;
        _isPreviewLoading = false;
      });
    } catch (error) {
      Logger.error('Error loading recipient preview: ${error.toString()}');
      setState(() {
        _isPreviewLoading = false;
      });
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    // Validação adicional
    final validation = SegmentedNotificationService.validateNotificationContent(
      title: title,
      body: body,
    );

    if (!validation['isValid']) {
      _showErrorDialog('Erro de Validação', validation['errors'].join('\n'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _segmentedNotificationService.sendAdminBroadcast(
        title: title,
        body: body,
        priority: _selectedPriority,
        sound: _selectedSound,
        data: {
          'source': 'admin_panel',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        _showSuccessDialog(result);
      } else {
        _showErrorDialog('Erro ao Enviar', result['message'] ?? 'Erro desconhecido');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      Logger.error('Error sending admin notification: ${error.toString()}');
      _showErrorDialog('Erro de Conexão', 'Não foi possível enviar a notificação. Verifique sua conexão.');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text(
              'Sucesso!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SegmentedNotificationService.formatSendResult(result),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (result['details'] != null) ...[
              const Text(
                'Detalhes:',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviadas: ${result['sent'] ?? 0}',
                style: const TextStyle(color: Colors.green),
              ),
              if ((result['failed'] ?? 0) > 0)
                Text(
                  'Falharam: ${result['failed']}',
                  style: const TextStyle(color: Colors.orange),
                ),
              Text(
                'Total: ${result['total'] ?? 0}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar dialog de sucesso
              Navigator.of(context).pop(); // Fechar dialog principal
            },
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500), // Corrigido aqui
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Enviar Notificação Global',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Preview de destinatários
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isPreviewLoading
                          ? const Text(
                              'Carregando destinatários...',
                              style: TextStyle(color: Colors.grey),
                            )
                          : Text(
                              _recipientPreview != null
                                  ? SegmentedNotificationService.formatRecipientPreview(_recipientPreview!)
                                  : 'Erro ao carregar destinatários',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                    if (!_isPreviewLoading)
                      IconButton(
                        onPressed: _loadRecipientPreview,
                        icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                        tooltip: 'Atualizar',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Campo de título
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Título da Notificação',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Ex: Manutenção programada',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  counterStyle: const TextStyle(color: Colors.grey),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Título é obrigatório';
                  }
                  if (value.trim().length < 3) {
                    return 'Título deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo de mensagem
              TextFormField(
                controller: _bodyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mensagem',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Digite sua mensagem aqui...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  counterStyle: const TextStyle(color: Colors.grey),
                ),
                maxLines: 4,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mensagem é obrigatória';
                  }
                  if (value.trim().length < 10) {
                    return 'Mensagem deve ter pelo menos 10 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Configurações avançadas
              Row(
                children: [
                  // Prioridade
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prioridade',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPriority,
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: Colors.grey[800],
                            style: const TextStyle(color: Colors.white),
                            items: _priorityOptions.map((option) {
                              return DropdownMenuItem<String>(
                                value: option['value'],
                                child: Text(option['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPriority = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Som
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Som',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedSound,
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: Colors.grey[800],
                            style: const TextStyle(color: Colors.white),
                            items: _soundOptions.map((option) {
                              return DropdownMenuItem<String>(
                                value: option['value'],
                                child: Text(option['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSound = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendNotification,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(_isLoading ? 'Enviando...' : 'Enviar Notificação'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


