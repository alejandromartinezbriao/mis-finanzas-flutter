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
}
