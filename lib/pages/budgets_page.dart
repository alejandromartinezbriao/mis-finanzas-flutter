import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaction_model.dart';
import 'package:mis_finanzas/pages/setup_page.dart';
import '../utils/icon_utils.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final FirebaseService _service = FirebaseService();
  DateTime _viewingDate = DateTime.now();

  final NumberFormat _uyuFormat = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 0, customPattern: '\u00A4#0');

  @override
  Widget build(BuildContext context) {
    final monthYearLabel = DateFormat('MMMM yyyy', 'es_ES').format(_viewingDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Presupuesto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/setup'),
          )
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(monthYearLabel),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
              builder: (context, txSnapshot) {
                if (txSnapshot.hasError) return Center(child: Text('Error Transacciones: ${txSnapshot.error}'));
                if (!txSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final transactions = txSnapshot.data!.where((t) => t.type == 'EXPENSE').toList();

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _service.getCategories(type: 'EXPENSE'),
                  builder: (context, catSnapshot) {
                    if (catSnapshot.hasError) return Center(child: Text('Error Categorías: ${catSnapshot.error}'));
                    if (!catSnapshot.hasData) return const SizedBox();
                    final categories = catSnapshot.data!;

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _service.getBudgets(_viewingDate.month, _viewingDate.year),
                      builder: (context, budSnapshot) {
                        if (budSnapshot.hasError) return Center(child: Text('Error Presupuestos: ${budSnapshot.error}'));
                        final budgets = budSnapshot.data ?? [];
                        
                        // Solo mostrar categorías que tengan presupuesto O tengan gastos
                        final relevantCategories = categories.where((cat) {
                          final hasBudget = budgets.any((b) => b['categoryName'] == cat['name'] && (b['amount'] ?? 0) > 0);
                          final hasSpent = transactions.any((t) => t.category == cat['name']);
                          return hasBudget || hasSpent;
                        }).toList();

                        if (relevantCategories.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('No hay presupuestos definidos para este mes.'),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => SetupPage(initialIndex: 4))
                                  ),
                                  child: const Text('Configurar Presupuestos'),
                                )
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: relevantCategories.length,
                          itemBuilder: (context, index) {
                            final cat = relevantCategories[index];
                            final budget = budgets.firstWhere(
                              (b) => b['categoryName'] == cat['name'],
                              orElse: () => {'amount': 0.0, 'currency': 'UYU'},
                            );
                            
                            final String budgetCurrency = budget['currency'] ?? 'UYU';
                            final budgetAmount = (budget['amount'] as num).toDouble();
                            final spentAmount = transactions
                                .where((t) => t.category == cat['name'] && t.currency == budgetCurrency)
                                .fold(0.0, (sum, t) => sum + t.amount);

                            return _buildBudgetProgressCard(cat, budgetAmount, spentAmount, budgetCurrency);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(String label) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _viewingDate = DateTime(_viewingDate.year, _viewingDate.month - 1)),
          ),
          Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _viewingDate = DateTime(_viewingDate.year, _viewingDate.month + 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgressCard(Map<String, dynamic> cat, double budget, double spent, String currency) {
    final percent = budget > 0 ? (spent / budget).clamp(0.0, 1.2) : 0.0;
    final isOver = spent > budget && budget > 0;
    final Color catColor = Color(cat['color'] ?? 0xFF9E9E9E);
    final format = currency == 'UYU' 
        ? NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 0, customPattern: '¤#0')
        : NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 2, customPattern: '¤#0.00');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconUtils.getIconData(cat['icon']), color: catColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (isOver)
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gastado: ${format.format(spent)}', style: TextStyle(color: isOver ? Colors.red : null, fontWeight: isOver ? FontWeight.bold : null)),
                Text('Presupuesto: ${budget > 0 ? format.format(budget) : "Sin definir"}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent > 1.0 ? 1.0 : percent,
                minHeight: 10,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: isOver ? Colors.red : (percent > 0.8 ? Colors.orange : catColor),
              ),
            ),
            if (budget > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${(percent * 100).toStringAsFixed(1)}% consumido',
                  style: TextStyle(fontSize: 11, color: isOver ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
