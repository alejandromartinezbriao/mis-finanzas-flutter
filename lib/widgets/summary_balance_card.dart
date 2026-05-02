import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryBalanceCard extends StatelessWidget {
  final double inUYU;
  final double outUYU;
  final double inUSD;
  final double outUSD;
  final bool isVertical;
  final bool isCompact;
  final NumberFormat uyuFormat;
  final NumberFormat usdFormat;

  const SummaryBalanceCard({
    super.key,
    required this.inUYU,
    required this.outUYU,
    required this.inUSD,
    required this.outUSD,
    required this.uyuFormat,
    required this.usdFormat,
    this.isVertical = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 4 : 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 20),
        child: isVertical
            ? Column(
                children: [
                  _balanceSmallRow(context, 'Resumen Pesos (UYU)', inUYU, outUYU, uyuFormat),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  _balanceSmallRow(context, 'Resumen Dólares (USD)', inUSD, outUSD, usdFormat),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _balanceSmallRow(context, 'UYU', inUYU, outUYU, uyuFormat, isCompact: isCompact),
                  ),
                  const VerticalDivider(width: 32),
                  Expanded(
                    child: _balanceSmallRow(context, 'USD', inUSD, outUSD, usdFormat, isCompact: isCompact),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _balanceSmallRow(
    BuildContext context,
    String label,
    double income,
    double expense,
    NumberFormat format, {
    bool isCompact = false,
  }) {
    double balance = income - expense;
    double progress = (income > 0) ? (expense / income).clamp(0.0, 1.0) : (expense > 0 ? 1.0 : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: isCompact ? 4 : 12),
        _miniAmount(context, 'Ingresos', income, Colors.green, format, isCompact: isCompact),
        SizedBox(height: isCompact ? 2 : 4),
        _miniAmount(context, 'Egresos', expense, Colors.deepOrange.shade800, format, isCompact: isCompact),
        if (!isCompact) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: progress > 0.9 ? Colors.red : (progress > 0.5 ? Colors.deepOrange : Colors.green),
              minHeight: 8,
            ),
          ),
        ],
        SizedBox(height: isCompact ? 8 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Disponible',
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              format.format(balance),
              style: TextStyle(
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniAmount(
    BuildContext context,
    String label,
    double amount,
    Color color,
    NumberFormat format, {
    bool isCompact = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 12 : 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          format.format(amount),
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
