import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/dialog_utils.dart';
import '../brand_icon.dart';

class AccountsListTab extends StatelessWidget {
  final FirebaseService service;
  final Function(Map<String, dynamic>?) onEdit;

  const AccountsListTab({
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
              const Text('MIS CUENTAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              TextButton.icon(
                onPressed: () async {
                  await service.syncBalancesFromCloud();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuentas sincronizadas')));
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
            stream: service.getBalances(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final accounts = snapshot.data!;
              
              if (accounts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Configura tus cuentas para arqueo (ej: Efectivo, Banco Santander).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: accounts.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final List<Map<String, dynamic>> items = List.from(accounts);
                  final Map<String, dynamic> item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  service.updateBalancesOrder(items);
                },
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  return Card(
                    key: ValueKey(acc['id']),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: BrandIcon(name: acc['accountName'], manualLogo: acc['brandLogo'], size: 32),
                      title: Text(acc['accountName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Moneda: ${acc['currency']}', style: const TextStyle(fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              if (await DialogUtils.confirmDeletion(context, acc['accountName'])) {
                                service.deleteBalanceAccount(acc['id']);
                              }
                            },
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.swap_vert, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => onEdit(acc),
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
