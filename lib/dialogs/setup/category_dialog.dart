import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/icon_utils.dart';
import '../../widgets/forms/logo_selector_field.dart';

class CategoryDialog extends StatefulWidget {
  final FirebaseService service;
  final Map<String, dynamic>? category;

  const CategoryDialog({
    super.key,
    required this.service,
    this.category,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController budgetCtrl;
  late String type;
  late Color selectedColor;
  late String selectedIcon;
  late String budgetCurrency;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    isEdit = widget.category != null;
    nameCtrl = TextEditingController(text: widget.category?['name'] ?? '');
    
    final double budgetVal = (widget.category?['budgetAmount'] ?? 0.0).toDouble();
    budgetCtrl = TextEditingController(
      text: budgetVal > 0 ? budgetVal.toStringAsFixed(0) : ''
    );
    budgetCurrency = widget.category?['budgetCurrency'] ?? 'UYU';

    type = widget.category?['type'] ?? 'EXPENSE';
    
    // Parseo defensivo del color para evitar pantalla blanca
    final dynamic rawColor = widget.category?['color'];
    if (rawColor is num) {
      selectedColor = Color(rawColor.toInt());
    } else if (rawColor is String && rawColor.startsWith('#')) {
      selectedColor = Color(int.parse(rawColor.replaceFirst('#', '0xff'), radix: 16));
    } else {
      selectedColor = Colors.blue;
    }
    
    selectedIcon = widget.category?['icon'] ?? 'category';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Editar Categoría' : 'Nueva Categoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'EXPENSE', label: Text('Gastos'), icon: Icon(Icons.remove_circle_outline)),
                ButtonSegment(value: 'INCOME', label: Text('Ingresos'), icon: Icon(Icons.add_circle_outline)),
              ],
              selected: {type},
              onSelectionChanged: (val) => setState(() => type = val.first),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de categoría', border: OutlineInputBorder()),
            ),
            
            if (type == 'EXPENSE') ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft, 
                child: Text('Presupuesto Mensual (Opcional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: budgetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      decoration: const InputDecoration(
                        labelText: 'Monto tope',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.speed, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: budgetCurrency,
                        items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => budgetCurrency = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            const Align(
                alignment: Alignment.centerLeft, child: Text('Color:', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Colors.blue, Colors.red, Colors.green, Colors.orange,
                  Colors.purple, Colors.teal, Colors.pink, Colors.amber,
                  Colors.brown, Colors.grey, Colors.indigo, Colors.cyan
                ].map((color) => GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: selectedColor.value == color.value ? Colors.black : Colors.transparent, width: 2),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
                alignment: Alignment.centerLeft, child: Text('Icono o Logo:', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selectedIcon.endsWith('.png')
                    ? Image.asset('assets/logos/$selectedIcon', width: 24, height: 24, fit: BoxFit.contain)
                    : Icon(IconUtils.getIconData(selectedIcon), color: selectedColor),
              ),
              title: Text(selectedIcon.endsWith('.png') ? 'Logo: $selectedIcon' : 'Icono: $selectedIcon',
                  style: const TextStyle(fontSize: 14)),
              trailing: TextButton.icon(
                onPressed: () => IconUtils.showUnifiedIconPicker(
                  context: context,
                  selectedValue: selectedIcon,
                  isSelectedValueAsset: selectedIcon.endsWith('.png'),
                  onSelected: (newVal, isAsset) => setState(() => selectedIcon = newVal ?? 'category'),
                ),
                icon: const Icon(Icons.grid_view, size: 16),
                label: const Text('Cambiar'),
              ),
            ),
            const SizedBox(height: 10),
            LogoSelectorField(
              selectedLogo: selectedIcon.endsWith('.png') ? selectedIcon : null,
              onSelect: (logo) => setState(() => selectedIcon = logo ?? 'category'),
              currentName: nameCtrl.text,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (nameCtrl.text.isNotEmpty) {
              final data = {
                'name': nameCtrl.text,
                'type': type,
                'color': selectedColor.value, // Guardar como int ARGB
                'icon': selectedIcon,
                'budgetAmount': type == 'EXPENSE' ? (double.tryParse(budgetCtrl.text) ?? 0.0) : 0.0,
                'budgetCurrency': type == 'EXPENSE' ? budgetCurrency : 'UYU',
              };
              if (isEdit) {
                widget.service.updateCategory(widget.category!['id'], data);
              } else {
                widget.service.addCategory(data);
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
