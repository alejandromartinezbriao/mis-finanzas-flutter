import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class DecimalRepairDialog extends StatefulWidget {
  final FirebaseService service;
  const DecimalRepairDialog({super.key, required this.service});

  @override
  State<DecimalRepairDialog> createState() => _DecimalRepairDialogState();
}

class _DecimalRepairDialogState extends State<DecimalRepairDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _detections = [];
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    final results = await widget.service.findBotchedDecimals();
    if (mounted) {
      setState(() {
        _detections = results;
        // Seleccionar todos por defecto
        for (int i = 0; i < _detections.length; i++) {
          _selectedIndices.add(i);
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Revisión de Decimales (Error 100x)'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading 
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : _detections.isEmpty
            ? const Text('No se encontraron montos sospechosos.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Se detectaron montos que podrían estar multiplicados por 100 debido a errores de coma. Selecciona los que deseas corregir:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _detections.length,
                      itemBuilder: (context, index) {
                        final d = _detections[index];
                        final isSelected = _selectedIndices.contains(index);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIndices.add(index);
                              } else {
                                _selectedIndices.remove(index);
                              }
                            });
                          },
                          title: Text("${d['title']} - ${d['monthLabel']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "\"${d['partLabel']}\"\nDe: ${d['currency']} ${d['originalValue']} -> A: ${d['currency']} ${d['suggestedValue']}",
                            style: const TextStyle(fontSize: 11),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        if (_detections.isNotEmpty)
          FilledButton(
            onPressed: _selectedIndices.isEmpty ? null : () async {
              final selectedFixes = _selectedIndices.map((i) => _detections[i]).toList();
              await widget.service.applyBotchedFixes(selectedFixes);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Aplicar Seleccionados'),
          ),
      ],
    );
  }
}
