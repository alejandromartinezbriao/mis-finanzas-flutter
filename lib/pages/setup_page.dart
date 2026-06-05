import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/setup/template_list_tab.dart';
import '../widgets/setup/accounts_list_tab.dart';
import '../widgets/setup/categories_list_tab.dart';
import '../widgets/setup/goals_list_tab.dart';
import '../widgets/setup/subscriptions_list_tab.dart';
import '../widgets/setup/family_circle_tab.dart';

import '../dialogs/setup/balance_dialog.dart';
import '../dialogs/setup/template_edit_dialog.dart';
import '../dialogs/setup/category_dialog.dart';
import '../dialogs/setup/goal_dialog.dart';
import '../dialogs/setup/subscription_dialog.dart';

class SetupPage extends StatefulWidget {
  final int initialIndex;
  final Map<String, dynamic>? goalToEdit;
  const SetupPage({super.key, this.initialIndex = 0, this.goalToEdit});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with SingleTickerProviderStateMixin {
  final FirebaseService _service = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7, // Aumentado a 7 para incluir Familia
      vsync: this, 
      initialIndex: widget.initialIndex >= 7 ? 6 : widget.initialIndex
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.goalToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGoal(widget.goalToEdit);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTemplate(Map<String, dynamic>? t, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TemplateEditDialog(service: _service, template: t, type: type),
    );
  }

  void _showBalance(Map<String, dynamic>? a) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BalanceDialog(service: _service, account: a),
    );
  }

  void _showCategory(Map<String, dynamic>? c) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryDialog(service: _service, category: c),
    );
  }

  void _showSubscription(Map<String, dynamic>? s) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionDialog(service: _service, sub: s),
    );
  }

  void _showGoal(Map<String, dynamic>? g) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GoalDialog(service: _service, goal: g),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Deseas salir de tu cuenta?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService().signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.family_restroom), text: 'Familia'), // NUEVA PESTAÑA
            Tab(icon: Icon(Icons.money_off), text: 'Gastos'),
            Tab(icon: Icon(Icons.attach_money), text: 'Ingresos'),
            Tab(icon: Icon(Icons.account_balance), text: 'Cuentas'),
            Tab(icon: Icon(Icons.category), text: 'Categorías'),
            Tab(icon: Icon(Icons.subscriptions), text: 'Suscrip.'),
            Tab(icon: Icon(Icons.savings), text: 'Metas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FamilyCircleTab(service: _service), // NUEVO CONTENIDO
          TemplateListTab(type: 'EXPENSE', service: _service, onEdit: (t, type) => _showTemplate(t, type)),
          TemplateListTab(type: 'INCOME', service: _service, onEdit: (t, type) => _showTemplate(t, type)),
          AccountsListTab(service: _service, onEdit: (a) => _showBalance(a)),
          CategoriesListTab(service: _service, onEdit: (c) => _showCategory(c)),
          SubscriptionsListTab(service: _service, onEdit: (s) => _showSubscription(s)),
          GoalsListTab(service: _service, onEdit: (g) => _showGoal(g)),
        ],
      ),
      bottomNavigationBar: _tabController.index == 0 ? null : SafeArea( // Ocultar botón flotante en pestaña Familia
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () {
                switch (_tabController.index) {
                  case 1: _showTemplate(null, 'EXPENSE'); break;
                  case 2: _showTemplate(null, 'INCOME'); break;
                  case 3: _showBalance(null); break;
                  case 4: _showCategory(null); break;
                  case 5: _showSubscription(null); break;
                  case 6: _showGoal(null); break;
                }
              },
              icon: const Icon(Icons.add),
              label: Text(_getButtonLabel(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  String _getButtonLabel() {
    switch (_tabController.index) {
      case 1: return 'NUEVO GASTO / TARJETA';
      case 2: return 'NUEVO INGRESO FIJO';
      case 3: return 'NUEVA CUENTA';
      case 4: return 'NUEVA CATEGORÍA';
      case 5: return 'NUEVA SUSCRIPCIÓN';
      case 6: return 'NUEVA META';
      default: return 'AÑADIR';
    }
  }
}
