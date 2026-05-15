import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class TemplateReconnectDialog extends StatefulWidget {
  final FirebaseService service;
  const TemplateReconnectDialog({super.key, required this.service});

  @override
  State<TemplateReconnectDialog> createState() => _TemplateReconnectDialogState();
}

class _TemplateReconnectDialogState extends State<TemplateReconnectDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _proposals = [];
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.service.findTemplateReconnections();
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
      title: const Text('Reconectar a Plantillas'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading 
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : _proposals.isEmpty
            ? const Text('Todos los gastos están correctamente vinculados.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Se encontraron gastos sueltos que coinciden con tus plantillas fijas. Vincularlos permite un mejor control histórico.', style: TextStyle(fontSize: 13, color: Colors.grey)),
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
                          title: Text(p['title'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text("Mes: ${p['month']} -> Vincular a: ${p['templateTitle']}", style: const TextStyle(fontSize: 11)),
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
              await widget.service.applyTemplateReconnections(_selectedIndices.map((i) => _proposals[i]).toList());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Vincular Seleccionados'),
          ),
      ],
    );
  }
}
