import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebtCoverageCard extends StatelessWidget {
  final double realUYU;
  final double debtUYU;
  final double realUSD;
  final double debtUSD;
  final bool isMobile;
  final bool isClosureMode; // Nueva bandera
  final NumberFormat uyuFormat;
  final NumberFormat usdFormat;

  const DebtCoverageCard({
    super.key,
    required this.realUYU,
    required this.debtUYU,
    required this.realUSD,
    required this.debtUSD,
    required this.uyuFormat,
    required this.usdFormat,
    this.isMobile = false,
    this.isClosureMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 4 : 0),
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isClosureMode ? Icons.assignment_turned_in_outlined : Icons.compare_arrows, 
                  color: Colors.amber, 
                  size: 14
                ),
                const SizedBox(width: 8),
                Text(
                  isClosureMode ? 'CIERRE DE MES' : 'COBERTURA DE DEUDAS',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 16),
            _comparisonRow(context, 'Pesos (UYU)', realUYU, debtUYU, uyuFormat, isMobile: isMobile, isClosure: isClosureMode),
            if (debtUSD > 0 || realUSD > 0) ...[
              Divider(
                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                height: isMobile ? 12 : 24,
              ),
              _comparisonRow(context, 'Dólares (USD)', realUSD, debtUSD, usdFormat, isMobile: isMobile, isClosure: isClosureMode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _comparisonRow(
    BuildContext context,
    String label,
    double real,
    double debt,
    NumberFormat format, {
    bool isMobile = false,
    bool isClosure = false,
  }) {
    double maxVal = real > debt ? real : debt;
    if (maxVal == 0) maxVal = 1;

    double realProgress = real / maxVal;
    double debtProgress = debt / maxVal;

    bool isCovered = real >= debt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isCovered ? Colors.green.withValues(alpha: 0.2) : Colors.deepOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isClosure 
                  ? (isCovered ? 'SUPERÁVIT: ${format.format(real - debt)}' : 'DÉFICIT: ${format.format(debt - real)}')
                  : (isCovered ? 'CUBIERTO' : 'FALTANTE: ${format.format(debt - real)}'),
                style: TextStyle(
                  color: isCovered ? Colors.greenAccent : Colors.deepOrangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 4 : 12),
        // Barra 1: Disponible (Actual) o Ingresos (Cierre)
        Row(
          children: [
            SizedBox(
              width: isMobile ? 65 : 80,
              child: Text(
                isClosure ? 'Ingresos' : 'Disponible',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  fontSize: isMobile ? 10 : 9,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: realProgress,
                  backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                  color: Colors.greenAccent,
                  minHeight: isMobile ? 2 : 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 75,
              child: Text(
                format.format(real),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: isMobile ? 11 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Barra 2: Deuda (Actual) o Egresos (Cierre)
        Row(
          children: [
            SizedBox(
              width: isMobile ? 65 : 80,
              child: Text(
                isClosure ? 'Egresos' : 'Deuda',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  fontSize: isMobile ? 10 : 9,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: debtProgress,
                  backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                  color: Colors.deepOrangeAccent,
                  minHeight: isMobile ? 2 : 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 75,
              child: Text(
                format.format(debt),
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.deepOrangeAccent,
                  fontSize: isMobile ? 11 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
