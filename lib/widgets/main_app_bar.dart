import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../dialogs/category_distribution_dialog.dart';
import '../dialogs/ai_analysis_dialog.dart';
import '../utils/export_utils.dart';
import '../utils/dialog_utils.dart';
import 'package:intl/intl.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final FirebaseService service;
  final DateTime viewingDate;
  final NumberFormat uyuFormat;
  final NumberFormat usdFormat;

  const MainAppBar({
    super.key,
    required this.service,
    required this.viewingDate,
    required this.uyuFormat,
    required this.usdFormat,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final monthYearLabel = DateFormat('MMMM yyyy', 'es_ES').format(viewingDate).toUpperCase();

    return AppBar(
      toolbarHeight: 50,
      titleSpacing: 12,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Mis Finanzas',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        IconButton(
          icon: const Icon(Icons.pie_chart_outline, size: 22),
          tooltip: 'Distribución',
          onPressed: () => _showDistribution(context),
        ),
        IconButton(
          icon: const Icon(Icons.query_stats, size: 22),
          tooltip: 'Estadísticas',
          onPressed: () => Navigator.pushNamed(context, '/statistics'),
        ),
        IconButton(
          icon: const Icon(Icons.savings_outlined, size: 22),
          tooltip: 'Metas',
          onPressed: () => Navigator.pushNamed(context, '/goals'),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_outlined, size: 22),
          tooltip: 'Presupuestos',
          onPressed: () => Navigator.pushNamed(context, '/budgets'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value, monthYearLabel),
          itemBuilder: (context) => _buildMenuItems(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showDistribution(BuildContext context) {
    service.getTransactions(month: viewingDate.month, year: viewingDate.year).first.then((txs) {
      service.getCategories(type: 'EXPENSE').first.then((cats) {
        showDialog(
          context: context,
          builder: (context) => CategoryDistributionDialog(
            transactions: txs,
            categories: cats,
            uyuFormat: uyuFormat,
            usdFormat: usdFormat,
          ),
        );
      });
    });
  }

  void _showAiAdvisor(BuildContext context, String monthLabel) async {
    // 1. Obtener transacciones del mes
    final txs = await service.getTransactions(month: viewingDate.month, year: viewingDate.year).first;
    
    // 2. Obtener presupuestos del mes
    final budgets = await service.getBudgets(viewingDate.month, viewingDate.year).first;
    
    // 3. Calcular presupuesto total (sumando todos los límites de categorías)
    double totalBudget = budgets.fold(0.0, (sum, b) => sum + (b['amount'] ?? 0.0));

    if (!context.mounted) return;

    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay gastos este mes para analizar.'))
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AiAnalysisDialog(
        transactions: txs,
        monthlyBudget: totalBudget > 0 ? totalBudget : 1000.0, // Fallback si no hay presupuesto definido
        monthLabel: monthLabel,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    return [
      const PopupMenuItem(
        value: 'setup',
        child: Row(
          children: [
            Icon(Icons.settings, size: 20),
            SizedBox(width: 12),
            Text('Panel de Control'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'ai_advisor',
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: Colors.purpleAccent),
            SizedBox(width: 12),
            Text('Asesor Financiero IA'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'generate',
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: Colors.amber),
            SizedBox(width: 12),
            Text('Cargar Plantillas'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'maintenance',
        child: Row(
          children: [
            Icon(Icons.build_circle_outlined, size: 20, color: Colors.teal),
            SizedBox(width: 12),
            Text('Mantenimiento'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'export',
        child: Row(
          children: [
            Icon(Icons.download, size: 20, color: Colors.blue),
            SizedBox(width: 12),
            Text('Exportar este Mes'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'clear',
        child: Row(
          children: [
            Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.orange),
            SizedBox(width: 12),
            Text('Limpiar este Mes'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'manual',
        child: Row(
          children: [
            Icon(Icons.help_outline, size: 20),
            SizedBox(width: 12),
            Text('Manual de Usuario'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'about',
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20),
            SizedBox(width: 12),
            Text('Acerca de...'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    ];
  }

  void _handleMenuAction(BuildContext context, String value, String label) async {
    if (value == 'logout') {
      final confirm = await _showConfirmDialog(
        context,
        'Cerrar Sesión',
        '¿Estás seguro de que quieres salir?',
        'Salir',
      );
      if (confirm == true) {
        await AuthService().signOut();
      }
    } else if (value == 'maintenance') {
      Navigator.pushNamed(context, '/maintenance');
    } else if (value == 'manual') {
      Navigator.pushNamed(context, '/manual');
    } else if (value == 'about') {
      Navigator.pushNamed(context, '/about');
    } else if (value == 'setup') {
      Navigator.pushNamed(context, '/setup');
    } else if (value == 'ai_advisor') {
      _showAiAdvisor(context, label);
    } else if (value == 'export') {
      final txs = await service.getTransactions(month: viewingDate.month, year: viewingDate.year).first;
      if (txs.isNotEmpty) {
        await ExportUtils.exportToCSV(txs, label);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay datos para exportar')));
        }
      }
    } else if (value == 'clear') {
      if (await DialogUtils.confirmDeletion(context, 'Todos los movimientos de $label')) {
        await service.clearMonth(viewingDate.month, viewingDate.year);
      }
    } else if (value == 'generate') {
      final confirm = await _showConfirmDialog(
        context,
        'Cargar Plantillas',
        '¿Deseas cargar los gastos e ingresos fijos para $label?\n\nNota: No se duplicarán los conceptos que ya existan.',
        'Cargar',
      );
      if (confirm == true) {
        await service.generateMonthlyTransactions(viewingDate.month, viewingDate.year);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plantillas procesadas correctamente')),
          );
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
    String actionLabel, {
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          isDestructive
              ? TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(actionLabel, style: const TextStyle(color: Colors.red)),
                )
              : FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(actionLabel),
                ),
        ],
      ),
    );
  }
}
