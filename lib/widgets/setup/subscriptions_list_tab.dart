import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/dialog_utils.dart';

class SubscriptionsListTab extends StatelessWidget {
  final FirebaseService service;
  final Function(Map<String, dynamic>?) onEdit;

  const SubscriptionsListTab({
    super.key,
    required this.service,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final subs = snapshot.data!;

        if (subs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Gestiona tus suscripciones mensuales (Netflix, Spotify, etc.) vinculándolas a Crédito o Débito.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: subs.length,
          itemBuilder: (context, index) {
            final s = subs[index];
            final String linkType = s['linkType'] ?? 'ACCOUNT';
            
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  child: const Icon(Icons.subscriptions, color: Colors.purple),
                ),
                title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${s['currency']} ${s['amount']} - ${linkType == 'CARD' ? "Crédito" : "Débito"}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    if (await DialogUtils.confirmDeletion(context, s['name'])) {
                      service.deleteSubscription(s['id']);
                    }
                  },
                ),
                onTap: () => onEdit(s),
              ),
            );
          },
        );
      },
    );
  }
}
