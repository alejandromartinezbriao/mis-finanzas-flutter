import 'package:flutter/material.dart';

class DialogUtils {
  static Future<bool> confirmDeletion(BuildContext context, String itemName) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: Text('¿Estás seguro de que quieres borrar "$itemName"?\n\nEsta acción no se puede deshacer y los datos se perderán permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<bool> confirmAction(BuildContext context, {required String title, required String message, String confirmText = 'Confirmar', Color? confirmColor}) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: confirmColor != null ? FilledButton.styleFrom(backgroundColor: confirmColor) : null,
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<DateTime?> showMonthYearPicker(BuildContext context, DateTime initialDate) async {
    int tempYear = initialDate.year;
    final List<String> months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                onPressed: () => setS(() => tempYear--),
              ),
              Text('$tempYear', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => setS(() => tempYear++),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          content: SizedBox(
            width: 280,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (ctx, index) {
                final bool isSelected = initialDate.month == index + 1 && initialDate.year == tempYear;
                return InkWell(
                  onTap: () => Navigator.pop(ctx, DateTime(tempYear, index + 1)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        months[index],
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(ctx).colorScheme.onPrimary : Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
