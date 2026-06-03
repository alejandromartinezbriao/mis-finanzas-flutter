import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/icon_utils.dart';
import '../../utils/color_utils.dart';

class CategoriesListTab extends StatelessWidget {
  final FirebaseService service;
  final Function(Map<String, dynamic>?) onEdit;

  const CategoriesListTab({
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
              const Text('CATEGORÍAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              TextButton.icon(
                onPressed: () async {
                  await service.syncCategoriesFromCloud();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categorías sincronizadas')));
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
            stream: service.getCategories(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final categories = snapshot.data!;
              
              if (categories.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Crea tus propias categorías para clasificar tus gastos e ingresos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final Color color = ColorUtils.parse(cat['color']);
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        child: cat['icon'] != null && cat['icon'].endsWith('.png')
                            ? Image.asset('assets/logos/${cat['icon']}', width: 20, height: 20)
                            : Icon(IconUtils.getIconData(cat['icon']), color: color),
                      ),
                      title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Text(cat['type'] == 'EXPENSE' ? 'Gasto' : 'Ingreso'),
                          if (cat['type'] == 'EXPENSE' && (cat['budgetAmount'] ?? 0.0) > 0) ...[
                            const SizedBox(width: 8),
                            const Text('•'),
                            const SizedBox(width: 8),
                            Icon(Icons.speed, size: 12, color: Colors.teal.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '${cat['budgetCurrency'] ?? 'UYU'} ${cat['budgetAmount']}',
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          if (await DialogUtils.confirmDeletion(context, cat['name'])) {
                            service.deleteCategory(cat['id']);
                          }
                        },
                      ),
                      onTap: () => onEdit(cat),
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
