import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String label = DateFormat('MMMM yyyy', 'es_ES').format(selectedDate).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }

  void _showMonthPicker(BuildContext context) async {
    int tempYear = selectedDate.year;
    final List<String> months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    final DateTime? picked = await showDialog<DateTime>(
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
                final bool isSelected = selectedDate.month == index + 1 && selectedDate.year == tempYear;
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

    if (picked != null) {
      onDateChanged(picked);
    }
  }
}
