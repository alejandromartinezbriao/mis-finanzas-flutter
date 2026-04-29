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
    return StreamBuilder<List<Map<String, dynamic>>>(
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

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final acc = accounts[index];
            return Card(
              child: ListTile(
                leading: BrandIcon(name: acc['accountName'], manualLogo: acc['brandLogo'], size: 32),
                title: Text(acc['accountName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('Moneda: ${acc['currency']}', style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    if (await DialogUtils.confirmDeletion(context, acc['accountName'])) {
                      service.deleteBalanceAccount(acc['id']);
                    }
                  },
                ),
                onTap: () => onEdit(acc),
              ),
            );
          },
        );
      },
    );
  }
}
