import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'brand_icon.dart';

class AccountBalanceGrid extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> balancesStream;
  final Stream<List<Map<String, dynamic>>> goalsStream;
  final NumberFormat uyuFormat;
  final NumberFormat usdFormat;
  final Function(Map<String, dynamic>) onAccountTap;
  final VoidCallback onManageTap;

  const AccountBalanceGrid({
    super.key,
    required this.balancesStream,
    required this.goalsStream,
    required this.uyuFormat,
    required this.usdFormat,
    required this.onAccountTap,
    required this.onManageTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: balancesStream,
      builder: (context, balSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: goalsStream,
          builder: (context, goalSnapshot) {
            if (!balSnapshot.hasData || balSnapshot.data!.isEmpty) return const SizedBox.shrink();
            final balances = balSnapshot.data!;
            final goals = goalSnapshot.data ?? [];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DISPONIBLE EN CUENTAS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                          letterSpacing: 1,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onManageTap,
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Gestionar', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: balances.length,
                    itemBuilder: (context, index) {
                      final b = balances[index];
                      final accountId = b['id'];
                      
                      // Calcular cuánto de esta cuenta está reservado para metas
                      final double reserved = goals
                          .where((g) => g['linkedAccountId'] == accountId)
                          .fold(0.0, (sum, g) => sum + (g['currentAmount'] ?? 0.0));
                      
                      final double realAmount = (b['amount'] ?? 0.0).toDouble();
                      final double availableAmount = realAmount - reserved;
                      
                      final format = b['currency'] == 'UYU' ? uyuFormat : usdFormat;
                      
                      return GestureDetector(
                        onTap: () => onAccountTap(b),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              BrandIcon(name: b['accountName'], manualLogo: b['brandLogo'], size: 28),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            b['accountName'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (b['includeInCoverage'] == false)
                                          const Icon(Icons.visibility_off_outlined, size: 10, color: Colors.orange),
                                      ],
                                    ),
                                    Text(
                                      format.format(availableAmount),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: availableAmount < 0 ? Colors.red : Colors.teal,
                                      ),
                                    ),
                                    if (reserved > 0)
                                      Text(
                                        'Reservado: ${format.format(reserved)}',
                                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AccountBalanceRow extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> balancesStream;
  final Stream<List<Map<String, dynamic>>> goalsStream;
  final NumberFormat uyuFormat;
  final NumberFormat usdFormat;
  final Function(Map<String, dynamic>) onAccountTap;

  const AccountBalanceRow({
    super.key,
    required this.balancesStream,
    required this.goalsStream,
    required this.uyuFormat,
    required this.usdFormat,
    required this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: balancesStream,
      builder: (context, balSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: goalsStream,
          builder: (context, goalSnapshot) {
            if (!balSnapshot.hasData || balSnapshot.data!.isEmpty) return const SizedBox.shrink();
            final balances = balSnapshot.data!;
            final goals = goalSnapshot.data ?? [];

            // Calcular sumas totales por moneda restando lo reservado
            double totalUYUAvailable = 0;
            double totalUSDAvailable = 0;

            for (var b in balances) {
              final double reserved = goals
                  .where((g) => g['linkedAccountId'] == b['id'])
                  .fold(0.0, (sum, g) => sum + (g['currentAmount'] ?? 0.0));
              final double available = (b['amount'] ?? 0.0).toDouble() - reserved;
              
              if (b['currency'] == 'UYU') {
                totalUYUAvailable += available;
              } else {
                totalUSDAvailable += available;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 4, bottom: 4),
                  child: Text(
                    'DISPONIBLE REAL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
                SizedBox(
                  height: 55,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      // LISTA DE CUENTAS INDIVIDUALES
                      ...balances.map((b) {
                        final double reserved = goals
                            .where((g) => g['linkedAccountId'] == b['id'])
                            .fold(0.0, (sum, g) => sum + (g['currentAmount'] ?? 0.0));
                        final double available = (b['amount'] ?? 0.0).toDouble() - reserved;
                        
                        final format = b['currency'] == 'UYU' ? uyuFormat : usdFormat;
                        return GestureDetector(
                          onTap: () => onAccountTap(b),
                          child: Container(
                            width: 130,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                BrandIcon(name: b['accountName'], manualLogo: b['brandLogo'], size: 24),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              b['accountName'],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          if (b['includeInCoverage'] == false)
                                            const Icon(Icons.visibility_off_outlined, size: 10, color: Colors.orange),
                                        ],
                                      ),
                                      Text(
                                        format.format(available),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: available < 0 ? Colors.red : Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
