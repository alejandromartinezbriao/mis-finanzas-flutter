import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../models/transaction_model.dart';
import 'package:intl/intl.dart';

class UnifyDuplicatesDialog extends StatefulWidget {
  final FirebaseService service;
  final int month;
  final int year;

  const UnifyDuplicatesDialog({
    super.key,
    required this.service,
    required this.month,
    required this.year,
  });

  @override
  State<UnifyDuplicatesDialog> createState() => _UnifyDuplicatesDialogState();
}

class _UnifyDuplicatesDialogState extends State<UnifyDuplicatesDialog> {
  bool isSearching = true;
  List<DuplicateGroup> duplicateGroups = [];

  @override
  void initState() {
    super.initState();
    _findDuplicates();
  }

  Future<void> _findDuplicates() async {
    setState(() => isSearching = true);
    try {
      final transactions = await widget.service.getTransactions(month: widget.month, year: widget.year).first;
      
      // Agrupar por nombre limpio y moneda
      final Map<String, List<TransactionModel>> groups = {};
      
      for (var t in transactions) {
        final cleanName = t.title.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim().toLowerCase();
        final key = "${cleanName}_${t.currency}";
        
        if (!groups.containsKey(key)) groups[key] = [];
        groups[key]!.add(t);
      }

      // Filtrar solo grupos con más de un elemento
      final List<DuplicateGroup> found = [];
      groups.forEach((key, list) {
        if (list.length > 1) {
          found.add(DuplicateGroup(
            baseName: list.first.title.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim(),
            currency: list.first.currency,
            transactions: list,
          ));
        }
      });

      setState(() {
        duplicateGroups = found;
        isSearching = false;
      });
    } catch (e) {
      print("Error buscando duplicados: $e");
      setState(() => isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_fix_high, color: Colors.teal),
          SizedBox(width: 10),
          Text('Unificar Registros'),
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
                  Text('Analizando movimientos del mes...'),
                ],
              )
            : duplicateGroups.isEmpty
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                      SizedBox(height: 15),
                      Text('No se encontraron registros duplicados con el mismo nombre y moneda.', textAlign: TextAlign.center),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'He encontrado registros que parecen ser el mismo. ¿Deseas unificarlos?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: duplicateGroups.length,
                          itemBuilder: (context, index) {
                            final group = duplicateGroups[index];
                            final totalAmount = group.transactions.fold(0.0, (sum, t) => sum + t.amount);
                            final format = group.currency == 'UYU' 
                                ? NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2, customPattern: '¤#0.00') 
                                : NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 2, customPattern: '¤#0.00');

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
                                        Text(group.baseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(group.currency, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    const Divider(),
                                    ...group.transactions.map((t) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text('• ${t.title}', style: const TextStyle(fontSize: 12))),
                                          Text(format.format(t.amount), style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    )),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Unificado:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        Text(format.format(totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => _unifyGroup(group),
                                        child: const Text('Unificar estos registros'),
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

  Future<void> _unifyGroup(DuplicateGroup group) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Unificación'),
        content: Text('Se combinarán los ${group.transactions.length} registros de "${group.baseName}" en uno solo con el nombre normalizado y el monto total.\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar Unificación')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSearching = true);
    try {
      await widget.service.unifyTransactions(group.transactions, group.baseName);
      _findDuplicates(); // Refrescar lista
    } catch (e) {
      print("Error unificando: $e");
      setState(() => isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al unificar: $e')));
      }
    }
  }
}

class DuplicateGroup {
  final String baseName;
  final String currency;
  final List<TransactionModel> transactions;

  DuplicateGroup({required this.baseName, required this.currency, required this.transactions});
}
