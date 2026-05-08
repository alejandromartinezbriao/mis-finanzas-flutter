import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../utils/icon_utils.dart';
import '../../utils/currency_formatter.dart';

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
                      
                      final String budgetCurrency = budget['currency'] ?? 'UYU';
                      final controller = TextEditingController(
                        text: (budget['amount'] as num) > 0 
                            ? CurrencyUtils.formatForInput((budget['amount'] as num).toDouble())
                            : '',
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(cat['color'] ?? 0xFF9E9E9E).withValues(alpha: 0.1),
                          child: Icon(IconUtils.getIconData(cat['icon']), color: Color(cat['color'] ?? 0xFF9E9E9E)),
                        ),
                        title: Text(cat['name']),
                        trailing: SizedBox(
                          width: 180,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              DropdownButton<String>(
                                value: budgetCurrency,
                                underline: const SizedBox(),
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (newCurrency) {
                                  if (newCurrency != null) {
                                    final amount = double.tryParse(controller.text) ?? 0.0;
                                    widget.service.setBudget(
                                      cat['name'], 
                                      amount, 
                                      _budgetDate.month, 
                                      _budgetDate.year, 
                                      newCurrency
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                                  textAlign: TextAlign.end,
                                  decoration: InputDecoration(
                                    prefixText: budgetCurrency == 'UYU' ? r'$ ' : r'U$S ',
                                    hintText: '0',
                                    border: const UnderlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (val) {
                                    final amount = double.tryParse(val) ?? 0.0;
                                    widget.service.setBudget(
                                      cat['name'], 
                                      amount, 
                                      _budgetDate.month, 
                                      _budgetDate.year, 
                                      budgetCurrency
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
