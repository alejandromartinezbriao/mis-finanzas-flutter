import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../utils/icon_utils.dart';
import '../utils/currency_formatter.dart';

class SetupDialogs {
  static void showCategoryDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? category) {
    final isEdit = category != null;
    final nameCtrl = TextEditingController(text: category?['name'] ?? '');
    String type = category?['type'] ?? 'EXPENSE';
    int selectedColor = category?['color'] ?? Colors.blue.value;
    String selectedIcon = category?['icon'] ?? 'category';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isEdit ? 'Editar Categoría' : 'Nueva Categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'EXPENSE', label: Text('Gasto'), icon: Icon(Icons.remove_circle_outline)),
                    ButtonSegment(value: 'INCOME', label: Text('Ingreso'), icon: Icon(Icons.add_circle_outline)),
                  ],
                  selected: {type},
                  onSelectionChanged: (val) => setS(() => type = val.first),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre de la categoría', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Align(alignment: Alignment.centerLeft, child: Text('Color identificativo:', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
                    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
                    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
                    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
                    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
                  ].map((c) => GestureDetector(
                    onTap: () => setS(() => selectedColor = c.value),
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: selectedColor == c.value ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: [if (selectedColor == c.value) const BoxShadow(blurRadius: 4, color: Colors.black26)],
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                const Align(alignment: Alignment.centerLeft, child: Text('Icono o Logo identificativo:', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(selectedColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(selectedColor)),
                    ),
                    child: selectedIcon.endsWith('.png')
                        ? Image.asset('assets/logos/$selectedIcon', width: 24, height: 24, fit: BoxFit.contain)
                        : Icon(IconUtils.getIconData(selectedIcon), color: Color(selectedColor)),
                  ),
                  title: Text(selectedIcon.endsWith('.png') ? 'Logo: $selectedIcon' : 'Icono: $selectedIcon', style: const TextStyle(fontSize: 14)),
                  trailing: TextButton.icon(
                    onPressed: () => IconUtils.showUnifiedIconPicker(
                      context: context,
                      selectedValue: selectedIcon,
                      isSelectedValueAsset: selectedIcon.endsWith('.png'),
                      onSelected: (newVal, isAsset) => setS(() => selectedIcon = newVal ?? 'category'),
                    ),
                    icon: const Icon(Icons.grid_view, size: 16),
                    label: const Text('Cambiar'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final data = {
                    'name': nameCtrl.text,
                    'type': type,
                    'color': selectedColor,
                    'icon': selectedIcon,
                  };
                  if (isEdit) {
                    service.updateCategory(category['id'], data);
                  } else {
                    service.addCategory(data);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEdit ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  static void showBalanceDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? account) {
    final isEdit = account != null;
    final nameCtrl = TextEditingController(text: account?['accountName'] ?? '');
    String currency = account?['currency'] ?? 'UYU';
    String? selectedLogo = account?['brandLogo'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isEdit ? 'Editar Cuenta' : 'Nueva Cuenta (Arqueo)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (ej: Banco Santander)'),
                onChanged: (_) => setS(() {}),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: currency,
                items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setS(() => currency = v!),
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: 15),
              _buildLogoSelector(context, selectedLogo, (logo) => setS(() => selectedLogo = logo), nameCtrl.text),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final data = {
                    'accountName': nameCtrl.text,
                    'currency': currency,
                    'brandLogo': selectedLogo,
                  };
                  if (isEdit) {
                    service.updateBalanceAccountDetails(account['id'], data);
                  } else {
                    service.addBalanceAccount(nameCtrl.text, currency, logo: selectedLogo);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEdit ? 'Actualizar' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  static void showGoalDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? goal) {
    final isEdit = goal != null;
    final titleCtrl = TextEditingController(text: goal?['title'] ?? '');
    final targetCtrl = TextEditingController(
      text: goal != null ? CurrencyUtils.formatForInput((goal['targetAmount'] ?? 0.0).toDouble()) : ''
    );
    final currentCtrl = TextEditingController(
      text: goal != null ? CurrencyUtils.formatForInput((goal['currentAmount'] ?? 0.0).toDouble()) : ''
    );
    String currency = goal?['currency'] ?? 'UYU';
    String selectedIcon = goal?['icon'] ?? 'savings';
    String? linkedAccountId = goal?['linkedAccountId'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isEdit ? 'Editar Meta' : 'Nueva Meta'),
          content: SingleChildScrollView(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.getBalances(),
              builder: (context, balSnapshot) {
                final accounts = balSnapshot.data ?? [];
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre de la meta (ej: Viaje)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: currency,
                            items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setS(() {
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
                      initialValue: linkedAccountId,
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
                      onChanged: (v) => setS(() => linkedAccountId = v),
                    ),
                    const SizedBox(height: 20),
                    const Align(alignment: Alignment.centerLeft, child: Text('Icono representativo:', style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.primary),
                        ),
                        child: selectedIcon.endsWith('.png')
                            ? Image.asset('assets/logos/$selectedIcon', width: 24, height: 24, fit: BoxFit.contain)
                            : Icon(IconUtils.getIconData(selectedIcon), color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(selectedIcon.endsWith('.png') ? 'Logo: $selectedIcon' : 'Icono: $selectedIcon', style: const TextStyle(fontSize: 14)),
                      trailing: TextButton.icon(
                        onPressed: () => IconUtils.showUnifiedIconPicker(
                          context: context,
                          selectedValue: selectedIcon,
                          isSelectedValueAsset: selectedIcon.endsWith('.png'),
                          onSelected: (newVal, isAsset) => setS(() => selectedIcon = newVal ?? 'savings'),
                        ),
                        icon: const Icon(Icons.grid_view, size: 16),
                        label: const Text('Cambiar'),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && targetCtrl.text.isNotEmpty) {
                  final data = {
                    'title': titleCtrl.text,
                    'targetAmount': double.tryParse(targetCtrl.text) ?? 0.0,
                    'currentAmount': double.tryParse(currentCtrl.text) ?? 0.0,
                    'currency': currency,
                    'icon': selectedIcon,
                    'linkedAccountId': linkedAccountId,
                  };
                  if (isEdit) {
                    service.updateGoal(goal['id'], data);
                  } else {
                    service.addGoal(data);
                  }
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEdit ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditTemplateDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? template, String type) {
    final isEdit = template != null;
    final titleController = TextEditingController(text: template?['title'] ?? '');
    final dayController = TextEditingController(text: template?['dueDay']?.toString() ?? '');
    final defaultAmountController = TextEditingController(
      text: template != null ? CurrencyUtils.formatForInput((template['defaultAmount'] ?? 0.0).toDouble()) : ''
    );
    String selectedCurrency = template?['currency'] ?? 'UYU';
    String? selectedCategoryId;
    bool isCreditCard = template?['isCreditCard'] ?? false;
    bool includedInCard = template?['includedInCard'] ?? false;
    String? selectedLogo = template?['brandLogo'];
    List<Map<String, dynamic>> subscriptions = List<Map<String, dynamic>>.from(template?['subscriptions'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.getCategories(type: type),
        builder: (context, catSnapshot) {
          final categories = catSnapshot.data ?? [];
          
          return StatefulBuilder(
            builder: (context, setS) {
              if (isEdit && selectedCategoryId == null && template['category'] != null) {
                final match = categories.where((c) => c['name'] == template['category']).firstOrNull;
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
                      decoration: const InputDecoration(labelText: 'Concepto'),
                      onChanged: (_) => setS(() {}),
                    ),
                    const SizedBox(height: 15),
                    _buildLogoSelector(context, selectedLogo, (logo) => setS(() => selectedLogo = logo), titleController.text),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      hint: const Text('Seleccionar Categoría'),
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                      items: categories.map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Row(
                          children: [
                            Icon(IconUtils.getIconData(c['icon'] ?? 'category'), color: Color(c['color'] ?? 0xFF9E9E9E), size: 20),
                            const SizedBox(width: 10),
                            Text(c['name']),
                          ],
                        ),
                      )).toList(),
                      onChanged: (v) => setS(() => selectedCategoryId = v),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: DropdownButtonFormField<String>(initialValue: selectedCurrency, items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setS(() => selectedCurrency = v!), decoration: const InputDecoration(labelText: 'Moneda'))),
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
                    TextField(controller: dayController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: type == 'EXPENSE' ? 'Día de vencimiento' : 'Día de cobro')),
                    if (type == 'EXPENSE') ...[
                      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('¿Es Tarjeta de Crédito?'), value: isCreditCard, onChanged: (v) => setS(() => isCreditCard = v)),
                      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('¿Incluido en tarjeta?'), subtitle: const Text('Ej: Servicio que viene en el resumen'), value: includedInCard, onChanged: (v) => setS(() => includedInCard = v)),
                    ],
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  FilledButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        final categoryName = categories.where((c) => c['id'] == selectedCategoryId).firstOrNull?['name'] 
                            ?? (isCreditCard ? 'Tarjeta' : (type == 'EXPENSE' ? 'Fijo' : 'Ingreso'));

                        final data = {
                          'title': titleController.text,
                          'currency': selectedCurrency,
                          'dueDay': int.tryParse(dayController.text),
                          'defaultAmount': double.tryParse(defaultAmountController.text) ?? 0.0,
                          'type': type,
                          'category': categoryName,
                          'isCreditCard': isCreditCard,
                          'includedInCard': includedInCard,
                          'brandLogo': selectedLogo,
                          'subscriptions': isCreditCard ? subscriptions : [],
                        };
                        if (isEdit) {
                          service.updateTemplate(template['id'], data);
                        } else {
                          service.addTemplate(data);
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        }
      ),
    );
  }

  static void showBudgetHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.teal),
            SizedBox(width: 10),
            Text('Sobre Presupuestos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• Define un monto máximo para cada categoría de gasto.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            const Text('• Puedes elegir si el presupuesto es en Pesos (\$) o Dólares (U\$S).', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            const Text('• Los cambios se guardan automáticamente al presionar "Enter" o cambiar la moneda.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            const Text('• En la pantalla de Análisis verás cuánto te queda disponible basado en tus gastos reales.', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  // --- UTILS PARA LOGOS ---

  static Widget _buildLogoSelector(BuildContext context, String? selectedLogo, Function(String?) onSelect, String currentName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Logo Identificatorio:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => IconUtils.showUnifiedIconPicker(
                context: context,
                selectedValue: selectedLogo,
                isSelectedValueAsset: true,
                onSelected: (val, isAsset) => onSelect(val),
              ),
              icon: const Icon(Icons.grid_view, size: 16, color: Colors.teal),
              label: const Text(
                'Galería',
                style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.teal.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (selectedLogo != null && selectedLogo.startsWith('http'))
                _logoItem(selectedLogo, true, () => onSelect(null), isUrl: true),
              _logoItem(null, selectedLogo == null, () => onSelect(null), isAuto: true),
              ...IconUtils.getAllAssetLogos().take(10).map((logoName) => _logoItem(logoName, selectedLogo == logoName, () => onSelect(logoName))),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _logoItem(String? logo, bool isSelected, VoidCallback onTap, {bool isAuto = false, bool isUrl = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300, width: 2),
        ),
        child: Center(
          child: isAuto
              ? const Icon(Icons.auto_awesome, color: Colors.grey)
              : isUrl
                  ? ClipOval(child: Image.network(logo!, width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.public, color: Colors.grey)))
                  : ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          'assets/logos/$logo', 
                          width: 40, 
                          height: 40, 
                          fit: BoxFit.contain, 
                          errorBuilder: (c, e, s) => const Icon(Icons.business, color: Colors.grey),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
