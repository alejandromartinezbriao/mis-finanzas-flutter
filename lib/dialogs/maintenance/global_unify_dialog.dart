import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class GlobalUnifyDialog extends StatefulWidget {
  final FirebaseService service;
  const GlobalUnifyDialog({super.key, required this.service});

  @override
  State<GlobalUnifyDialog> createState() => _GlobalUnifyDialogState();
}

class _GlobalUnifyDialogState extends State<GlobalUnifyDialog> {
  bool isSearching = true;
  List<Map<String, dynamic>> duplicateGroups = [];

  @override
  void initState() {
    super.initState();
    _find();
  }

  Future<void> _find() async {
    setState(() => isSearching = true);
    final results = await widget.service.findGlobalDuplicates();
    setState(() {
      duplicateGroups = results;
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.language, color: Colors.teal),
          SizedBox(width: 10),
          Text('Unificación Global'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: isSearching
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text('Escaneando toda la base de datos...'),
                ],
              )
            : duplicateGroups.isEmpty
                ? const Text('¡Felicidades! No se encontraron nombres duplicados en toda tu historia financiera.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'He detectado tarjetas con nombres inconsistentes en varios meses. ¿Quieres unificarlas en toda la historia?',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 15),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: duplicateGroups.length,
                          itemBuilder: (context, index) {
                            final group = duplicateGroups[index];
                            final List<String> variations = List<String>.from(group['variations']);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(group['baseName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(group['currency'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    const Divider(),
                                    const Text('Variaciones encontradas:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ...variations.map((v) => Text('• $v', style: const TextStyle(fontSize: 12))),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.tonal(
                                        onPressed: () => _unify(group),
                                        child: const Text('Unificar en todos los meses'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }

  Future<void> _unify(Map<String, dynamic> group) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Unificación Global'),
        content: Text(
          'Se buscarán todas las ocurrencias de estas variaciones en TODOS los meses y se fusionarán en un solo registro por mes con el nombre normalizado.\n\n'
          'Esto corregirá el problema de "Cabal" y "Cabal (UYU)" definitivamente.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceder')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSearching = true);
    try {
      await widget.service.unifyGlobalTransactions(
        group['baseName'], 
        group['currency'], 
        List<String>.from(group['variations'])
      );
      _find(); // Recargar
    } catch (e) {
      setState(() => isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
