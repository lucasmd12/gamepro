import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/qrr_model.dart';
import 'package:lucasbeatsfederacao/services/qrr_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class QRREditScreen extends StatefulWidget {
  final QRRModel qrr;

  const QRREditScreen({super.key, required this.qrr});

  @override
  State<QRREditScreen> createState() => _QRREditScreenState();
}

class _QRREditScreenState extends State<QRREditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  // Removido _imageUrlController, _maxParticipantsController, _requiredRolesController

  late QRRType _selectedType;
  late QRRPriority _selectedPriority;
  DateTime? _selectedStartDate; // Alterado para _selectedStartDate
  DateTime? _selectedEndDate;   // Alterado para _selectedEndDate

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.qrr.title);
    _descriptionController = TextEditingController(text: widget.qrr.description);

    _selectedType = QRRType.values.firstWhere((e) => e.toString().split('.').last == widget.qrr.type, orElse: () => QRRType.mission);
    _selectedPriority = QRRPriority.values.firstWhere((e) => e.toString().split('.').last == widget.qrr.priority, orElse: () => QRRPriority.medium);
    _selectedStartDate = widget.qrr.startDate; // Usando startDate
    _selectedEndDate = widget.qrr.endDate;     // Usando endDate
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime((isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStartDate) {
            _selectedStartDate = selectedDateTime;
          } else {
            _selectedEndDate = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _updateQRR() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final qrrService = Provider.of<QRRService>(context, listen: false);
        final updatedQRRData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'type': _selectedType.toString().split('.').last,
          'priority': _selectedPriority.toString().split('.').last,
          'startDate': _selectedStartDate?.toIso8601String(),
          'endDate': _selectedEndDate?.toIso8601String(),
          // Removido imageUrl, maxParticipants, requiredRoles
        };

        await qrrService.updateQRR(widget.qrr.id, updatedQRRData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QRR atualizada com sucesso!')), 
          );
          Navigator.pop(context);
        }
      } catch (e) {
        Logger.error('Erro ao atualizar QRR', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar QRR: ${e.toString()}')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Missão QRR'),
        backgroundColor: Colors.grey[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título da Missão',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição da Missão',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma descrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<QRRType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Missão',
                        border: OutlineInputBorder(),
                      ),
                      items: QRRType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<QRRPriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade da Missão',
                        border: OutlineInputBorder(),
                      ),
                      items: QRRPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ListTile(
                      title: Text(
                        _selectedStartDate == null
                            ? 'Selecionar Data e Hora de Início'
                            : 'Início: ${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year} ${_selectedStartDate!.hour}:${_selectedStartDate!.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateTime(context, true),
                    ),
                    const SizedBox(height: 16.0),
                    ListTile(
                      title: Text(
                        _selectedEndDate == null
                            ? 'Selecionar Data e Hora de Término'
                            : 'Término: ${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year} ${_selectedEndDate!.hour}:${_selectedEndDate!.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDateTime(context, false),
                    ),
                    const SizedBox(height: 24.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: _updateQRR,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Atualizar Missão QRR',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


