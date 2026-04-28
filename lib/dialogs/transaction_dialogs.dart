import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';
import '../utils/icon_utils.dart';
import '../utils/currency_formatter.dart';

class SimpleTransactionDialog extends StatefulWidget {
  final FirebaseService service;
  final DateTime initialDate;

  const SimpleTransactionDialog({
    super.key,
    required this.service,
    required this.initialDate,
  });

  @override
  State<SimpleTransactionDialog> createState() => _SimpleTransactionDialogState();
}

class _SimpleTransactionDialogState extends State<SimpleTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  String type = 'EXPENSE';
  String currency = 'UYU';
  bool includedInCard = false;
  String? selectedCategoryId;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.service.getCategories(),
      builder: (context, catSnapshot) {
        final allCategories = catSnapshot.data ?? [];
        final categories = allCategories.where((c) => c['type'] == type).toList();

        // Validar que la categoría seleccionada sea del tipo correcto
        if (selectedCategoryId != null && !categories.any((c) => c['id'] == selectedCategoryId)) {
          selectedCategoryId = null;
        }

        return AlertDialog(
          title: const Text('Nuevo Movimiento'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'EXPENSE', label: Text('Gasto'), icon: Icon(Icons.remove_circle)),
                      ButtonSegment(value: 'INCOME', label: Text('Ingreso'), icon: Icon(Icons.add_circle))
                    ],
                    selected: {type},
                    onSelectionChanged: (val) => setState(() => type = val.first),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    hint: const Text('Seleccionar Categoría (Opcional)'),
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.label_off_outlined, color: Colors.grey, size: 20),
                            SizedBox(width: 10),
                            Text('Sin categoría', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      ...categories.map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Row(
                          children: [
                            Icon(IconUtils.getIconData(c['icon'] ?? 'category'), color: Color(c['color'] ?? 0xFF9E9E9E), size: 20),
                            const SizedBox(width: 10),
                            Text(c['name']),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (v) => setState(() => selectedCategoryId = v),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Concepto', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingresa un concepto' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: const InputDecoration(labelText: 'Monto', border: OutlineInputBorder()),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa un monto';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 56, // Match height of TextFormField with border
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currency,
                            onChanged: (v) => setState(() => currency = v!),
                            items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (type == 'EXPENSE')
                    SwitchListTile(
                      title: const Text('¿Incluido en tarjeta?', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Evita duplicar deuda si ya lo pagaste/pagarás con tarjeta.', style: TextStyle(fontSize: 11)),
                      value: includedInCard,
                      onChanged: (v) => setState(() => includedInCard = v),
                      contentPadding: EdgeInsets.zero,
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
                        lastDate: DateTime(2100)
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final categoryName = allCategories.firstWhere(
                    (c) => c['id'] == selectedCategoryId,
                    orElse: () => {'name': type == 'EXPENSE' ? 'Otros' : 'Ingresos'}
                  )['name'];

                  widget.service.addTransaction(TransactionModel(
                    id: '',
                    title: titleController.text,
                    amount: double.parse(amountController.text.replaceAll('.', '').replaceAll(',', '.')),
                    date: selectedDate,
                    category: categoryName,
                    currency: currency,
                    type: type,
                    isCompleted: true,
                    includedInCard: includedInCard,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }
}

class CreditCardTransactionDialog extends StatefulWidget {
  final FirebaseService service;
  final DateTime initialDate;

  const CreditCardTransactionDialog({
    super.key,
    required this.service,
    required this.initialDate,
  });

  @override
  State<CreditCardTransactionDialog> createState() => _CreditCardTransactionDialogState();
}

class _CreditCardTransactionDialogState extends State<CreditCardTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final installmentsController = TextEditingController(text: '1');
  final conceptController = TextEditingController();
  String? selectedCard;
  String? selectedCategoryId;
  String currency = 'UYU';
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    amountController.dispose();
    installmentsController.dispose();
    conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.service.getCategories(type: 'EXPENSE'),
      builder: (context, catSnapshot) {
        final allCategories = catSnapshot.data ?? [];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.service.getTemplates(type: 'EXPENSE'),
          builder: (context, snapshot) {
            final cards = snapshot.data?.where((t) => t['isCreditCard'] == true).toList() ?? [];

            return AlertDialog(
              title: const Row(children: [
                Icon(Icons.credit_card, color: Colors.blue),
                SizedBox(width: 10),
                Text('Compra con Tarjeta')
              ]),
              content: cards.isEmpty
                  ? const Text('Primero debes marcar alguna de tus plantillas de gastos como "Tarjeta de Crédito" en Configuración.')
                  : SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedCard,
                              hint: const Text('Seleccionar Tarjeta'),
                              items: cards.map((c) => DropdownMenuItem<String>(
                                value: c['title'],
                                child: Text(c['title'])
                              )).toList(),
                              onChanged: (v) => setState(() => selectedCard = v),
                              decoration: const InputDecoration(labelText: 'Tarjeta', border: OutlineInputBorder()),
                              validator: (v) => v == null ? 'Selecciona una tarjeta' : null,
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: selectedCategoryId,
                              hint: const Text('Categoría (Opcional)'),
                              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      Icon(Icons.label_off_outlined, color: Colors.grey, size: 20),
                                      SizedBox(width: 10),
                                      Text('Sin categoría', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                ...allCategories.map((c) => DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Row(
                                    children: [
                                      Icon(IconUtils.getIconData(c['icon'] ?? 'category'), color: Color(c['color'] ?? 0xFF9E9E9E), size: 20),
                                      const SizedBox(width: 10),
                                      Text(c['name']),
                                    ],
                                  ),
                                )),
                              ],
                              onChanged: (v) => setState(() => selectedCategoryId = v),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: conceptController,
                              decoration: const InputDecoration(labelText: 'Concepto (Opcional)', hintText: 'Ej: Televisor, Supermercado', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: amountController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                                    decoration: const InputDecoration(labelText: 'Monto Total', border: OutlineInputBorder()),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Ingresa un monto';
                                      return null;
                                    },
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
                                      value: currency,
                                      onChanged: (v) => setState(() => currency = v!),
                                      items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList()
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: installmentsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Cantidad de Cuotas', border: OutlineInputBorder()),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Ingresa cuotas';
                                final n = int.tryParse(v);
                                if (n == null || n < 1) return 'Mínimo 1';
                                return null;
                              },
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
                                  lastDate: DateTime(2100)
                                );
                                if (picked != null) setState(() => selectedDate = picked);
                              }
                            ),
                          ],
                        ),
                      ),
                    ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                if (cards.isNotEmpty)
                  FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final categoryName = allCategories.firstWhere(
                          (c) => c['id'] == selectedCategoryId,
                          orElse: () => {'name': 'Tarjeta'}
                        )['name'];

                        widget.service.addCreditCardExpense(
                          cardName: selectedCard!,
                          totalAmount: double.parse(amountController.text.replaceAll('.', '').replaceAll(',', '.')),
                          installments: int.parse(installmentsController.text),
                          currency: currency,
                          startDate: selectedDate,
                          concept: conceptController.text.isNotEmpty ? conceptController.text : null,
                          category: categoryName,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando gasto de tarjeta...')));
                      }
                    },
                    child: const Text('Registrar Compra'),
                  ),
              ],
            );
          },
        );
      }
    );
  }
}

