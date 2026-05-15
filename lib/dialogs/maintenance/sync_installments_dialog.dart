import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class SyncInstallmentsDialog extends StatefulWidget {
  final FirebaseService service;
  const SyncInstallmentsDialog({super.key, required this.service});

  @override
  State<SyncInstallmentsDialog> createState() => _SyncInstallmentsDialogState();
}

class _SyncInstallmentsDialogState extends State<SyncInstallmentsDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _fixes = [];
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.service.findSyncProposals();
    if (mounted) {
      setState(() {
        _fixes = res;
        for (int i = 0; i < _fixes.length; i++) {
          _selectedIndices.add(i);
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sincronizar Montos de Cuotas'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading 
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : _fixes.isEmpty
            ? const Text('No se encontraron discrepancias en las series de cuotas.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('La app comparó los mismos consumos en distintos meses y detectó variaciones sospechosas en el monto. El "Valor Sugerido" es el que más se repite en la serie.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _fixes.length,
                      itemBuilder: (context, index) {
                        final f = _fixes[index];
                        return CheckboxListTile(
                          value: _selectedIndices.contains(index),
                          onChanged: (v) => setState(() => v! ? _selectedIndices.add(index) : _selectedIndices.remove(index)),
                          title: Text("${f['cardTitle']} (${f['month']})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "Concepto: ${f['concept']} (${f['installment']})\nActual: ${f['currency']} ${f['currentValue']} -> Sugerido: ${f['currency']} ${f['suggestedValue']}",
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
        if (_fixes.isNotEmpty)
          FilledButton(
            onPressed: _selectedIndices.isEmpty ? null : () async {
              await widget.service.applySyncFixes(_selectedIndices.map((i) => _fixes[i]).toList());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Sincronizar Seleccionados'),
          ),
      ],
    );
  }
}
