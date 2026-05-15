import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'brand_icon.dart';
import '../utils/dialog_utils.dart';

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
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await DialogUtils.confirmDeletion(context, transaction.title);
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
                child: Icon(Icons.link, size: 12, color: Colors.blueGrey),
              ),
            if (transaction.dueDate != null)
              Text(
                'Vence: ${DateFormat('dd/MM').format(transaction.dueDate!)}',
                style: const TextStyle(fontSize: 11),
              ),
            if (transaction.includedInCard)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '(Ya sumado)',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
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
                color: isExpense ? Colors.deepOrange.shade800 : Colors.green,
              ),
            ),
            if (isExpense)
              Icon(
                transaction.isCompleted ? Icons.check_circle : Icons.pending_actions,
                size: 14,
                color: transaction.isCompleted ? Colors.green : Colors.deepOrange,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
