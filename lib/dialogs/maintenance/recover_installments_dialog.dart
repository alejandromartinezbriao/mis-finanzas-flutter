import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';

class RecoverInstallmentsDialog extends StatefulWidget {
  final FirebaseService service;

  const RecoverInstallmentsDialog({super.key, required this.service});

  @override
  State<RecoverInstallmentsDialog> createState() => _RecoverInstallmentsDialogState();
}

class _RecoverInstallmentsDialogState extends State<RecoverInstallmentsDialog> {
  bool isSearching = true;
  List<Map<String, dynamic>> recoveries = [];
  final Map<String, bool> selectedForRecovery = {};

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => isSearching = true);
    final results = await widget.service.findLostInstallments();
    setState(() {
      recoveries = results;
      isSearching = false;
      for (var r in results) {
        final key = "${r['cardName']}_${r['concept']}";
        selectedForRecovery[key] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.history_edu, color: Colors.blue),
          SizedBox(width: 10),
          Text('Recuperar Cuotas'),
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
                  Text('Escaneando meses futuros...'),
                ],
              )
            : recoveries.isEmpty
                ? const Text('No se detectaron cuotas faltantes en base a tus registros futuros.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'He detectado compras en cuotas que existen en el futuro pero faltan en algunos meses pasados:',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 15),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: recoveries.length,
                          itemBuilder: (context, index) {
                            final r = recoveries[index];
                            final key = "${r['cardName']}_${r['concept']}";
                            final List<int> missing = List<int>.from(r['missingInstallments']);
                            final format = r['currency'] == 'UYU' 
                                ? NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2, customPattern: '¤#0.00') 
                                : NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 2, customPattern: '¤#0.00');

                            return CheckboxListTile(
                              value: selectedForRecovery[key],
                              onChanged: (val) => setState(() => selectedForRecovery[key] = val!),
                              title: Text("${r['concept']} (${r['cardName']})", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                "Faltan cuotas: ${missing.join(', ')} de ${r['totalInstallments']}\n"
                                "Monto: ${format.format(r['amountPerInstallment'])} c/u",
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        if (recoveries.isNotEmpty)
          FilledButton(
            onPressed: _performRecovery,
            child: const Text('Restaurar Seleccionadas'),
          ),
      ],
    );
  }

  Future<void> _performRecovery() async {
    final toProcess = recoveries.where((r) {
      final key = "${r['cardName']}_${r['concept']}";
      return selectedForRecovery[key] == true;
    }).toList();

    if (toProcess.isEmpty) return;

    setState(() => isSearching = true);
    try {
      await widget.service.recoverInstallments(toProcess);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuotas restauradas correctamente en los meses correspondientes')),
        );
      }
    } catch (e) {
      setState(() => isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al restaurar: $e')));
      }
    }
  }
}
