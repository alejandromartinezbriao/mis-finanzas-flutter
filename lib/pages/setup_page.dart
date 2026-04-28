import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/brand_icon.dart';

class SetupPage extends StatefulWidget {
  final int initialIndex;
  const SetupPage({super.key, this.initialIndex = 0});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with SingleTickerProviderStateMixin {
  final FirebaseService _service = FirebaseService();
  late TabController _tabController;
  DateTime _budgetDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6, 
      vsync: this, 
      initialIndex: widget.initialIndex
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.money_off), text: 'Gastos'),
            Tab(icon: Icon(Icons.attach_money), text: 'Ingresos'),
            Tab(icon: Icon(Icons.account_balance), text: 'Mis Cuentas'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Categorías'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Presupuestos'),
            Tab(icon: Icon(Icons.flag_outlined), text: 'Metas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplateList('EXPENSE'),
          _buildTemplateList('INCOME'),
          _buildBalanceAccountsList(),
          _buildCategoriesManagementList(),
          _buildBudgetList(),
          _buildGoalsManagementList(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                if (_tabController.index == 2) {
                  _showBalanceDialog();
                } else if (_tabController.index == 3) {
                  _showCategoryDialog();
                } else if (_tabController.index == 4) {
                  _showBudgetHelpDialog();
                } else if (_tabController.index == 5) {
                  _showGoalDialog();
                } else {
                  _showEditTemplateDialog(null, _tabController.index == 0 ? 'EXPENSE' : 'INCOME');
                }
              },
              icon: Icon(_tabController.index == 4 ? Icons.help_outline : Icons.add_circle_outline),
              label: Text(_getButtonLabel(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getButtonLabel() {
    switch (_tabController.index) {
      case 0: return 'NUEVO GASTO FIJO';
      case 1: return 'NUEVO INGRESO FIJO';
      case 2: return 'NUEVA CUENTA';
      case 3: return 'NUEVA CATEGORÍA';
      case 4: return 'AYUDA PRESUPUESTOS';
      case 5: return 'NUEVA META';
      default: return 'AÑADIR';
    }
  }

  // --- GESTIÓN DE PRESUPUESTOS ---

  Widget _buildBudgetList() {
    final monthLabel = DateFormat('MMMM yyyy', 'es_ES').format(_budgetDate).toUpperCase();
    
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _budgetDate = DateTime(_budgetDate.year, _budgetDate.month - 1)),
              ),
              const SizedBox(width: 10),
              Text(
                monthLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.1),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _budgetDate = DateTime(_budgetDate.year, _budgetDate.month + 1)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.getCategories(type: 'EXPENSE'),
            builder: (context, catSnap) {
              if (catSnap.hasError) return Center(child: Text('Error: ${catSnap.error}'));
              if (!catSnap.hasData) return const Center(child: CircularProgressIndicator());
              final categories = catSnap.data!;
              
              if (categories.isEmpty) {
                return const Center(child: Text('Crea categorías de GASTO primero.'));
              }
              
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getBudgets(_budgetDate.month, _budgetDate.year),
                builder: (context, budSnap) {
                  if (budSnap.hasError) return Center(child: Text('Error Presupuestos: ${budSnap.error}'));
                  final budgets = budSnap.data ?? [];
                  
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final budget = budgets.firstWhere(
                        (b) => b['categoryName'] == cat['name'],
                        orElse: () => {'amount': 0.0, 'currency': 'UYU'},
                      );
                      
                      final String budgetCurrency = budget['currency'] ?? 'UYU';
                      final controller = TextEditingController(
                        text: (budget['amount'] as num) > 0 
                            ? (budgetCurrency == 'UYU' 
                                ? (budget['amount'] as num).toStringAsFixed(0) 
                                : (budget['amount'] as num).toStringAsFixed(2)) 
                            : '',
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(cat['color'] ?? 0xFF9E9E9E).withValues(alpha: 0.1),
                          child: Icon(_getIconData(cat['icon']), color: Color(cat['color'] ?? 0xFF9E9E9E)),
                        ),
                        title: Text(cat['name']),
                        trailing: SizedBox(
                          width: 180,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              DropdownButton<String>(
                                value: budgetCurrency,
                                underline: const SizedBox(),
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (newCurrency) {
                                  if (newCurrency != null) {
                                    final amount = double.tryParse(controller.text) ?? 0.0;
                                    _service.setBudget(
                                      cat['name'], 
                                      amount, 
                                      _budgetDate.month, 
                                      _budgetDate.year, 
                                      newCurrency
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.end,
                                  decoration: InputDecoration(
                                    prefixText: budgetCurrency == 'UYU' ? r'$ ' : r'U$S ',
                                    hintText: '0',
                                    border: const UnderlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (val) {
                                    final amount = double.tryParse(val) ?? 0.0;
                                    _service.setBudget(
                                      cat['name'], 
                                      amount, 
                                      _budgetDate.month, 
                                      _budgetDate.year, 
                                      budgetCurrency
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- GESTIÓN DE CATEGORÍAS ---

  Widget _buildCategoriesManagementList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!;
        if (categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Crea tus propias categorías para clasificar tus gastos e ingresos.', textAlign: TextAlign.center),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final Color color = Color(cat['color'] ?? 0xFF9E9E9E);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(_getIconData(cat['icon']), color: color),
                ),
                title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(cat['type'] == 'EXPENSE' ? 'Gasto' : 'Ingreso'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _service.deleteCategory(cat['id']),
                ),
                onTap: () => _showCategoryDialog(category: cat),
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
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
                const Align(alignment: Alignment.centerLeft, child: Text('Icono:', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    'shopping_cart', 'restaurant', 'directions_car', 'home',
                    'flash_on', 'water_drop', 'phone_android', 'medical_services',
                    'school', 'fitness_center', 'flight', 'movie',
                    'payments', 'account_balance', 'redeem', 'pets',
                    'work', 'sports_esports', 'stroller', 'cleaning_services'
                  ].map((iconName) => GestureDetector(
                    onTap: () => setS(() => selectedIcon = iconName),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == iconName ? Color(selectedColor).withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selectedIcon == iconName ? Color(selectedColor) : Colors.grey.shade300),
                      ),
                      child: Icon(_getIconData(iconName), color: selectedIcon == iconName ? Color(selectedColor) : Colors.grey),
                    ),
                  )).toList(),
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
                    _service.updateCategory(category['id'], data);
                  } else {
                    _service.addCategory(data);
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

  IconData _getIconData(String name) {
    switch (name) {
      case 'shopping_cart': return Icons.shopping_cart;
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'flash_on': return Icons.flash_on;
      case 'water_drop': return Icons.water_drop;
      case 'phone_android': return Icons.phone_android;
      case 'medical_services': return Icons.medical_services;
      case 'school': return Icons.school;
      case 'fitness_center': return Icons.fitness_center;
      case 'flight': return Icons.flight;
      case 'movie': return Icons.movie;
      case 'payments': return Icons.payments;
      case 'account_balance': return Icons.account_balance;
      case 'redeem': return Icons.redeem;
      case 'pets': return Icons.pets;
      case 'work': return Icons.work;
      case 'sports_esports': return Icons.sports_esports;
      case 'stroller': return Icons.stroller;
      case 'cleaning_services': return Icons.cleaning_services;
      default: return Icons.category;
    }
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
                initialValue: currency,
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
      'ose.png', 'ute.png', 'imm.png', 'ces.png', 'gastos-comunes.png', 'antel.png'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Logo Identificatorio:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showLogoGalleryDialog(onSelect),
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
              ...availableLogos.map((logoName) => _logoItem(logoName, selectedLogo == logoName, () => onSelect(logoName))),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoSearchDialog(String currentName, Function(String?) onSelect) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buscar Logo Online'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa una URL de imagen o el nombre para identificar el logo.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://ejemplo.com/logo.png',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) onSelect(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Usar'),
          ),
        ],
      ),
    );
  }

  Widget _logoItem(String? logo, bool isSelected, VoidCallback onTap, {bool isAuto = false, bool isUrl = false}) {
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
              ? Icon(Icons.auto_awesome, color: isSelected ? Colors.teal : Colors.grey)
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

  void _showBudgetHelpDialog() {
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

  // --- GESTIÓN DE METAS ---

  Widget _buildGoalsManagementList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getGoals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final goals = snapshot.data!;
        if (goals.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Define tus metas financieras (ej: Ahorro para viaje, Cambio de auto).', textAlign: TextAlign.center),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final g = goals[index];
            final double target = (g['targetAmount'] as num).toDouble();
            final double current = (g['currentAmount'] as num).toDouble();
            final double percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
            final currency = g['currency'] ?? 'UYU';
            final format = currency == 'UYU' 
                ? NumberFormat.currency(locale: 'es_UY', symbol: r'$', decimalDigits: 0)
                : NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 2);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(_getIconData(g['icon'] ?? 'flag'), color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(g['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${format.format(current)} de ${format.format(target)}'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _service.deleteGoal(g['id']),
                ),
                onTap: () => _showGoalDialog(goal: g),
              ),
            );
          },
        );
      },
    );
  }

  void _showGoalDialog({Map<String, dynamic>? goal}) {
    final isEdit = goal != null;
    final titleCtrl = TextEditingController(text: goal?['title'] ?? '');
    final targetCtrl = TextEditingController(text: goal?['targetAmount']?.toString() ?? '');
    final currentCtrl = TextEditingController(text: goal?['currentAmount']?.toString() ?? '');
    String currency = goal?['currency'] ?? 'UYU';
    String selectedIcon = goal?['icon'] ?? 'flag';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isEdit ? 'Editar Meta' : 'Nueva Meta'),
          content: SingleChildScrollView(
            child: Column(
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
                        value: currency,
                        items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setS(() => currency = v!),
                        decoration: const InputDecoration(labelText: 'Moneda'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: targetCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Monto Objetivo', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto ya ahorrado', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Align(alignment: Alignment.centerLeft, child: Text('Icono representativo:', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    'flag', 'flight', 'directions_car', 'home', 'school', 'fitness_center', 'movie', 'redeem', 'pets', 'work'
                  ].map((iconName) => GestureDetector(
                    onTap: () => setS(() => selectedIcon = iconName),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == iconName ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selectedIcon == iconName ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
                      ),
                      child: Icon(_getIconData(iconName), color: selectedIcon == iconName ? Theme.of(context).colorScheme.primary : Colors.grey),
                    ),
                  )).toList(),
                ),
              ],
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
                  };
                  if (isEdit) {
                    _service.updateGoal(goal['id'], data);
                  } else {
                    _service.addGoal(data);
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

  void _showLogoGalleryDialog(Function(String?) onSelect) {
    final List<String> availableLogos = [
      'antel.png', 'ute.png', 'ose.png', 'banco-republica.png',
      'santander.png', 'itau.png', 'oca.png', 'bbva.png',
      'scotiabank.png', 'hsbc.png', 'visa.png', 'mastercard.png',
      'cabal.png', 'alquiler.png', 'gastos-comunes.png', 'midinero.png',
      'imm.png', 'prex.png', 'generic-bank.png'
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Logo'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: availableLogos.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return InkWell(
                  onTap: () {
                    onSelect(null);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.grey),
                  ),
                );
              }
              final logo = availableLogos[index - 1];
              return InkWell(
                onTap: () {
                  onSelect(logo);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset('assets/logos/$logo', fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateList(String type) {
    return Column(
      children: [
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
    String? selectedCategoryId;
    bool isCreditCard = template?['isCreditCard'] ?? false;
    String? selectedLogo = template?['brandLogo'];
    List<Map<String, dynamic>> subscriptions = List<Map<String, dynamic>>.from(template?['subscriptions'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getCategories(type: type),
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
                    _buildLogoSelector(selectedLogo, (logo) => setS(() => selectedLogo = logo), titleController.text),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      hint: const Text('Seleccionar Categoría'),
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                      items: categories.map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Row(
                          children: [
                            Icon(_getIconData(c['icon'] ?? 'category'), color: Color(c['color'] ?? 0xFF9E9E9E), size: 20),
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
                          'brandLogo': selectedLogo,
                          'subscriptions': isCreditCard ? subscriptions : [],
                        };
                        if (isEdit) {
                          _service.updateTemplate(template['id'], data);
                        } else {
                          _service.addTemplate(data);
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
}
