import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _service = FirebaseService();
  
  // Estado para controlar el mes y año que estamos viendo
  DateTime _viewingDate = DateTime.now();

  final NumberFormat _uyuFormat = NumberFormat.currency(locale: 'es_UY', symbol: '\$', decimalDigits: 0);
  final NumberFormat _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: 'U\$S', decimalDigits: 2);

  void _changeMonth(int delta) {
    setState(() {
      _viewingDate = DateTime(_viewingDate.year, _viewingDate.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Formatear el mes y año para el título
    String monthYearLabel = DateFormat('MMMM yyyy', 'es_ES').format(_viewingDate);
    monthYearLabel = monthYearLabel[0].toUpperCase() + monthYearLabel.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuentas'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/setup'),
            tooltip: 'Configuración Maestra',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Limpiar este mes?'),
                    content: const Text('Se borrarán TODOS los movimientos de este mes. Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Borrar Todo', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _service.clearMonth(_viewingDate.month, _viewingDate.year);
                }
              } else if (value == 'generate') {
                await _service.generateMonthlyTransactions(_viewingDate.month, _viewingDate.year);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Plantillas cargadas para ' + DateFormat('MMMM', 'es_ES').format(_viewingDate))),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Cargar Plantillas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Limpiar todo este mes'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // SELECTOR DE MES
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  monthYearLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // LISTADO DE TRANSACCIONES FILTRADO POR MES
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data ?? [];
                
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No hay movimientos en $monthYearLabel.'),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () async {
                            // GENERAR EL MES QUE ESTAMOS VIENDO
                            await _service.generateMonthlyTransactions(_viewingDate.month, _viewingDate.year);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Mes de $monthYearLabel generado con éxito')),
                              );
                            }
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Cargar Plantillas de este Mes'),
                        ),
                      ],
                    ),
                  );
                }
                
                // Cálculo de Totales
                double incomeUYU = transactions.where((t) => t.type == 'INCOME' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
                double expenseUYU = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
                double incomeUSD = transactions.where((t) => t.type == 'INCOME' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
                double expenseUSD = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);

                // --- LÓGICA DE AGRUPACIÓN Y ORDENAMIENTO ---
                final incomes = transactions
                    .where((t) => t.type == 'INCOME')
                    .toList()
                  ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

                final expenses = transactions
                    .where((t) => t.type == 'EXPENSE')
                    .toList()
                  ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

                // Creamos una lista combinada con encabezados
                final sortedItems = [
                  if (incomes.isNotEmpty) 'INGRESOS',
                  ...incomes,
                  if (expenses.isNotEmpty) 'GASTOS',
                  ...expenses,
                ];

                return Column(
                  children: [
                    _buildBalanceCard(incomeUYU, expenseUYU, incomeUSD, expenseUSD),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sortedItems.length,
                        itemBuilder: (context, index) {
                          final item = sortedItems[index];

                          if (item is String) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: item == 'INGRESOS' ? Colors.teal : Colors.deepOrange,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            );
                          }

                          return _buildTransactionTile(item as TransactionModel);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddDialog(),
        label: const Text('Extra'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(double inUYU, double outUYU, double inUSD, double outUSD) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _balanceSmallRow('Pesos (UYU)', inUYU, outUYU, _uyuFormat)),
            const VerticalDivider(width: 20),
            Expanded(child: _balanceSmallRow('Dólares (USD)', inUSD, outUSD, _usdFormat)),
          ],
        ),
      ),
    );
  }

  Widget _balanceSmallRow(String label, double income, double expense, NumberFormat format) {
    double balance = income - expense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        _miniAmount('En: ', income, Colors.green, format),
        _miniAmount('Out: ', expense, Colors.red, format),
        const Divider(height: 8),
        Text(format.format(balance), style: TextStyle(fontWeight: FontWeight.bold, color: balance >= 0 ? Colors.teal : Colors.red)),
      ],
    );
  }

  Widget _miniAmount(String prefix, double amount, Color color, NumberFormat format) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(prefix, style: const TextStyle(fontSize: 10)),
        Text(format.format(amount), style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel t) {
    final format = t.currency == 'UYU' ? _uyuFormat : _usdFormat;
    final isExpense = t.type == 'EXPENSE';

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Eliminar movimiento?'),
            content: Text('¿Estás seguro de que quieres eliminar "${t.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(context, true), 
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _service.deleteTransaction(t.id),
      child: ListTile(
        dense: true,
        leading: Icon(
          isExpense ? (t.isCompleted ? Icons.check_circle : Icons.pending_actions) : Icons.add_circle,
          color: isExpense ? (t.isCompleted ? Colors.green : Colors.orange) : Colors.teal,
        ),
        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: t.dueDate != null ? Text('Vence: ${DateFormat('dd/MM').format(t.dueDate!)}', style: const TextStyle(fontSize: 11)) : null,
        trailing: Text(format.format(t.amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isExpense ? Colors.black : Colors.green)),
        onTap: () => _showEditDialog(t),
      ),
    );
  }

  void _showEditDialog(TransactionModel t) {
    final TextEditingController amountController = TextEditingController(text: t.amount.toString());
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final String rawDesc = t.description ?? '';
        final List<String> items = rawDesc.isEmpty 
            ? [] 
            : rawDesc.split(', ').where((s) => s.trim().isNotEmpty).toList();

        return AlertDialog(
          title: Text(t.title),
          scrollable: true,
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (items.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Consumos (clic para borrar cuotas):', 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onTap: () async {
                      final bool? ok = await showDialog<bool>(
                        context: dialogContext,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Eliminar cuotas?'),
                          content: Text('Se borrará "$item" de todos los meses.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, borrar todo')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await _service.removeCreditCardExpense(
                          cardName: t.title,
                          fullItemText: item,
                          startDate: t.date,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      }
                    },
                  )),
                  const Divider(),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto Total',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Botones simples sin Spacer para evitar errores de layout en Web
            TextButton(
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: dialogContext,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Borrar ítem?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  _service.deleteTransaction(t.id);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                _service.updateTransaction(t.copyWith(isCompleted: !t.isCompleted));
                Navigator.pop(dialogContext);
              },
              child: Text(t.isCompleted ? 'Pendiente' : 'Pagado'),
            ),
            // Botón para convertir en recurrente (solo si no es tarjeta directamente)
            if (t.category != 'Tarjeta')
              IconButton(
                icon: const Icon(Icons.autorenew, color: Colors.blue),
                tooltip: 'Hacer recurrente',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: dialogContext,
                    builder: (ctx) => AlertDialog(
                      title: const Text('¿Hacer recurrente?'),
                      content: const Text('Este gasto se guardará como plantilla y aparecerá automáticamente en los próximos meses.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hacer Fijo')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _service.createTemplateFromTransaction(t);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Guardado como gasto fijo para el futuro')),
                      );
                    }
                  }
                },
              ),
            FilledButton(
              onPressed: () {
                final double? val = double.tryParse(amountController.text);
                if (val != null) {
                  _service.updateTransaction(t.copyWith(amount: val));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Qué quieres registrar?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.teal),
              title: const Text('Ingreso o Gasto Simple'),
              subtitle: const Text('Movimiento puntual en este mes'),
              onTap: () {
                Navigator.pop(context);
                _showSimpleTransactionDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Compra con Tarjeta'),
              subtitle: const Text('Suma al total de la tarjeta y permite cuotas'),
              onTap: () {
                Navigator.pop(context);
                _showCreditCardDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSimpleTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'EXPENSE';
    String currency = 'UYU';
    DateTime selectedDate = _viewingDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Nuevo Movimiento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'EXPENSE', label: Text('Gasto'), icon: Icon(Icons.remove_circle)),
                  ButtonSegment(value: 'INCOME', label: Text('Ingreso'), icon: Icon(Icons.add_circle)),
                ],
                selected: {type},
                onSelectionChanged: (val) => setS(() => type = val.first),
              ),
              const SizedBox(height: 10),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Concepto')),
              Row(
                children: [
                  Expanded(child: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto'))),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: currency,
                    onChanged: (v) => setS(() => currency = v!),
                    items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text('Mes de imputación: ${DateFormat('MMMM yyyy', 'es_ES').format(selectedDate)}'),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setS(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  _service.addTransaction(TransactionModel(
                    id: '', 
                    title: titleController.text, 
                    amount: double.parse(amountController.text),
                    date: selectedDate, 
                    category: 'Extra', 
                    currency: currency, 
                    type: type, 
                    isCompleted: true
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreditCardDialog() {
    final amountController = TextEditingController();
    final installmentsController = TextEditingController(text: '1');
    final conceptController = TextEditingController();
    String? selectedCard;
    String currency = 'UYU';
    DateTime selectedDate = _viewingDate;

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getTemplates(type: 'EXPENSE'),
        builder: (context, snapshot) {
          final cards = snapshot.data?.where((t) => t['isCreditCard'] == true).toList() ?? [];

          return StatefulBuilder(
            builder: (context, setS) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Compra con Tarjeta'),
                ],
              ),
              content: cards.isEmpty 
                ? const Text('Primero debes marcar alguna de tus plantillas de gastos como "Tarjeta de Crédito" en Configuración.')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedCard,
                          hint: const Text('Seleccionar Tarjeta'),
                          items: cards.map((c) => DropdownMenuItem<String>(
                            value: c['title'],
                            child: Text(c['title']),
                          )).toList(),
                          onChanged: (v) => setS(() => selectedCard = v),
                          decoration: const InputDecoration(labelText: 'Tarjeta'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: conceptController,
                          decoration: const InputDecoration(
                            labelText: 'Concepto',
                            hintText: 'Ej: Televisor, Supermercado',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: amountController, 
                                keyboardType: TextInputType.number, 
                                decoration: const InputDecoration(labelText: 'Monto Total'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: currency,
                              onChanged: (v) => setS(() => currency = v!),
                              items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: installmentsController, 
                          keyboardType: TextInputType.number, 
                          decoration: const InputDecoration(labelText: 'Cantidad de Cuotas'),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today),
                          title: Text('Mes de inicio: ${DateFormat('MMMM yyyy', 'es_ES').format(selectedDate)}'),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setS(() => selectedDate = picked);
                          },
                        ),
                      ],
                    ),
                  ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                if (cards.isNotEmpty)
                  FilledButton(
                    onPressed: () {
                      if (selectedCard != null && amountController.text.isNotEmpty) {
                        _service.addCreditCardExpense(
                          cardName: selectedCard!,
                          totalAmount: double.parse(amountController.text),
                          installments: int.parse(installmentsController.text),
                          currency: currency,
                          startDate: selectedDate,
                          concept: conceptController.text.isNotEmpty ? conceptController.text : null,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Procesando gasto de tarjeta...')),
                        );
                      }
                    },
                    child: const Text('Registrar Compra'),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
}
