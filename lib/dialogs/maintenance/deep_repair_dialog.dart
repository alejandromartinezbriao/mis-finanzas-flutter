import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class DeepRepairDialog extends StatefulWidget {
  final FirebaseService service;
  const DeepRepairDialog({super.key, required this.service});

  @override
  State<DeepRepairDialog> createState() => _DeepRepairDialogState();
}

class _DeepRepairDialogState extends State<DeepRepairDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _proposals = [];
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.service.findDeepRepairProposals();
    if (mounted) {
      setState(() {
        _proposals = res;
        for (int i = 0; i < _proposals.length; i++) {
          _selectedIndices.add(i);
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reparación de Duplicados Internos'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading 
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : _proposals.isEmpty
            ? const Text('No se detectaron duplicados dentro de las listas de consumos.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Se detectaron consumos repetidos dentro de un mismo registro de tarjeta. La reparación dejará solo uno de cada uno y recalculará el total.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _proposals.length,
                      itemBuilder: (context, index) {
                        final p = _proposals[index];
                        return CheckboxListTile(
                          value: _selectedIndices.contains(index),
                          onChanged: (v) => setState(() => v! ? _selectedIndices.add(index) : _selectedIndices.remove(index)),
                          title: Text("${p['title']} (${p['month']})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text("Duplicados: ${p['duplicates'].join(', ')}", style: const TextStyle(fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        if (_proposals.isNotEmpty)
          FilledButton(
            onPressed: _selectedIndices.isEmpty ? null : () async {
              await widget.service.applyDeepRepairFixes(_selectedIndices.map((i) => _proposals[i]).toList());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Reparar Seleccionados'),
          ),
      ],
    );
  }
}