class EditTransactionDialog extends StatefulWidget {
  final TransactionModel transaction;
  final FirebaseService service;

  const EditTransactionDialog({
    super.key,
    required this.transaction,
    required this.service,
  });

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController amountController;

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat.decimalPattern('es_UY');
    amountController = TextEditingController(
      text: formatter.format(widget.transaction.amount),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final String rawDesc = t.description ?? '';
    final List<String> items = rawDesc.isEmpty ? [] : rawDesc.split(', ').where((s) => s.trim().isNotEmpty).toList();

    return AlertDialog(
      title: Text(t.title),
      scrollable: true,
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (items.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Consumos (clic para borrar cuotas):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onTap: () async {
                    final bool? ok = await showDialog<bool>(
                      context: context,
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
                      await widget.service.removeCreditCardExpense(
                        cardName: t.title,
                        fullItemText: item,
                        startDate: t.date,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                )),
                const Divider(),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Monto Total',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa un monto';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final bool? confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('¿Borrar ítem?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Borrar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              widget.service.deleteTransaction(t.id);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () {
            widget.service.updateTransaction(t.copyWith(isCompleted: !t.isCompleted));
            Navigator.pop(context);
          },
          child: Text(t.isCompleted ? 'Pendiente' : 'Pagado'),
        ),
        if (t.category != 'Tarjeta')
          IconButton(
            icon: const Icon(Icons.autorenew, color: Colors.blue),
            tooltip: 'Hacer recurrente',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
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
                await widget.service.createTemplateFromTransaction(t);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Guardado como gasto fijo para el futuro')),
                  );
                }
              }
            },
          ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final double? val = double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '.'));
              if (val != null) {
                widget.service.updateTransaction(t.copyWith(amount: val));
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
