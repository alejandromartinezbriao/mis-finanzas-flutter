import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';
import '../utils/export_utils.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FirebaseService _service = FirebaseService();
  String _currency = 'UYU';
  final int _monthCount = 6;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime start = DateTime(now.year, now.month - _monthCount + 1, 1);
    DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Histórico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar a CSV',
            onPressed: () async {
              // Obtener todos los datos del stream actual (basado en el rango start/end)
              final txs = await _service.getTransactionsInRange(start, end).first;
              if (txs.isNotEmpty) {
                await ExportUtils.exportToCSV(txs, 'Histórico 6 Meses');
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'UYU', label: Text('UYU')),
                ButtonSegment(value: 'USD', label: Text('USD')),
              ],
              selected: {_currency},
              onSelectionChanged: (val) => setState(() => _currency = val.first),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getCategories(type: 'EXPENSE'),
        builder: (context, catSnapshot) {
          final masterCategories = catSnapshot.data ?? [];

          return StreamBuilder<List<TransactionModel>>(
            stream: _service.getTransactionsInRange(start, end),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final txs = snapshot.data!.where((t) => t.currency == _currency).toList();
              final data = _processHistoricalData(txs, now);
              
              // Categorías que el usuario definió
              final masterCategoryNames = masterCategories.map((c) => c['name'] as String).toSet();
              
              // Todas las categorías que aparecen en los gastos reales
              final actualCategories = txs
                  .where((t) => t.type == 'EXPENSE')
                  .map((t) => t.category)
                  .toSet();

              // Separar: Definidas por el usuario vs Automáticas/Sistema
              final userDefinedInUse = actualCategories.where((c) => masterCategoryNames.contains(c)).toList()..sort();
              final systemCategories = actualCategories.where((c) => !masterCategoryNames.contains(c)).toList()..sort();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummary(data),
                    const SizedBox(height: 30),
                    const Text('EVOLUCIÓN MENSUAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: _buildBarChart(data),
                    ),
                    const SizedBox(height: 40),
                    const Text('ANÁLISIS POR CATEGORÍA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 15),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Todas'),
                              selected: _selectedCategory == null,
                              onSelected: (val) => setState(() => _selectedCategory = null),
                            ),
                          ),
                          // Mostrar primero las definidas por el usuario
                          ...userDefinedInUse.map((cat) {
                            final catData = masterCategories.firstWhere((c) => c['name'] == cat);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(Icons.label, size: 16, color: Color(catData['color'] ?? 0xFF9E9E9E)),
                                label: Text(cat),
                                selected: _selectedCategory == cat,
                                onSelected: (val) => setState(() => _selectedCategory = val ? cat : null),
                              ),
                            );
                          }),
                          // Luego las de sistema (Tarjeta, Fijo, Otros)
                          if (systemCategories.isNotEmpty) ...[
                            const VerticalDivider(),
                            ...systemCategories.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat, style: const TextStyle(fontStyle: FontStyle.italic)),
                                selected: _selectedCategory == cat,
                                onSelected: (val) => setState(() => _selectedCategory = val ? cat : null),
                              ),
                            )),
                          ]
                        ],
                      ),
                    ),
                    if (_selectedCategory != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: _buildCategoryChart(txs, _selectedCategory!, now),
                      ),
                    ],
                    const SizedBox(height: 30),
                    const Text('DETALLES POR MES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12, color: Colors.grey)),
                    _buildDetailsList(data),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<_MonthlyData> _processHistoricalData(List<TransactionModel> txs, DateTime now) {
    List<_MonthlyData> result = [];
    for (int i = _monthCount - 1; i >= 0; i--) {
      DateTime d = DateTime(now.year, now.month - i, 1);
      double income = txs.where((t) => t.date.month == d.month && t.date.year == d.year && t.type == 'INCOME').fold(0, (sum, t) => sum + t.amount);
      double expense = txs.where((t) => t.date.month == d.month && t.date.year == d.year && t.type == 'EXPENSE').fold(0, (sum, t) => sum + t.amount);
      result.add(_MonthlyData(month: d.month, year: d.year, income: income, expense: expense));
    }
    return result;
  }

  Widget _buildSummary(List<_MonthlyData> data) {
    double totalIncome = data.fold(0, (sum, d) => sum + d.income);
    double totalExpense = data.fold(0, (sum, d) => sum + d.expense);
    
    // Contar solo meses que tienen al menos un movimiento (Ingreso o Gasto)
    int monthsWithData = data.where((d) => d.income > 0 || d.expense > 0).length;
    // Evitar división por cero si no hay datos
    double avgMonthly = monthsWithData > 0 ? totalExpense / monthsWithData : 0;

    final format = _currency == 'UYU' 
      ? NumberFormat.currency(locale: 'es_UY', symbol: r'$', decimalDigits: 0)
      : NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 0);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem('Ingreso Total', format.format(totalIncome), Colors.teal),
            _summaryItem('Egreso Total', format.format(totalExpense), Colors.deepOrange),
            _summaryItem('Promedio Gastos', format.format(avgMonthly), Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildBarChart(List<_MonthlyData> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue(data) * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_getMonthName(data[index].month), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(toY: e.value.income, color: Colors.teal.withOpacity(0.7), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              BarChartRodData(toY: e.value.expense, color: Colors.deepOrange.withOpacity(0.7), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailsList(List<_MonthlyData> data) {
    final format = _currency == 'UYU' 
      ? NumberFormat.currency(locale: 'es_UY', symbol: r'$', decimalDigits: 0)
      : NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 0);

    return Column(
      children: data.reversed.map((d) {
        double saving = d.income - d.expense;
        return ListTile(
          title: Text('${_getMonthName(d.month, full: true)} ${d.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Ahorro: ${format.format(saving)}', style: TextStyle(color: saving >= 0 ? Colors.teal : Colors.red)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Gasto: ${format.format(d.expense)}', style: const TextStyle(fontSize: 12)),
              Text('Ingreso: ${format.format(d.income)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChart(List<TransactionModel> txs, String category, DateTime now) {
    List<BarChartGroupData> groups = [];
    double maxVal = 0;

    for (int i = 0; i < _monthCount; i++) {
      DateTime d = DateTime(now.year, now.month - (_monthCount - 1 - i), 1);
      double total = txs
          .where((t) => t.category == category && t.date.month == d.month && t.date.year == d.year)
          .fold(0, (sum, t) => sum + t.amount);
      
      if (total > maxVal) maxVal = total;
      
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: total,
            color: Theme.of(context).colorScheme.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal == 0 ? 100 : maxVal * 1.2,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                DateTime d = DateTime(now.year, now.month - (_monthCount - 1 - idx), 1);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_getMonthName(d.month), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }

  double _getMaxValue(List<_MonthlyData> data) {
    double max = 0;
    for (var d in data) {
      if (d.income > max) max = d.income;
      if (d.expense > max) max = d.expense;
    }
    return max == 0 ? 100 : max;
  }

  String _getMonthName(int month, {bool full = false}) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    const monthsFull = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return full ? monthsFull[month - 1] : months[month - 1];
  }
}

class _MonthlyData {
  final int month;
  final int year;
  final double income;
  final double expense;

  _MonthlyData({required this.month, required this.year, required this.income, required this.expense});
}
