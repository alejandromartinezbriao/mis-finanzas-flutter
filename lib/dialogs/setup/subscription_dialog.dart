import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/currency_formatter.dart';

class SubscriptionDialog extends StatefulWidget {
  final FirebaseService service;
  final Map<String, dynamic>? sub;

  const SubscriptionDialog({
    super.key,
    required this.service,
    this.sub,
  });

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController amountCtrl;
  late TextEditingController dayCtrl;
  late String currency;
  late String linkType;
  String? linkId;
  String? initialCategoryName;
  String? selectedCategoryId;
  bool shareWithFamily = false;
  String? familyId;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    isEdit = widget.sub != null;
    nameCtrl = TextEditingController(text: widget.sub?['name']?.toString() ?? '');
    
    final double amount = (widget.sub?['amount'] ?? 0.0).toDouble();
    amountCtrl = TextEditingController(
        text: amount > 0 ? CurrencyUtils.formatForInput(amount) : '');
        
    dayCtrl = TextEditingController(text: widget.sub?['dueDay']?.toString() ?? '');
    currency = widget.sub?['currency']?.toString() ?? 'UYU';
    linkType = widget.sub?['linkType']?.toString() ?? 'CARD';
    linkId = widget.sub?['linkId']?.toString();
    initialCategoryName = widget.sub?['category']?.toString(); 
    shareWithFamily = widget.sub?['familyId'] != null;

    _loadFamilyInfo();
  }

  Future<void> _loadFamilyInfo() async {
    final fid = await widget.service.getMyFamilyId();
    if (mounted) setState(() => familyId = fid);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
    dayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.service.getCategories(type: 'EXPENSE'),
      builder: (context, catSnapshot) {
        final categories = catSnapshot.data ?? [];
        
        if (selectedCategoryId == null && initialCategoryName != null && categories.isNotEmpty) {
          final match = categories.where((c) => c['name'] == initialCategoryName).firstOrNull;
          if (match != null) selectedCategoryId = match['id'];
        }

        return AlertDialog(
          title: Text(isEdit ? 'Editar Suscripción' : 'Nueva Suscripción'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (familyId != null)
                  SwitchListTile(
                    title: const Text('Compartir con Familia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Visible para todos los miembros', style: TextStyle(fontSize: 11)),
                    value: shareWithFamily,
                    secondary: const Icon(Icons.family_restroom, color: Colors.teal),
                    onChanged: (v) => setState(() => shareWithFamily = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre (ej: Netflix, Gym)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                        child: DropdownButtonFormField<String>(
                            value: currency,
                            items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() {
                                  currency = v!;
                                  linkId = null;
                                }),
                            decoration: const InputDecoration(labelText: 'Moneda'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [ThousandsSeparatorInputFormatter()],
                            decoration: const InputDecoration(labelText: 'Costo Mensual'))),
                  ],
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  hint: const Text('Categoría'),
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']?.toString() ?? ''))).toList(),
                  onChanged: (v) => setState(() => selectedCategoryId = v),
                ),
                const SizedBox(height: 15),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CARD', label: Text('A Tarjeta'), icon: Icon(Icons.credit_card)),
                    ButtonSegment(value: 'ACCOUNT', label: Text('A Cuenta'), icon: Icon(Icons.account_balance_wallet)),
                  ],
                  selected: {linkType},
                  onSelectionChanged: (val) => setState(() {
                    linkType = val.first;
                    linkId = null;
                  }),
                ),
                const SizedBox(height: 15),
                if (linkType == 'CARD')
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.service.getTemplates(type: 'EXPENSE'),
                    builder: (context, snapshot) {
                      final cards = snapshot.data?.where((t) => t['isCreditCard'] == true || t['isCreditCard'] == 1).toList() ?? [];
                      return DropdownButtonFormField<String>(
                        value: linkId,
                        hint: const Text('Seleccionar Tarjeta de Crédito'),
                        decoration: const InputDecoration(labelText: 'Vincular a Crédito:', border: OutlineInputBorder()),
                        items: cards.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['title']?.toString() ?? ''))).toList(),
                        onChanged: (v) => setState(() => linkId = v),
                      );
                    },
                  )
                else
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.service.getBalances(),
                    builder: (context, snapshot) {
                      final accounts = snapshot.data?.where((a) => a['currency'] == currency).toList() ?? [];
                      return DropdownButtonFormField<String>(
                        value: linkId,
                        hint: const Text('¿Desde qué cuenta se debita? (Opcional)'),
                        decoration: const InputDecoration(labelText: 'Vincular a Débito:', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Manual / Efectivo (Sin vínculo)')),
                          ...accounts.map((a) => DropdownMenuItem(value: a['id'] as String, child: Text(a['accountName']?.toString() ?? ''))),
                        ],
                        onChanged: (v) => setState(() => linkId = v),
                      );
                    },
                  ),
                const SizedBox(height: 15),
                TextField(
                  controller: dayCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Día de vencimiento (aprox)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  final categoryName = categories.where((c) => c['id'] == selectedCategoryId).firstOrNull?['name'] ?? 'Suscripción';
                  final Map<String, dynamic> data = {
                    'name': nameCtrl.text,
                    'amount': widget.service.parseAmount(amountCtrl.text),
                    'currency': currency,
                    'linkType': linkType,
                    'linkId': linkId,
                    'dueDay': int.tryParse(dayCtrl.text),
                    'category': categoryName,
                    'familyId': shareWithFamily ? familyId : null,
                  };
                  if (isEdit) {
                    widget.service.updateSubscription(widget.sub!['id'].toString(), data);
                  } else {
                    widget.service.addSubscription(data);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEdit ? 'Actualizar' : 'Crear'),
            ),
          ],
        );
      },
    );
  }
}
