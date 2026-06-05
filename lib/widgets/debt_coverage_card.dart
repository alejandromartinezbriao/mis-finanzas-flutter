import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebtCoverageCard extends StatelessWidget {
  final double realUYU;
  final double debtUYU;
  final double realUSD;
  final double debtUSD;
  final bool isMobile;
  final bool isClosureMode;
  final bool isProjectionMode;
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
    this.isProjectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    String headerText = 'COBERTURA DE DEUDAS';
    IconData headerIcon = Icons.compare_arrows;
    if (isClosureMode) {
      headerText = 'CIERRE DE MES';
      headerIcon = Icons.assignment_turned_in_outlined;
    } else if (isProjectionMode) {
      headerText = 'PROYECCIÓN DEL MES';
      headerIcon = Icons.auto_graph;
    }

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
                  headerIcon, 
                  color: Colors.amber, 
                  size: 14
                ),
                const SizedBox(width: 8),
                Text(
                  headerText,
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
            _comparisonRow(context, 'Pesos (UYU)', realUYU, debtUYU, uyuFormat, isMobile: isMobile, isClosure: isClosureMode, isProjection: isProjectionMode),
            if (debtUSD > 0 || realUSD > 0) ...[
              Divider(
                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
                height: isMobile ? 12 : 24,
              ),
              _comparisonRow(context, 'Dólares (USD)', realUSD, debtUSD, usdFormat, isMobile: isMobile, isClosure: isClosureMode, isProjection: isProjectionMode),
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
    bool isProjection = false,
  }) {
    double maxVal = real > debt ? real : debt;
    if (maxVal == 0) maxVal = 1;

    double realProgress = real / maxVal;
    double debtProgress = debt / maxVal;

    bool isCovered = real >= debt;

    String statusText = '';
    if (isClosure) {
      statusText = isCovered ? 'SUPERÁVIT: ${format.format(real - debt)}' : 'DÉFICIT: ${format.format(debt - real)}';
    } else if (isProjection) {
      statusText = isCovered ? 'SOBRANTE: ${format.format(real - debt)}' : 'A CUBRIR: ${format.format(debt - real)}';
    } else {
      statusText = isCovered ? 'CUBIERTO' : 'FALTANTE: ${format.format(debt - real)}';
    }

    String realLabel = 'Disponible';
    String debtLabel = 'Deuda';
    if (isClosure || isProjection) {
      realLabel = 'Ingresos';
      debtLabel = 'Gastos';
    }

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
                color: isCovered ? Colors.green.withOpacity(0.2) : Colors.deepOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
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
        // Barra 1
        Row(
          children: [
            SizedBox(
              width: isMobile ? 65 : 80,
              child: Text(
                realLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  fontSize: isMobile ? 10 : 9,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: realProgress,
                  backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
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
        // Barra 2
        Row(
          children: [
            SizedBox(
              width: isMobile ? 65 : 80,
              child: Text(
                debtLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  fontSize: isMobile ? 10 : 9,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: debtProgress,
                  backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.1),
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
