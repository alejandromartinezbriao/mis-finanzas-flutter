import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/brand_icon.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Maestra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Estás seguro de que quieres salir?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService().signOut();
                if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.money_off), text: 'Gastos'),
            Tab(icon: Icon(Icons.attach_money), text: 'Ingresos'),
            Tab(icon: Icon(Icons.account_balance), text: 'Mis Cuentas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplateList('EXPENSE', _expenseSuggestions),
          _buildTemplateList('INCOME', []),
          _buildBalanceAccountsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 2) {
            _showBalanceDialog();
          } else {
            _showEditTemplateDialog(null, _tabController.index == 0 ? 'EXPENSE' : 'INCOME');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- WIDGET PARA LISTA DE CUENTAS DE SALDO REAL ---
  Widget _buildBalanceAccountsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getBalances(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final accounts = snapshot.data!;
        if (accounts.isEmpty) return const Center(child: Text('Configura tus cuentas para arqueo (ej: Efectivo, Banco).'));

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final acc = accounts[index];
            return Card(
              child: ListTile(
                leading: BrandIcon(name: acc['accountName'], manualLogo: acc['brandLogo'], size: 32),
                title: Text(acc['accountName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('Moneda: ${acc['currency']}', style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _service.deleteBalanceAccount(acc['id']),
                ),
                onTap: () => _showBalanceDialog(account: acc),
              ),
            );
          },
        );
      },
    );
  }

  void _showBalanceDialog({Map<String, dynamic>? account}) {
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
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej: Banco Santander)')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: currency,
                items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setS(() => currency = v!),
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: 15),
              _buildLogoSelector(selectedLogo, (logo) => setS(() => selectedLogo = logo)),
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
                    _service.updateBalanceAccountDetails(account['id'], data);
                  } else {
                    _service.addBalanceAccount(nameCtrl.text, currency, logo: selectedLogo);
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

  Widget _buildLogoSelector(String? selectedLogo, Function(String?) onSelect) {
    final List<String> availableLogos = [
      'banco-republica.png',
      'itau.png',
      'santander.png',
      'bbva.png',
      'scotiabank.png',
      'oca.png',
      'oca-blue.png',
      'prex.png',
      'midinero.png',
      'ahorros.png',
      'cabal.png',
      'srpffaa.png',
      'dinero.png',
      'queen.png',
      'bodyguard.png',
      'alquiler.png',
      'ose.png',
      'ute.png',
      'imm.png',
      'ces.png',
      'gastos-comunes.png',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Logo Identificatorio:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Opción Automática / Genérica
              GestureDetector(
                onTap: () => onSelect(null),
                child: Container(
                  width: 45,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: selectedLogo == null ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                    border: Border.all(color: selectedLogo == null ? Colors.blue : Colors.grey.withOpacity(0.3)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, size: 20, color: Colors.grey),
                ),
              ),
              ...availableLogos.map((logoName) {
                final isSelected = selectedLogo == logoName;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => onSelect(logoName),
                    child: Container(
                      width: 45,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                        border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Image.asset('assets/logos/$logoName', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  // --- (El resto de métodos _buildTemplateList y _showEditTemplateDialog se mantienen iguales o similares) ---
  // He recortado aquí para brevedad, pero en la escritura real mantendré todo el archivo coherente.

  Widget _buildTemplateList(String type, List<Map<String, String>> suggestions) {
    return Column(
      children: [
        const SizedBox(height: 10),
        if (suggestions.isNotEmpty)
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
              return ListView.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  return ListTile(
                    leading: BrandIcon(name: t['title'], manualLogo: t['brandLogo'], size: 32),
                    title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(
                      '${t['currency']} ${t['defaultAmount'] != null ? "(${(t['defaultAmount'] as num).toStringAsFixed(0)}) " : ""}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _service.deleteTemplate(t['id'])),
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
    String? selectedLogo = template?['brandLogo'];
    List<Map<String, dynamic>> subscriptions = List<Map<String, dynamic>>.from(template?['subscriptions'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: Text(isEdit ? 'Editar Plantilla' : 'Nueva Plantilla'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Concepto')),
              const SizedBox(height: 15),
              _buildLogoSelector(selectedLogo, (logo) => setS(() => selectedLogo = logo)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(value: selectedCurrency, items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setS(() => selectedCurrency = v!), decoration: const InputDecoration(labelText: 'Moneda'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: defaultAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto Fijo'))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: dayController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: type == 'EXPENSE' ? 'Día de vencimiento' : 'Día de cobro')),
              if (type == 'EXPENSE')
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('¿Es Tarjeta de Crédito?'), value: isCreditCard, onChanged: (v) => setS(() => isCreditCard = v)),
            ],
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
                  'brandLogo': selectedLogo,
                  'subscriptions': isCreditCard ? subscriptions : [],
                };
                if (isEdit) _service.updateTemplate(template['id'], data); else _service.addTemplate(data);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
