import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with SingleTickerProviderStateMixin {
  final FirebaseService _service = FirebaseService();
  late TabController _tabController;

  final List<Map<String, String>> _expenseSuggestions = [
    {'title': 'Alquiler', 'category': 'Vivienda'},
    {'title': 'VISA Scotiabank', 'category': 'Tarjetas'},
    {'title': 'VISA Itaú', 'category': 'Tarjetas'},
    {'title': 'OCA', 'category': 'Tarjetas'},
    {'title': 'OSE', 'category': 'Servicios'},
    {'title': 'IMM', 'category': 'Impuestos'},
    {'title': 'Antel', 'category': 'Servicios'},
  ];

  final List<Map<String, String>> _incomeSuggestions = [
    {'title': 'Sueldo', 'category': 'Laboral'},
    {'title': 'Aguinaldo', 'category': 'Laboral'},
    {'title': 'Freelance', 'category': 'Laboral'},
    {'title': 'Renta', 'category': 'Inversión'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Maestra'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.money_off), text: 'Gastos Fijos'),
            Tab(icon: Icon(Icons.attach_money), text: 'Ingresos Fijos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplateList('EXPENSE', _expenseSuggestions),
          _buildTemplateList('INCOME', _incomeSuggestions),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditTemplateDialog(null, _tabController.index == 0 ? 'EXPENSE' : 'INCOME'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generar Mes Actual'),
          onPressed: () async {
            final now = DateTime.now();
            await _service.generateMonthlyTransactions(now.month, now.year);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mes generado exitosamente')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTemplateList(String type, List<Map<String, String>> suggestions) {
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final s = suggestions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ActionChip(
                  label: Text(s['title']!),
                  onPressed: () => _service.addTemplate({
                    'title': s['title'],
                    'category': s['category'],
                    'currency': 'UYU',
                    'dueDay': null,
                    'type': type,
                  }),
                ),
              );
            },
          ),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.getTemplates(type: type),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final templates = snapshot.data!;
              if (templates.isEmpty) return const Center(child: Text('No hay plantillas configuradas.'));

              return ListView.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  return ListTile(
                    leading: Icon(type == 'EXPENSE' ? Icons.remove_circle_outline : Icons.add_circle_outline, 
                                 color: type == 'EXPENSE' ? Colors.red : Colors.green),
                    title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${t['currency']} ${t['defaultAmount'] != null ? "(${(t['defaultAmount'] as num).toStringAsFixed(0)}) " : ""}${t['dueDay'] != null ? "- Día: ${t['dueDay']}" : ""}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _service.deleteTemplate(t['id']),
                    ),
                    onTap: () => _showEditTemplateDialog(t, type),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditTemplateDialog(Map<String, dynamic>? template, String type) {
    final isEdit = template != null;
    final titleController = TextEditingController(text: template?['title'] ?? '');
    final dayController = TextEditingController(text: template?['dueDay']?.toString() ?? '');
    final defaultAmountController = TextEditingController(text: template?['defaultAmount']?.toString() ?? '');
    String selectedCurrency = template?['currency'] ?? 'UYU';
    bool isCreditCard = template?['isCreditCard'] ?? false;
    
    // Lista local de suscripciones para el diálogo
    List<Map<String, dynamic>> subscriptions = List<Map<String, dynamic>>.from(template?['subscriptions'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar Plantilla' : 'Nueva Plantilla'),
              scrollable: true,
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Concepto')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCurrency,
                            items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setDialogState(() => selectedCurrency = val!),
                            decoration: const InputDecoration(labelText: 'Moneda'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: defaultAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Monto Fijo'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dayController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: type == 'EXPENSE' ? 'Día de vencimiento' : 'Día de cobro (opcional)'),
                    ),
                    if (type == 'EXPENSE') ...[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('¿Es Tarjeta de Crédito?'),
                        value: isCreditCard,
                        onChanged: (val) => setDialogState(() => isCreditCard = val),
                      ),
                      if (isCreditCard) ...[
                        const Divider(),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Suscripciones / Débitos Fijos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        ...subscriptions.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var sub = entry.value;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('${sub['name']} (${selectedCurrency} ${sub['amount']})'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                              onPressed: () => setDialogState(() => subscriptions.removeAt(idx)),
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () async {
                            final nameCtrl = TextEditingController();
                            final amtCtrl = TextEditingController();
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Añadir Suscripción'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej: Netflix)')),
                                    TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto')),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                  TextButton(onPressed: () {
                                    if (nameCtrl.text.isNotEmpty && amtCtrl.text.isNotEmpty) {
                                      setDialogState(() {
                                        subscriptions.add({
                                          'name': nameCtrl.text,
                                          'amount': double.parse(amtCtrl.text),
                                        });
                                      });
                                      Navigator.pop(ctx);
                                    }
                                  }, child: const Text('Añadir')),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar suscripción'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    final data = {
                      'title': titleController.text,
                      'currency': selectedCurrency,
                      'dueDay': int.tryParse(dayController.text),
                      'defaultAmount': double.tryParse(defaultAmountController.text) ?? 0.0,
                      'type': type,
                      'category': isCreditCard ? 'Tarjeta' : (type == 'EXPENSE' ? 'Fijo' : 'Ingreso'),
                      'isCreditCard': isCreditCard,
                      'subscriptions': isCreditCard ? subscriptions : [],
                    };
                    if (isEdit) {
                      _service.updateTemplate(template['id'], data);
                    } else {
                      _service.addTemplate(data);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
