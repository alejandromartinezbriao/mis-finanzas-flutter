import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/icon_utils.dart';

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
    return StreamBuilder<List<Map<String, dynamic>>>(
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
            final Color color = Color(cat['color'] ?? 0xFF9E9E9E);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: cat['icon'] != null && cat['icon'].endsWith('.png')
                      ? Image.asset('assets/logos/${cat['icon']}', width: 20, height: 20)
                      : Icon(IconUtils.getIconData(cat['icon']), color: color),
                ),
                title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(cat['type'] == 'EXPENSE' ? 'Gasto' : 'Ingreso'),
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
    );
  }
}
