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
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (ej: Banco Santander)'),
                onChanged: (_) => setS(() {}),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: currency,
                items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setS(() => currency = v!),
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: 15),
              _buildLogoSelector(selectedLogo, (logo) => setS(() => selectedLogo = logo), nameCtrl.text),
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

  Widget _buildLogoSelector(String? selectedLogo, Function(String?) onSelect, String currentName) {
    final List<String> availableLogos = [
      'banco-republica.png', 'itau.png', 'santander.png', 'bbva.png', 'scotiabank.png',
      'oca.png', 'oca-blue.png', 'prex.png', 'midinero.png', 'ahorros.png', 'cabal.png',
      'srpffaa.png', 'dinero.png', 'queen.png', 'bodyguard.png', 'alquiler.png',
      'ose.png', 'ute.png', 'imm.png', 'ces.png', 'gastos-comunes.png',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Logo Identificatorio:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showLogoSearchDialog(currentName, onSelect),
              icon: const Icon(Icons.search, size: 16, color: Colors.teal),
              label: Text(
                currentName.isEmpty ? 'Buscar por nombre' : 'Buscar Online',
                style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.teal.withOpacity(0.05),
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
              // Vista previa del logo actual (si es URL)
              if (selectedLogo != null && selectedLogo.startsWith('http'))
                _logoItem(selectedLogo, true, () => onSelect(null), isUrl: true),

              // Opción Automática
              _logoItem(null, selectedLogo == null, () => onSelect(null), isAuto: true),
              
              ...availableLogos.map((logoName) {
                return _logoItem(logoName, selectedLogo == logoName, () => onSelect(logoName));
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoItem(String? logo, bool isSelected, VoidCallback onTap, {bool isAuto = false, bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.teal : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1),
                boxShadow: isSelected ? [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 4)] : null,
              ),
              child: Center(
                child: isAuto 
                  ? const Icon(Icons.auto_awesome, size: 20, color: Colors.grey)
                  : ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: isUrl 
                          ? Image.network(logo!, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                          : Image.asset('assets/logos/$logo', fit: BoxFit.contain),
                      ),
                    ),
              ),
            ),
            if (isUrl) const Text('Web', style: TextStyle(fontSize: 8, color: Colors.teal, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showLogoSearchDialog(String initialName, Function(String?) onSelect) {
    String predictDomain(String name) {
      String d = name.toLowerCase().trim().replaceAll(' ', '');
      if (d.isEmpty) return "";

      if (d.contains('itau')) return "itau.com.uy";
      if (d.contains('santander')) return "santander.com.uy";
      if (d.contains('brou')) return "brou.com.uy";
      if (d.contains('oca')) return "oca.com.uy";
      if (d.contains('bbva')) return "bbva.com.uy";
      if (d.contains('scotia')) return "scotiabank.com.uy";
      if (d.contains('hsbc')) return "hsbc.com.uy";
      if (d.contains('prex')) return "prexcard.com";
      if (d.contains('visa')) return "visa.com";
      if (d.contains('master')) return "mastercard.com";
      if (d.contains('antel')) return "antel.com.uy";
      if (d.contains('ose')) return "ose.com.uy";
      if (d.contains('ute')) return "ute.com.uy";
      if (d.contains('banco')) return "$d.com.uy";
      
      return d.contains('.') ? d : "$d.com";
    }

    final domainCtrl = TextEditingController(text: predictDomain(initialName));

    // Usamos una variable para rastrear qué logo funcionó realmente
    String effectiveLogoUrl = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentDomain = domainCtrl.text.trim();
          
          String getPrimaryUrl(String input) {
            if (input.isEmpty) return "";
            String target;
            if (input.startsWith('http')) {
              target = input;
            } else {
              final d = input.toLowerCase();
              if (d.contains('antel')) target = "https://www.antel.com.uy/image/layout_set_logo?img_id=3960533";
              else if (d.contains('ute')) target = "https://www.ute.com.uy/sites/default/files/logo_ute.png";
              else if (d.contains('prex')) target = "https://www.prexcard.com/images/logo-prex.png";
              else if (d.contains('brou') || d.contains('republica')) target = "https://www.brou.com.uy/documents/20124/38202/logo-brou.png";
              else if (d.contains('hsbc')) target = "https://www.hsbc.com.uy/content/dam/hsbc/uy/images/logos/logo-hsbc.png";
              else target = "https://logo.clearbit.com/${input.contains('.') ? input : '$input.com'}";
            }
            return "https://images.weserv.nl/?url=${Uri.encodeComponent(target)}&n=1&il";
          }

          final primaryUrl = getPrimaryUrl(currentDomain);
          // Por defecto la efectiva es la primaria
          if (effectiveLogoUrl == "") effectiveLogoUrl = primaryUrl;

          return AlertDialog(
            title: const Text('Buscador de Logos'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: domainCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Empresa o dominio',
                    hintText: 'ej: Santander, Itaú, OCA, Pepsi',
                  ),
                  onChanged: (v) {
                    effectiveLogoUrl = ""; // Reset al escribir
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 20),
                if (currentDomain.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          width: 80,
                          child: Image.network(
                            primaryUrl,
                            key: ValueKey('p_$primaryUrl'),
                            fit: BoxFit.contain,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (frame != null) effectiveLogoUrl = primaryUrl;
                              return child;
                            },
                            errorBuilder: (ctx, err, st) {
                              final domain = currentDomain.contains('.') ? currentDomain : '$currentDomain.com';
                              final fallback = "https://images.weserv.nl/?url=${Uri.encodeComponent('https://www.google.com/s2/favicons?domain=$domain&sz=128')}&il";
                              
                              return Image.network(
                                fallback,
                                key: ValueKey('f_$fallback'),
                                fit: BoxFit.contain,
                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (frame != null) effectiveLogoUrl = fallback;
                                  return child;
                                },
                                errorBuilder: (ctx, err2, st2) {
                                  effectiveLogoUrl = "";
                                  return const Icon(Icons.business_rounded, size: 40, color: Colors.teal);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Vista previa para: $currentDomain', 
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(
                onPressed: currentDomain.isEmpty ? null : () {
                  onSelect(effectiveLogoUrl != "" ? effectiveLogoUrl : primaryUrl);
                  Navigator.pop(ctx);
                },
                child: const Text('Usar este Logo'),
              ),
            ],
          );
        },
      ),
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
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Concepto'),
                onChanged: (_) => setS(() {}),
              ),
              const SizedBox(height: 15),
              _buildLogoSelector(selectedLogo, (logo) => setS(() => selectedLogo = logo), titleController.text),
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
