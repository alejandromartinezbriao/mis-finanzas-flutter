import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/icon_utils.dart';

class GoalsListTab extends StatelessWidget {
  final FirebaseService service;
  final Function(Map<String, dynamic>?) onEdit;

  const GoalsListTab({
    super.key,
    required this.service,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getGoals(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final goals = snapshot.data!;
        
        if (goals.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Define tus metas financieras (ej: Ahorro para viaje, Cambio de auto).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
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
                  child: Icon(IconUtils.getIconData(g['icon'] ?? 'flag'), color: Theme.of(context).colorScheme.primary),
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
                  onPressed: () async {
                    if (await DialogUtils.confirmDeletion(context, g['title'])) {
                      service.deleteGoal(g['id']);
                    }
                  },
                ),
                onTap: () => onEdit(g),
              ),
            );
          },
        );
      },
    );
  }
}
