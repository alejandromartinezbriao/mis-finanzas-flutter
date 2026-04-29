import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/dialog_utils.dart';
import '../brand_icon.dart';

class TemplateListTab extends StatelessWidget {
  final String type;
  final FirebaseService service;
  final Function(Map<String, dynamic>?, String) onEdit;

  const TemplateListTab({
    super.key,
    required this.type,
    required this.service,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: service.getTemplates(type: type),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final templates = snapshot.data!;
              
              if (templates.isEmpty) {
                return Center(
                  child: Text(
                    type == 'EXPENSE' 
                      ? 'No hay gastos fijos configurados.' 
                      : 'No hay ingresos fijos configurados.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: templates.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final t = templates[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: BrandIcon(name: t['title'], manualLogo: t['brandLogo'], size: 32),
                      title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(
                        '${t['currency']} ${t['defaultAmount'] != null ? "(${(t['defaultAmount'] as num).toStringAsFixed(0)}) " : ""}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red), 
                        onPressed: () async {
                          if (await DialogUtils.confirmDeletion(context, t['title'])) {
                            service.deleteTemplate(t['id']);
                          }
                        }
                      ),
                      onTap: () => onEdit(t, type),
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
