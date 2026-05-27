import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/setup/template_list_tab.dart';
import '../widgets/setup/accounts_list_tab.dart';
import '../widgets/setup/categories_list_tab.dart';
import '../widgets/setup/goals_list_tab.dart';
import '../widgets/setup/subscriptions_list_tab.dart';
import '../dialogs/setup_dialogs.dart';

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
      length: 6, // Reducido de 7 a 6
      vsync: this, 
      initialIndex: widget.initialIndex >= 6 ? 5 : widget.initialIndex
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.goalToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SetupDialogs.showGoalDialog(context, _service, widget.goalToEdit);
      });
    }
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
            Tab(icon: Icon(Icons.money_off), text: 'Gastos / Tarjetas'),
            Tab(icon: Icon(Icons.attach_money), text: 'Ingresos'),
            Tab(icon: Icon(Icons.account_balance), text: 'Mis Cuentas'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Categorías'),
            Tab(icon: Icon(Icons.subscriptions_outlined), text: 'Suscripciones'),
            Tab(icon: Icon(Icons.savings_outlined), text: 'Metas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TemplateListTab(
            type: 'EXPENSE', 
            service: _service, 
            onEdit: (template, type) => SetupDialogs.showEditTemplateDialog(context, _service, template, type)
          ),
          TemplateListTab(
            type: 'INCOME', 
            service: _service, 
            onEdit: (template, type) => SetupDialogs.showEditTemplateDialog(context, _service, template, type)
          ),
          AccountsListTab(
            service: _service, 
            onEdit: (account) => SetupDialogs.showBalanceDialog(context, _service, account)
          ),
          CategoriesListTab(
            service: _service, 
            onEdit: (category) => SetupDialogs.showCategoryDialog(context, _service, category)
          ),
          SubscriptionsListTab(
            service: _service,
            onEdit: (sub) => SetupDialogs.showSubscriptionDialog(context, _service, sub)
          ),
          GoalsListTab(
            service: _service, 
            onEdit: (goal) => SetupDialogs.showGoalDialog(context, _service, goal)
          ),
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
                if (_tabController.index == 0) {
                  SetupDialogs.showEditTemplateDialog(context, _service, null, 'EXPENSE');
                } else if (_tabController.index == 1) {
                  SetupDialogs.showEditTemplateDialog(context, _service, null, 'INCOME');
                } else if (_tabController.index == 2) {
                  SetupDialogs.showBalanceDialog(context, _service, null);
                } else if (_tabController.index == 3) {
                  SetupDialogs.showCategoryDialog(context, _service, null);
                } else if (_tabController.index == 4) {
                  SetupDialogs.showSubscriptionDialog(context, _service, null);
                } else if (_tabController.index == 5) {
                  SetupDialogs.showGoalDialog(context, _service, null);
                }
              },
              icon: const Icon(Icons.add_circle_outline),
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
      case 0: return 'NUEVO GASTO / TARJETA';
      case 1: return 'NUEVO INGRESO FIJO';
      case 2: return 'NUEVA CUENTA';
      case 3: return 'NUEVA CATEGORÍA';
      case 4: return 'NUEVA SUSCRIPCIÓN';
      case 5: return 'NUEVA META';
      default: return 'AÑADIR';
    }
  }
}
