import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/icon_utils.dart';
import '../../utils/currency_formatter.dart';

class GoalDialog extends StatefulWidget {
  final FirebaseService service;
  final Map<String, dynamic>? goal;

  const GoalDialog({
    super.key,
    required this.service,
    this.goal,
  });

  @override
  State<GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<GoalDialog> {
  late TextEditingController titleCtrl;
  late TextEditingController targetCtrl;
  late TextEditingController currentCtrl;
  late String currency;
  late String selectedIcon;
  String? linkedAccountId;
  bool shareWithFamily = false;
  String? familyId;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    isEdit = widget.goal != null;
    titleCtrl = TextEditingController(text: widget.goal?['title'] ?? '');
    
    final double target = (widget.goal?['targetAmount'] ?? 0.0).toDouble();
    targetCtrl = TextEditingController(
        text: target > 0 ? CurrencyUtils.formatForInput(target) : '');
        
    final double current = (widget.goal?['currentAmount'] ?? 0.0).toDouble();
    currentCtrl = TextEditingController(
        text: current > 0 ? CurrencyUtils.formatForInput(current) : '');
        
    currency = widget.goal?['currency'] ?? 'UYU';
    selectedIcon = widget.goal?['icon'] ?? 'savings';
    linkedAccountId = widget.goal?['linkedAccountId'];
    shareWithFamily = widget.goal?['familyId'] != null;

    _loadFamilyInfo();
  }

  Future<void> _loadFamilyInfo() async {
    final fid = await widget.service.getMyFamilyId();
    if (mounted) setState(() => familyId = fid);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    targetCtrl.dispose();
    currentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Editar Meta' : 'Nueva Meta'),
      content: SingleChildScrollView(
        child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.service.getBalances(),
            builder: (context, balSnapshot) {
              final accounts = balSnapshot.data ?? [];

              return Column(
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
                    controller: titleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nombre de la meta (ej: Viaje)', border: OutlineInputBorder()),
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
                            linkedAccountId = null;
                          }),
                          decoration: const InputDecoration(labelText: 'Moneda'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: targetCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: const InputDecoration(labelText: 'Monto Objetivo', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: currentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Monto ya ahorrado', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: linkedAccountId,
                    hint: const Text('¿Dónde guardas este ahorro?'),
                    decoration: const InputDecoration(labelText: 'Cuenta vinculada', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Efectivo / Manual'),
                      ),
                      ...accounts.where((a) => a['currency'] == currency).map((a) => DropdownMenuItem(
                            value: a['id'] as String,
                            child: Text(a['accountName']),
                          )),
                    ],
                    onChanged: (v) => setState(() => linkedAccountId = v),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Icono representativo:', style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.primary),
                      ),
                      child: selectedIcon.endsWith('.png')
                          ? Image.asset('assets/logos/$selectedIcon', width: 24, height: 24, fit: BoxFit.contain)
                          : Icon(IconUtils.getIconData(selectedIcon), color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(selectedIcon.endsWith('.png') ? 'Logo: $selectedIcon' : 'Icono: $selectedIcon',
                        style: const TextStyle(fontSize: 14)),
                    trailing: TextButton.icon(
                      onPressed: () => IconUtils.showUnifiedIconPicker(
                        context: context,
                        selectedValue: selectedIcon,
                        isSelectedValueAsset: selectedIcon.endsWith('.png'),
                        onSelected: (newVal, isAsset) => setState(() => selectedIcon = newVal ?? 'savings'),
                      ),
                      icon: const Icon(Icons.grid_view, size: 16),
                      label: const Text('Cambiar'),
                    ),
                  ),
                ],
              );
            }),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (titleCtrl.text.isNotEmpty && targetCtrl.text.isNotEmpty) {
              final data = {
                'title': titleCtrl.text,
                'targetAmount': widget.service.parseAmount(targetCtrl.text),
                'currentAmount': widget.service.parseAmount(currentCtrl.text),
                'currency': currency,
                'icon': selectedIcon,
                'linkedAccountId': linkedAccountId,
                'familyId': shareWithFamily ? familyId : null, // NUEVO
              };
              if (isEdit) {
                widget.service.updateGoal(widget.goal!['id'].toString(), data);
              } else {
                widget.service.addGoal(data);
              }
              Navigator.pop(context);
            }
          },
          child: Text(isEdit ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}
