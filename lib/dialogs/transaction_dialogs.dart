import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/firebase_service.dart';
import '../utils/icon_utils.dart';
import '../utils/currency_formatter.dart';
import '../utils/dialog_utils.dart';
import '../utils/color_utils.dart';

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
  bool shareWithFamily = false;
  String? familyId;
  
  String? selectedCategoryId;
  String? selectedAccountId;
  
  late DateTime selectedDate;

  String accTruncate(String name) {
    return name.length > 18 ? '${name.substring(0, 15)}...' : name;
  }

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    _loadFamilyInfo();
  }

  Future<void> _loadFamilyInfo() async {
    final fid = await widget.service.getMyFamilyId();
    if (mounted) setState(() => familyId = fid);
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

        return AlertDialog(
          title: const Text('Nuevo Movimiento'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: type == 'EXPENSE' ? Colors.deepOrange.shade800 : Colors.green,
                      selectedForegroundColor: Colors.white,
                    ),
                    segments: const [
                      ButtonSegment(value: 'EXPENSE', label: Text('Gasto'), icon: Icon(Icons.remove_circle)),
                      ButtonSegment(value: 'INCOME', label: Text('Ingreso'), icon: Icon(Icons.add_circle))
                    ],
                    selected: {type},
                    onSelectionChanged: (val) => setState(() {
                      type = val.first;
                      selectedCategoryId = null;
                      selectedAccountId = null;
                    }),
                  ),
                  const SizedBox(height: 20),

                  if (familyId != null)
                    SwitchListTile(
                      title: const Text('Compartir con Familia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Visible para todos los miembros', style: TextStyle(fontSize: 11)),
                      value: shareWithFamily,
                      secondary: const Icon(Icons.family_restroom, size: 20, color: Colors.teal),
                      onChanged: (v) => setState(() => shareWithFamily = v),
                      contentPadding: EdgeInsets.zero,
                    ),

                  if (type == 'EXPENSE')
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      hint: const Text('Seleccionar Categoría'),
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Sin categoría (Otros)', style: TextStyle(color: Colors.grey)),
                        ),
                        ...allCategories.where((c) => c['type'] == 'EXPENSE').map((c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Row(
                            children: [
                              Icon(IconUtils.getIconData(c['icon'] ?? 'category'), color: ColorUtils.parse(c['color']), size: 20),
                              const SizedBox(width: 10),
                              Text(c['name']),
                            ],
                          ),
                        )),
                      ],
                      onChanged: (v) => setState(() => selectedCategoryId = v),
                    )
                  else
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: widget.service.getBalances(),
                      builder: (context, snapshot) {
                        final allAccounts = snapshot.data ?? [];
                        final accounts = allAccounts.where((a) => a['currency'] == currency).toList();

                        return DropdownButtonFormField<String>(
                          initialValue: selectedAccountId,
                          hint: Text(accounts.isEmpty ? 'No hay cuentas en $currency' : '¿A dónde va el dinero?'),
                          decoration: InputDecoration(
                            labelText: 'Cuenta Destino ($currency)', 
                            border: const OutlineInputBorder(),
                            helperText: accounts.isEmpty ? 'Crea una cuenta en $currency en Configuración' : null,
                            helperStyle: const TextStyle(color: Colors.orange),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'CASH_PAYMENT',
                              child: Row(
                                children: [
                                  Icon(Icons.money_off_csred_outlined, color: Colors.blueGrey, size: 20),
                                  SizedBox(width: 10),
                                  Text('Solo registro / Efectivo', style: TextStyle(color: Colors.blueGrey)),
                                ],
                              ),
                            ),
                            ...accounts.map((a) => DropdownMenuItem(
                              value: a['id'] as String,
                              child: Row(
                                children: [
                                  if (a['brandLogo'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Image.asset('assets/logos/${a['brandLogo']}', width: 18),
                                    ),
                                  Text(a['accountName']),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (v) => setState(() => selectedAccountId = v),
                        );
                      }
                    ),

                  const SizedBox(height: 10),
                  if (type == 'EXPENSE') ...[
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: widget.service.getBalances(),
                      builder: (context, snapshot) {
                        final allAccounts = snapshot.data ?? [];
                        final accounts = allAccounts.where((a) => a['currency'] == currency).toList();

                        return DropdownButtonFormField<String>(
                          initialValue: selectedAccountId,
                          hint: Text(accounts.isEmpty ? '¿Pagado ahora?' : '¿Con qué pagaste? (Opcional)'),
                          decoration: InputDecoration(
                            labelText: 'Cuenta de Pago ($currency)',
                            border: const OutlineInputBorder(),
                            helperText: 'Si seleccionas una, se marcará como pagado.',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                                  SizedBox(width: 10),
                                  Text('Dejar como Pendiente', style: TextStyle(color: Colors.orange)),
                                ],
                              ),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'CASH_PAYMENT',
                              child: Row(
                                children: [
                                  Icon(Icons.money_off_csred_outlined, color: Colors.blueGrey, size: 20),
                                  SizedBox(width: 10),
                                  Text('Pago en Efectivo (Sin cuenta)', style: TextStyle(color: Colors.blueGrey)),
                                ],
                              ),
                            ),
                            ...accounts.map((a) => DropdownMenuItem(
                              value: a['id'] as String,
                              child: Row(
                                children: [
                                  if (a['brandLogo'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Image.asset('assets/logos/${a['brandLogo']}', width: 18),
                                    ),
                                  Text(accTruncate(a['accountName'])),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (v) => setState(() => selectedAccountId = v),
                        );
                      }
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Concepto (Ej: Alquiler, Sueldo)', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingresa un concepto' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Monto', 
                            border: OutlineInputBorder(),
                            helperText: 'Usa punto (.) para decimales.',
                          ),
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
                            onChanged: (v) => setState(() {
                              currency = v!;
                              selectedAccountId = null;
                            }),
                            items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (type == 'EXPENSE')
                    SwitchListTile(
                      title: const Text('¿Incluido en tarjeta?', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Evita duplicar deuda.', style: TextStyle(fontSize: 11)),
                      value: includedInCard,
                      onChanged: (v) => setState(() => includedInCard = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  const SizedBox(height: 10),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text('Mes: ${DateFormat('MMMM yyyy', 'es_ES').format(selectedDate)}'),
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
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final double amount = widget.service.parseAmount(amountController.text);
                  final String concept = titleController.text;

                  final confirm = await DialogUtils.confirmAction(
                    context,
                    title: 'Confirmar Registro',
                    message: '¿Deseas registrar "$concept" por un monto de $currency $amount?',
                    confirmText: 'Registrar',
                  );

                  if (confirm != true) return;

                  String categoryName = 'Otros';
                  String? categoryLogo;
                  int? categoryColor;
                  if (type == 'INCOME') {
                    categoryName = 'Ingreso';
                  } else if (selectedCategoryId != null) {
                    final catData = allCategories.firstWhere((c) => c['id'] == selectedCategoryId);
                    final cat = CategoryModel.fromMap(catData, catData['id']);
                    categoryName = cat.name;
                    categoryLogo = cat.icon;
                    categoryColor = cat.color;
                  }

                  final transaction = TransactionModel(
                    id: '',
                    title: titleController.text,
                    amount: amount,
                    date: selectedDate,
                    category: categoryName,
                    currency: currency,
                    type: type,
                    isCompleted: selectedAccountId != null,
                    isPaid: selectedAccountId != null,
                    includedInCard: includedInCard,
                    brandLogo: categoryLogo, 
                    categoryColor: categoryColor,
                    familyId: shareWithFamily ? familyId : null, // NUEVO
                  );

                  if (selectedAccountId != null && selectedAccountId != 'CASH_PAYMENT') {
                    await widget.service.addTransactionWithBalanceUpdate(
                      transaction: transaction,
                      accountId: selectedAccountId,
                    );
                  } else {
                    await widget.service.addTransaction(transaction);
                  }
                  
                  if (mounted) Navigator.pop(context, true);
                }
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      }
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
  final initialInstallmentController = TextEditingController(text: '1');
  final conceptController = TextEditingController();
  String? selectedCard;
  String? selectedCategoryId;
  String currency = 'UYU';
  late DateTime selectedDate;
  bool shareWithFamily = false;
  String? familyId;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    _loadFamilyInfo();
  }

  Future<void> _loadFamilyInfo() async {
    final fid = await widget.service.getMyFamilyId();
    if (mounted) setState(() => familyId = fid);
  }

  @override
  void dispose() {
    amountController.dispose();
    installmentsController.dispose();
    initialInstallmentController.dispose();
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              );
            }

            final cards = snapshot.data?.where((t) => t['isCreditCard'] == true || t['isCreditCard'] == 1).where((t) => t['currency'] == currency).toList() ?? [];

            return AlertDialog(
              title: Row(children: [
                Icon(Icons.credit_card, color: Colors.deepOrange.shade800),
                const SizedBox(width: 10),
                const Text('Compra con Tarjeta')
              ]),
              scrollable: true,
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (familyId != null)
                      SwitchListTile(
                        title: const Text('Compartir con Familia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Visible para todos los miembros', style: TextStyle(fontSize: 11)),
                        value: shareWithFamily,
                        secondary: const Icon(Icons.family_restroom, size: 20, color: Colors.teal),
                        onChanged: (v) => setState(() => shareWithFamily = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    Row(
                      children: [
                        const Text("Moneda:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'UYU', label: Text('UYU', style: TextStyle(fontSize: 12))),
                              ButtonSegment(value: 'USD', label: Text('USD', style: TextStyle(fontSize: 12))),
                            ],
                            selected: {currency},
                            onSelectionChanged: (val) => setState(() {
                              currency = val.first;
                              selectedCard = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (cards.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('No tienes tarjetas de crédito en $currency.', 
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Configúralas en Menú > Configuración > Gastos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      )
                    else
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: selectedCard,
                              hint: const Text('Seleccionar Tarjeta'),
                              isExpanded: true,
                              items: cards.map((c) => DropdownMenuItem<String>(
                                value: c['title'],
                                child: Text(c['title'], overflow: TextOverflow.ellipsis)
                              )).toList(),
                              onChanged: (v) => setState(() => selectedCard = v),
                              decoration: const InputDecoration(
                                labelText: 'Tarjeta', 
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              validator: (v) => v == null ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: selectedCategoryId,
                              hint: const Text('Categoría (Opcional)'),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Categoría', 
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Sin categoría', style: TextStyle(color: Colors.grey)),
                                ),
                                ...allCategories.map((c) => DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Row(
                                    children: [
                                      Icon(IconUtils.getIconData(c['icon'] ?? 'category'), color: ColorUtils.parse(c['color']), size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(c['name'], overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                )),
                              ],
                              onChanged: (v) => setState(() => selectedCategoryId = v),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: conceptController,
                              decoration: const InputDecoration(
                                labelText: 'Concepto', 
                                hintText: 'Ej: Televisor, Super...', 
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                                    decoration: const InputDecoration(
                                      labelText: 'Monto Total de Compra', 
                                      border: OutlineInputBorder(),
                                      helperText: 'Decimales con punto (.).',
                                      helperStyle: TextStyle(fontSize: 10),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  height: 48,
                                  width: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                                  ),
                                  child: Text(currency, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: installmentsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Cuotas Totales', 
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Error';
                                      final n = int.tryParse(v);
                                      if (n == null || n < 1) return 'Min 1';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: initialInstallmentController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Cuota Próxima', 
                                      border: OutlineInputBorder(),
                                      helperText: 'Inicio de carga',
                                      helperStyle: TextStyle(fontSize: 10),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Error';
                                      final n = int.tryParse(v);
                                      final total = int.tryParse(installmentsController.text) ?? 1;
                                      if (n == null || n < 1) return 'Min 1';
                                      if (n > total) return 'Max $total';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              leading: const Icon(Icons.calendar_month, size: 20),
                              title: Text('Mes de inicio: ${DateFormat('MMM yyyy', 'es_ES').format(selectedDate)}', style: const TextStyle(fontSize: 13)),
                              trailing: const Icon(Icons.edit, size: 16),
                              onTap: () async {
                                final DateTime? picked = await DialogUtils.showMonthYearPicker(context, selectedDate);
                                if (picked != null) setState(() => selectedDate = picked);
                              }
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                if (cards.isNotEmpty)
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange.shade800),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final double totalAmount = widget.service.parseAmount(amountController.text);
                        final int installments = int.parse(installmentsController.text);
                        
                        final confirm = await DialogUtils.confirmAction(
                          context,
                          title: 'Confirmar Compra',
                          message: '¿Registrar compra de $currency $totalAmount en $installments cuotas con la tarjeta $selectedCard?',
                          confirmText: 'Registrar Compra',
                          confirmColor: Colors.deepOrange.shade800,
                        );

                        if (confirm != true) return;

                        final catData = allCategories.where((c) => c['id'] == selectedCategoryId).firstOrNull;
                        String categoryName = 'Tarjeta';
                        String? categoryLogo;
                        int? categoryColor;
                        
                        if (catData != null) {
                          final cat = CategoryModel.fromMap(catData, catData['id']);
                          categoryName = cat.name;
                          categoryLogo = cat.icon;
                          categoryColor = cat.color;
                        }

                        widget.service.addCreditCardExpense(
                          cardName: selectedCard!,
                          totalAmount: totalAmount,
                          installments: installments,
                          initialInstallment: int.parse(initialInstallmentController.text),
                          currency: currency,
                          startDate: selectedDate,
                          concept: conceptController.text.isNotEmpty ? conceptController.text : null,
                          category: categoryName,
                          categoryLogo: categoryLogo,
                          categoryColor: categoryColor,
                          familyId: shareWithFamily ? familyId : null, // NUEVO
                        );
                        if (context.mounted) Navigator.pop(context, true);
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
  late TextEditingController titleController;
  String? selectedCategoryId;
  bool shareWithFamily = false;
  String? familyId;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: CurrencyUtils.formatForInput(widget.transaction.amount),
    );
    titleController = TextEditingController(text: widget.transaction.title);
    shareWithFamily = widget.transaction.familyId != null;
    _loadFamilyInfo();
  }

  Future<void> _loadFamilyInfo() async {
    final fid = await widget.service.getMyFamilyId();
    if (mounted) setState(() => familyId = fid);
  }

  @override
  void dispose() {
    amountController.dispose();
    titleController.dispose();
    super.dispose();
  }

  Future<void> _togglePaidStatus(BuildContext context, TransactionModel t) async {
    final double currentAmount = widget.service.parseAmount(amountController.text);
    final transactionToUse = t.copyWith(amount: currentAmount);

    if (t.isCompleted) {
      if (t.paidFromAccountId == null) {
        await widget.service.updateTransaction(transactionToUse.copyWith(isCompleted: false, isPaid: false));
        if (mounted) Navigator.pop(context);
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deshacer Pago'),
          content: const Text('¿Deseas marcar este movimiento como pendiente y devolver el dinero a la cuenta original?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Solo Pendiente')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revertir Saldo')),
          ],
        ),
      );

      if (confirm == null) return;

      if (confirm) {
        await widget.service.completeTransactionWithBalanceUpdate(
          transaction: transactionToUse,
          accountId: t.paidFromAccountId!,
          isUndoing: true,
        );
      } else {
        await widget.service.updateTransaction(transactionToUse.copyWith(isCompleted: false, isPaid: false, paidFromAccountId: null));
      }
      if (mounted) Navigator.pop(context);
    } else {
      _showAccountSelector(context, transactionToUse);
    }
  }

  void _showAccountSelector(BuildContext context, TransactionModel t) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.service.getBalances(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final allAccounts = snapshot.data!;
            final accounts = allAccounts; 

            return AlertDialog(
              title: Text('Pagar con ${t.currency}'),
              content: isProcessing 
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: accounts.isEmpty
                        ? const Text('No tienes cuentas configuradas. Ve al Panel de Control.')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: accounts.length + 1,
                            itemBuilder: (context, index) {
                              if (index == accounts.length) {
                                return ListTile(
                                  leading: const Icon(Icons.money_off_csred_outlined),
                                  title: const Text('Pago en efectivo'),
                                  subtitle: const Text('Sin descontar de ninguna cuenta'),
                                  onTap: isProcessing ? null : () async {
                                    setS(() => isProcessing = true);
                                    try {
                                      await widget.service.updateTransaction(t.copyWith(isCompleted: true, isPaid: true));
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) Navigator.pop(this.context);
                                    } catch (e) {
                                      setS(() => isProcessing = false);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  },
                                );
                              }
                              
                              final acc = accounts[index];
                              final bool sameCurrency = acc['currency'] == t.currency;

                              return ListTile(
                                enabled: !isProcessing,
                                leading: acc['brandLogo'] != null 
                                  ? Image.asset('assets/logos/${acc['brandLogo']}', width: 24, errorBuilder: (_, _, _) => const Icon(Icons.account_balance_wallet))
                                  : Icon(Icons.account_balance_wallet, color: sameCurrency ? null : Colors.grey),
                                title: Text(acc['accountName'], style: TextStyle(color: sameCurrency ? null : Colors.grey)),
                                subtitle: Text('${acc['currency']} ${acc['amount']}', style: TextStyle(color: sameCurrency ? null : Colors.grey)),
                                trailing: sameCurrency ? null : const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Confirmar Pago'),
                                      content: Text('¿Confirmas descontar ${t.currency} ${t.amount} de la cuenta ${acc['accountName']}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                                        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmar Pago')),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    setS(() => isProcessing = true);
                                    try {
                                      await widget.service.completeTransactionWithBalanceUpdate(
                                        transaction: t,
                                        accountId: acc['id'],
                                        isUndoing: false,
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) Navigator.pop(this.context);
                                    } catch (e) {
                                      setS(() => isProcessing = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al procesar pago: $e')));
                                      }
                                    }
                                  }
                                },
                              );
                            },
                          ),
                  ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(ctx), 
                  child: const Text('Cancelar')
                ),
              ],
            );
          },
        ),
      ),
    );
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
              if (familyId != null)
                SwitchListTile(
                  title: const Text('Compartir con Familia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Visible para todos los miembros', style: TextStyle(fontSize: 11)),
                  value: shareWithFamily,
                  secondary: const Icon(Icons.family_restroom, size: 20, color: Colors.teal),
                  onChanged: (v) => setState(() => shareWithFamily = v),
                  contentPadding: EdgeInsets.zero,
                ),
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () async {
                      if (await DialogUtils.confirmDeletion(context, item)) {
                        await widget.service.removeCreditCardExpense(
                          cardName: t.title,
                          fullItemText: item,
                          startDate: t.date,
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                )),
                const Divider(),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa un concepto' : null,
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.service.getCategories(type: widget.transaction.type),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  if (selectedCategoryId == null && categories.isNotEmpty) {
                    final match = categories.where((c) => c['name'] == widget.transaction.category).firstOrNull;
                    if (match != null) selectedCategoryId = match['id'];
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    hint: const Text('Categoría'),
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                    items: [
                      if (widget.transaction.type == 'INCOME')
                        const DropdownMenuItem(value: 'income_cat', child: Text('Ingreso')),
                      ...categories.map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['name']),
                      )),
                    ],
                    onChanged: (v) => setState(() => selectedCategoryId = v),
                  );
                }
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Monto Total',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Usa punto (.) para decimales.',
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
            if (await DialogUtils.confirmDeletion(context, t.title)) {
              widget.service.deleteTransaction(t.id);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => _togglePaidStatus(context, t),
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final double val = widget.service.parseAmount(amountController.text);
              
              String newCategory = t.category;
              if (selectedCategoryId != null) {
                if (selectedCategoryId == 'income_cat') {
                  newCategory = 'Ingreso';
                } else {
                  final categories = await widget.service.getCategories(type: t.type).first;
                  final catData = categories.where((c) => c['id'] == selectedCategoryId).firstOrNull;
                  if (catData != null) {
                    final cat = CategoryModel.fromMap(catData, catData['id']);
                    newCategory = cat.name;
                  }
                }
              }

              widget.service.updateTransaction(t.copyWith(
                title: titleController.text,
                amount: val,
                category: newCategory,
                familyId: shareWithFamily ? familyId : null, // NUEVO
              ));
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
