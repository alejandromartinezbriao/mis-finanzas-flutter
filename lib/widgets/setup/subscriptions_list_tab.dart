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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SUSCRIPCIONES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              TextButton.icon(
                onPressed: () async {
                  await service.syncSubscriptionsFromCloud();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suscripciones sincronizadas')));
                  }
                },
                icon: const Icon(Icons.cloud_download, size: 16),
                label: const Text('Sincronizar Nube', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
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
                        backgroundColor: Colors.purple.withOpacity(0.1),
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
          ),
        ),
      ],
    );
  }
}
