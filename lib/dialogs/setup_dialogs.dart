import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'setup/balance_dialog.dart';
import 'setup/template_edit_dialog.dart';
import 'setup/category_dialog.dart';
import 'setup/goal_dialog.dart';
import 'setup/subscription_dialog.dart';

class SetupDialogs {
  static void showCategoryDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? category) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CategoryDialog(service: service, category: category),
    );
  }

  static void showBalanceDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? account) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BalanceDialog(service: service, account: account),
    );
  }

  static void showGoalDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? goal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GoalDialog(service: service, goal: goal),
    );
  }

  static void showEditTemplateDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? template, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TemplateEditDialog(service: service, template: template, type: type),
    );
  }

  static void showSubscriptionDialog(BuildContext context, FirebaseService service, Map<String, dynamic>? sub) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SubscriptionDialog(service: service, sub: sub),
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aquí puedes definir cuánto planeas gastar por categoría cada mes.\n\n'
              '• Los presupuestos son mensuales.\n'
              '• Verás una barra de progreso en la sección de Estadísticas.\n'
              '• Te ayuda a no excederte de tus límites financieros.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }
}
