import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class CategoryDistributionDialog extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<Map<String, dynamic>> categories;
  final NumberFormat uyuFormat;
  final NumberFormat usdFormat;

  const CategoryDistributionDialog({
    super.key,
    required this.transactions,
    required this.categories,
    required this.uyuFormat,
    required this.usdFormat,
  });

  @override
  State<CategoryDistributionDialog> createState() => _CategoryDistributionDialogState();
}

class _CategoryDistributionDialogState extends State<CategoryDistributionDialog> {
  late Map<String, double> uyuTotals;
  late Map<String, double> usdTotals;
  late bool isUYU;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  void _processData() {
    uyuTotals = {};
    usdTotals = {};
    
    final expenses = widget.transactions.where((t) => t.type == 'EXPENSE').toList();
    
    for (var t in expenses) {
      if (t.currency == 'UYU') {
        uyuTotals[t.category] = (uyuTotals[t.category] ?? 0) + t.amount;
      } else {
        usdTotals[t.category] = (usdTotals[t.category] ?? 0) + t.amount;
      }
    }
    
    isUYU = uyuTotals.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final totals = isUYU ? uyuTotals : usdTotals;
    
    if (totals.isEmpty) {
      return AlertDialog(
        title: const Text('Distribución por Categoría'),
        content: const Text('No hay egresos registrados en esta moneda.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))
        ],
      );
    }

    final totalSum = totals.values.fold(0.0, (sum, v) => sum + v);

    return AlertDialog(
      title: const Text('Distribución por Categoría'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (uyuTotals.isNotEmpty && usdTotals.isNotEmpty)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text(r'Pesos ($)')),
                  ButtonSegment(value: false, label: Text(r'Dólares (U$S)')),
                ],
                selected: {isUYU},
                onSelectionChanged: (val) => setState(() => isUYU = val.first),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: totals.entries.map((e) {
                    final cat = widget.categories.firstWhere((c) => c['name'] == e.key, orElse: () => {});
                    final color = cat['color'] != null ? Color(cat['color']) : Colors.grey;
                    final percent = (e.value / totalSum * 100);
                    return PieChartSectionData(
                      color: color,
                      value: e.value,
                      title: percent > 5 ? '${percent.toStringAsFixed(0)}%' : '',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: totals.entries.map((e) {
                    final cat = widget.categories.firstWhere((c) => c['name'] == e.key, orElse: () => {});
                    final color = cat['color'] != null ? Color(cat['color']) : Colors.grey;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(backgroundColor: color, radius: 6),
                      title: Text(e.key, style: const TextStyle(fontSize: 13)),
                      trailing: Text(
                        isUYU ? widget.uyuFormat.format(e.value) : widget.usdFormat.format(e.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))
      ],
    );
  }
}
