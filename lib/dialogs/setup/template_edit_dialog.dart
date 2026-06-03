import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/icon_utils.dart';
import '../../utils/color_utils.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/forms/logo_selector_field.dart';
import '../../widgets/brand_icon.dart';

class TemplateEditDialog extends StatefulWidget {
  final FirebaseService service;
  final Map<String, dynamic>? template;
  final String type;

  const TemplateEditDialog({
    super.key,
    required this.service,
    this.template,
    required this.type,
  });

  @override
  State<TemplateEditDialog> createState() => _TemplateEditDialogState();
}

class _TemplateEditDialogState extends State<TemplateEditDialog> {
  late TextEditingController titleController;
  late TextEditingController dayController;
  late TextEditingController defaultAmountController;
  late String selectedCurrency;
  String? selectedCategoryId;
  late bool isCreditCard;
  late bool includedInCard;
  late String? selectedLogo;
  late List<Map<String, dynamic>> subscriptions;
  late bool isBimonetary;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    isEdit = widget.template != null;
    titleController = TextEditingController(
        text: widget.template?['title']?.toString().replaceAll(RegExp(r' \((UYU|USD)\)$'), '') ?? '');
    dayController = TextEditingController(text: widget.template?['dueDay']?.toString() ?? '');
    defaultAmountController = TextEditingController(
        text: widget.template != null ? CurrencyUtils.formatForInput((widget.template!['defaultAmount'] ?? 0.0).toDouble()) : '');
    selectedCurrency = widget.template?['currency'] ?? 'UYU';
    
    // Parseo seguro de booleanos (SQLite int 0/1 vs Firebase bool)
    isCreditCard = widget.template?['isCreditCard'] == true || widget.template?['isCreditCard'] == 1;
    includedInCard = widget.template?['includedInCard'] == true || widget.template?['includedInCard'] == 1;
    isBimonetary = widget.template?['isBimonetaryPart'] == true || widget.template?['isBimonetaryPart'] == 1;

    selectedLogo = widget.template?['brandLogo'];
    
