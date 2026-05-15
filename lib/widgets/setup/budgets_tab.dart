import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../utils/icon_utils.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/dialog_utils.dart';

class BudgetsTab extends StatefulWidget {
  final FirebaseService service;

  const BudgetsTab({
    super.key,
    required this.service,
  });

  @override
  State<BudgetsTab> createState() => _BudgetsTabState();
}

class _BudgetsTabState extends State<BudgetsTab> {
  DateTime _budgetDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'es_ES').format(_budgetDate).toUpperCase();
    
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _budgetDate = DateTime(_budgetDate.year, _budgetDate.month - 1)),
              ),
              const SizedBox(width: 10),
              Text(
                monthLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.1),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _budgetDate = DateTime(_budgetDate.year, _budgetDate.month + 1)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.service.getCategories(type: 'EXPENSE'),
            builder: (context, catSnap) {
              if (catSnap.hasError) return Center(child: Text('Error: ${catSnap.error}'));
              if (!catSnap.hasData) return const Center(child: CircularProgressIndicator());
              final categories = catSnap.data!;
              
              if (categories.isEmpty) {
                return const Center(child: Text('Crea categorías de GASTO primero.'));
              }
              
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.service.getBudgets(_budgetDate.month, _budgetDate.year),
                builder: (context, budSnap) {
                  if (budSnap.hasError) return Center(child: Text('Error Presupuestos: ${budSnap.error}'));
                  final budgets = budSnap.data ?? [];
                  
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final budget = budgets.firstWhere(
                        (b) => b['categoryName'] == cat['name'],
                        orElse: () => {'amount': 0.0, 'currency': 'UYU'},
                      );
                      
                      final double budgetAmount = (budget['amount'] as num).toDouble();
                      final String budgetCurrency = budget['currency'] ?? 'UYU';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(cat['color'] ?? 0xFF9E9E9E).withValues(alpha: 0.1),
                          child: Icon(IconUtils.getIconData(cat['icon']), color: Color(cat['color'] ?? 0xFF9E9E9E)),
                        ),
                        title: Text(cat['name']),
                        subtitle: Text(
                          budgetAmount > 0 
                            ? 'Presupuesto: $budgetCurrency $budgetAmount'
                            : 'Sin presupuesto definido',
                          style: TextStyle(
                            fontSize: 12, 
                            color: budgetAmount > 0 ? Colors.teal : Colors.grey,
                            fontWeight: budgetAmount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.blue),
                          onPressed: () => _showEditBudgetDialog(context, cat, budget),
                        ),
                        onTap: () => _showEditBudgetDialog(context, cat, budget),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditBudgetDialog(BuildContext context, Map<String, dynamic> cat, Map<String, dynamic> budget) {
    final amountCtrl = TextEditingController(
      text: (budget['amount'] as num) > 0 
          ? CurrencyUtils.formatForInput((budget['amount'] as num).toDouble()) 
          : ''
    );
    String selectedCurrency = budget['currency'] ?? 'UYU';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: Row(
            children: [
              Icon(IconUtils.getIconData(cat['icon']), color: Color(cat['color'] ?? 0xFF9E9E9E)),
              const SizedBox(width: 10),
              Expanded(child: Text('Presupuesto: ${cat['name']}')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Define el tope de gasto mensual para esta categoría.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Monto Máximo',
                        border: OutlineInputBorder(),
                        helperText: 'Usa punto (.) para decimales.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCurrency,
                        items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setS(() => selectedCurrency = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final double amount = double.tryParse(amountCtrl.text) ?? 0.0;
                
                final confirm = await DialogUtils.confirmAction(
                  context,
                  title: 'Confirmar Presupuesto',
                  message: '¿Deseas registrar un presupuesto de $selectedCurrency $amount para ${cat['name']} en el mes de ${DateFormat('MMMM', 'es_ES').format(_budgetDate)}?',
                  confirmText: 'Registrar',
                );

                if (confirm == true) {
                  await widget.service.setBudget(
                    cat['name'], 
                    amount, 
                    _budgetDate.month, 
                    _budgetDate.year, 
                    selectedCurrency
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
