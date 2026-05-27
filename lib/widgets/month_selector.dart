import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/dialog_utils.dart'; // Importante: Faltaba este import

class MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onRefresh;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final String label = DateFormat('MMMM yyyy', 'es_ES').format(selectedDate).toUpperCase();
    
    // Detectamos si es un dispositivo táctil (Móvil/Tablet) basándonos en el ancho o la plataforma
    final bool isDesktopWeb = kIsWeb && MediaQuery.of(context).size.width > 900;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left, size: 24),
                onPressed: () => onDateChanged(DateTime(selectedDate.year, selectedDate.month - 1)),
              ),
              InkWell(
                onTap: () => _showMonthPicker(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.calendar_month, size: 16, color: Theme.of(context).colorScheme.secondary),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right, size: 24),
                onPressed: () => onDateChanged(DateTime(selectedDate.year, selectedDate.month + 1)),
              ),
            ],
          ),
          // Solo mostramos el botón de refresco si es Web y pantalla ancha (Escritorio)
          if (onRefresh != null && isDesktopWeb)
            IconButton(
              tooltip: 'Actualizar datos del mes',
              icon: const Icon(Icons.refresh, size: 22),
              onPressed: onRefresh,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context) async {
    final DateTime? picked = await DialogUtils.showMonthYearPicker(context, selectedDate);
    if (picked != null) {
      onDateChanged(picked);
    }
  }
}