    final rawSubs = widget.template?['subscriptions'];
    if (rawSubs is List) {
      subscriptions = List<Map<String, dynamic>>.from(rawSubs);
    } else {
      subscriptions = [];
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    dayController.dispose();
    defaultAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.service.getCategories(type: widget.type),
      builder: (context, catSnapshot) {
        final categories = catSnapshot.data ?? [];
        if (isEdit && selectedCategoryId == null && widget.template!['category'] != null) {
          final match = categories.where((c) => c['name'] == widget.template!['category']).firstOrNull;
          if (match != null) selectedCategoryId = match['id'];
        }

        return AlertDialog(
          title: Text(isEdit ? 'Editar Plantilla' : 'Nueva Plantilla'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Concepto', border: OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 15),
              LogoSelectorField(
                selectedLogo: selectedLogo,
                onSelect: (logo) => setState(() => selectedLogo = logo),
                currentName: titleController.text,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: selectedCategoryId,
                hint: const Text('Seleccionar Categoría'),
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(
                  value: c['id'] as String,
                  child: Row(
                    children: [
                      Icon(IconUtils.getIconData(c['icon'] ?? 'category'), color: ColorUtils.parse(c['color']), size: 20),
                      const SizedBox(width: 10),
                      Text(c['name']),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setState(() => selectedCategoryId = v),
              ),
              const SizedBox(height: 15),
              if (!isBimonetary)
                Row(
                  children: [
                    Expanded(
                        child: DropdownButtonFormField<String>(
                            initialValue: selectedCurrency,
                            items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => selectedCurrency = v!),
                            decoration: const InputDecoration(labelText: 'Moneda'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: defaultAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        decoration: const InputDecoration(labelText: 'Monto Fijo'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              TextField(
                  controller: dayController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: widget.type == 'EXPENSE' ? 'Día de vencimiento' : 'Día de cobro')),
              if (widget.type == 'EXPENSE') ...[
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('¿Es Tarjeta de Crédito?'),
                    value: isCreditCard,
                    onChanged: (v) => setState(() => isCreditCard = v)),
                if (isCreditCard)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('¿Es Bimonetaria?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Crea registros para Pesos y Dólares', style: TextStyle(fontSize: 11)),
                    value: isBimonetary,
                    onChanged: (widget.template?['isBimonetaryPart'] == true || widget.template?['isBimonetaryPart'] == 1)
                        ? null
                        : (v) => setState(() => isBimonetary = v),
                  )
                else
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('¿Incluido en tarjeta?'),
                      subtitle: const Text('Ej: Servicio que viene en el resumen'),
                      value: includedInCard,
                      onChanged: (v) => setState(() => includedInCard = v)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final categoryName = categories.where((c) => c['id'] == selectedCategoryId).firstOrNull?['name'] ??
                      (isCreditCard ? 'Tarjeta' : (widget.type == 'EXPENSE' ? 'Fijo' : 'Ingreso'));

                  final data = {
                    'title': titleController.text,
                    'baseName': isBimonetary ? titleController.text : null,
                    'currency': selectedCurrency,
                    'dueDay': int.tryParse(dayController.text),
                    'defaultAmount': double.tryParse(defaultAmountController.text) ?? 0.0,
                    'type': widget.type,
                    'category': categoryName,
                    'isCreditCard': isCreditCard ? 1 : 0,
                    'includedInCard': includedInCard ? 1 : 0,
                    'brandLogo': selectedLogo,
                    'subscriptions': isCreditCard ? subscriptions : [],
                    'isBimonetaryPart': isBimonetary ? 1 : 0,
                  };
                  if (isEdit) {
                    if (isBimonetary && (widget.template!['isBimonetaryPart'] != true && widget.template!['isBimonetaryPart'] != 1)) {
                      await _showTemplateBimonetaryUpgradeDialog(
                        context,
                        widget.service,
                        widget.template!,
                        data,
                        selectedLogo,
                      );
                    } else {
                      await widget.service.updateTemplate(widget.template!['id'], data);
                    }
                  } else {
                    await widget.service.addTemplate(data, isBimonetary: isBimonetary);
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showTemplateBimonetaryUpgradeDialog(BuildContext context, FirebaseService service,
      Map<String, dynamic> originalTemplate, Map<String, dynamic> data, String? currentLogo) async {
    final originalId = originalTemplate['id'];
    final oldTitle = originalTemplate['title'];
    final cleanBaseName = data['title']
        .replaceAll(RegExp(r'\s+(pesos|dólares|uyu|usd|dolares)$', caseSensitive: false), '')
        .trim();
    final otherCurrency = (data['currency'] ?? 'UYU') == 'UYU' ? 'USD' : 'UYU';

    final candidates = await service.findPotentialCardTwins(
      baseName: cleanBaseName,
      targetCurrency: otherCurrency,
      logo: currentLogo,
      excludeId: originalId,
    );

    if (!context.mounted) return;

    String? selectedGemelaId;
    String? selectedGemelaTitle;
    bool createNew = false;

    if (candidates.isEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirmar Bimonetaria'),
          content: Text('Se creará una nueva tarjeta gemela en $otherCurrency para "$cleanBaseName".'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmar')),
          ],
        ),
      );
      if (confirm == true) createNew = true;
    } else {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Vincular Tarjeta Gemela'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('He encontrado tarjetas que podrían ser la contraparte en $otherCurrency de "$cleanBaseName":',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 15),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    itemBuilder: (ctx, index) {
                      final cand = candidates[index];
                      final bool isHighMatch = (cand['matchScore'] ?? 0) >= 100;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: BrandIcon(name: cand['title'], manualLogo: cand['brandLogo'], size: 32),
                        title: Text(cand['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(isHighMatch ? 'Sugerencia recomendada (mismo banco)' : 'Posible coincidencia',
                            style: TextStyle(fontSize: 11, color: isHighMatch ? Colors.green : Colors.grey)),
                        trailing: isHighMatch
                            ? const Icon(Icons.star, color: Colors.amber, size: 16)
                            : const Icon(Icons.chevron_right, size: 16),
                        tileColor: isHighMatch ? Colors.green.withOpacity(0.05) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onTap: () => Navigator.pop(c, {'id': cand['id'], 'title': cand['title']}),
                      );
                    },
                  ),
                ),
                const Divider(height: 30),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  title: const Text('No es ninguna de estas', style: TextStyle(fontSize: 14)),
                  subtitle: Text('Crear una nueva tarjeta en $otherCurrency', style: const TextStyle(fontSize: 11)),
                  onTap: () => Navigator.pop(c, {'create': true}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          ],
        ),
      );

      if (result != null) {
        if (result['create'] == true) {
          createNew = true;
        } else {
          selectedGemelaId = result['id'];
          selectedGemelaTitle = result['title'];
        }
      }
    }

    if (createNew || selectedGemelaId != null) {
      await service.upgradeTemplateToBimonetary(
        originalId: originalId,
        oldTitle: oldTitle,
        data: {...data, 'title': cleanBaseName},
        existingGemelaId: selectedGemelaId,
        oldGemelaTitle: selectedGemelaTitle,
      );
    }
  }
}
