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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Arrastra desde el icono de las flechas para reordenar.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
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
                      ? 'No hay gastos fijos o tarjetas configuradas.' 
                      : 'No hay ingresos fijos configurados.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ReorderableListView.builder(
                buildDefaultDragHandles: false, // Desactivamos el "long press" por defecto
                itemCount: templates.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final List<Map<String, dynamic>> items = List.from(templates);
                  final Map<String, dynamic> item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  service.updateTemplatesOrder(items);
                },
                itemBuilder: (context, index) {
                  final t = templates[index];
                  return Card(
                    key: ValueKey(t['id']),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: BrandIcon(name: t['title'], manualLogo: t['brandLogo'], size: 32),
                      title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(
                        '${t['currency']} ${t['defaultAmount'] != null ? "(${(t['defaultAmount'] as num).toStringAsFixed(0)}) " : ""}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red), 
                            onPressed: () async {
                              if (await DialogUtils.confirmDeletion(context, t['title'])) {
                                service.deleteTemplate(t['id']);
                              }
                            }
                          ),
                          // Escuchador específico para activar el arrastre inmediatamente en PC y Móvil
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.swap_vert, color: Colors.grey),
                            ),
                          ),
                        ],
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
