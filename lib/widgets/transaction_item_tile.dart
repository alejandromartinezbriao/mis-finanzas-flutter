import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'brand_icon.dart';

class TransactionItemTile extends StatelessWidget {
  final TransactionModel transaction;
  final NumberFormat uyuFormat;
  final NumberFormat usdFormat;
  final VoidCallback onTap;
  final VoidCallback onDeleteConfirmed;

  const TransactionItemTile({
    super.key,
    required this.transaction,
    required this.uyuFormat,
    required this.usdFormat,
    required this.onTap,
    required this.onDeleteConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final format = transaction.currency == 'UYU' ? uyuFormat : usdFormat;
    final isExpense = transaction.type == 'EXPENSE';

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Eliminar movimiento?'),
            content: Text('¿Estás seguro de que quieres eliminar "${transaction.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDeleteConfirmed(),
      child: ListTile(
        dense: true,
        leading: BrandIcon(name: transaction.title, manualLogo: transaction.brandLogo, size: 32),
        title: Text(
          transaction.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: transaction.includedInCard ? TextDecoration.underline : null,
            decorationStyle: TextDecorationStyle.dotted,
          ),
        ),
        subtitle: Row(
          children: [
            if (transaction.includedInCard)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.credit_card, size: 12, color: Colors.blueGrey),
              ),
            if (transaction.dueDate != null)
              Text(
                'Vence: ${DateFormat('dd/MM').format(transaction.dueDate!)}',
                style: const TextStyle(fontSize: 11),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              format.format(transaction.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isExpense ? Theme.of(context).colorScheme.onSurface : Colors.green,
              ),
            ),
            if (isExpense)
              Icon(
                transaction.isCompleted ? Icons.check_circle : Icons.pending_actions,
                size: 14,
                color: transaction.isCompleted ? Colors.green : Colors.orange,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
