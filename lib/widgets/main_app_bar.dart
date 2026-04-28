import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../dialogs/category_distribution_dialog.dart';
import '../utils/export_utils.dart';
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
      title: const Text(
        'MIS FINANZAS',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        IconButton(
          icon: const Icon(Icons.pie_chart_outline),
          tooltip: 'Distribución de gastos',
          onPressed: () => _showDistribution(context),
        ),
        IconButton(
          icon: const Icon(Icons.query_stats),
          tooltip: 'Análisis histórico',
          onPressed: () => Navigator.pushNamed(context, '/statistics'),
        ),
        IconButton(
          icon: const Icon(Icons.flag_outlined),
          tooltip: 'Metas de ahorro',
          onPressed: () => Navigator.pushNamed(context, '/goals'),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_outlined),
          tooltip: 'Presupuestos',
          onPressed: () => Navigator.pushNamed(context, '/budgets'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configuración rápida',
          onPressed: () => Navigator.pushNamed(context, '/setup'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value, monthYearLabel),
          itemBuilder: (context) => _buildMenuItems(),
        ),
        const SizedBox(width: 8),
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
      const PopupMenuItem(
        value: 'generate',
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: Colors.teal),
            SizedBox(width: 12),
            Text('Cargar Plantillas'),
          ],
        ),
      ),
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
    } else if (value == 'setup') {
      Navigator.pushNamed(context, '/setup');
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
      final confirm = await _showConfirmDialog(
        context,
        'Limpiar Mes',
        '¿Borrar todos los movimientos de $label? (No borra las plantillas)',
        'Limpiar',
        isDestructive: true,
      );
      if (confirm == true) {
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
