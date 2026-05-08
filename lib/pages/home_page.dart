import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';
import '../widgets/debt_coverage_card.dart';
import '../widgets/summary_balance_card.dart';
import '../widgets/account_balance_display.dart';
import '../widgets/transaction_item_tile.dart';
import '../widgets/month_selector.dart';
import '../widgets/main_app_bar.dart';
import '../dialogs/transaction_dialogs.dart';
import '../dialogs/transfer_dialog.dart';
import '../utils/currency_formatter.dart';

class HomePage extends StatefulWidget {
  final String? initialAction;
  const HomePage({super.key, this.initialAction});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _service = FirebaseService();
  DateTime _viewingDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Asegurar que el perfil del usuario existe (y es Premium por defecto en esta fase)
    _service.createUserProfileIfNotExist();

    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialAction == 'action_new_expense') {
          showDialog(
            context: context,
            builder: (context) => SimpleTransactionDialog(service: _service, initialDate: _viewingDate),
          );
        } else if (widget.initialAction == 'action_new_card') {
          showDialog(
            context: context,
            builder: (context) => CreditCardTransactionDialog(service: _service, initialDate: _viewingDate),
          );
        }
      });
    }
  }

  // Formateadores sin separadores de miles y con punto decimal
  final NumberFormat _uyuFormat = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
  final NumberFormat _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MainAppBar(
        service: _service,
        viewingDate: _viewingDate,
        uyuFormat: _uyuFormat,
        usdFormat: _usdFormat,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 900;
          
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MonthSelector(
                          selectedDate: _viewingDate,
                          onDateChanged: (newDate) => setState(() => _viewingDate = newDate),
                        ),
                        const SizedBox(height: 20),
                        StreamBuilder<List<TransactionModel>>(
                          stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
                          builder: (context, txSnapshot) {
                            final txs = txSnapshot.data ?? [];
                            double inUYU = txs.where((t) => t.type == 'INCOME' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
                            double outUYU = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
                            double inUSD = txs.where((t) => t.type == 'INCOME' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
                            double outUSD = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
                            
                            double debtUYU = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU' && !t.isCompleted && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);
                            double debtUSD = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'USD' && !t.isCompleted && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);

                            return StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _service.getBalances(),
                              builder: (context, balSnapshot) {
                                return StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: _service.getGoals(),
                                  builder: (context, goalSnapshot) {
                                    final balances = balSnapshot.data ?? [];
                                    final goals = goalSnapshot.data ?? [];
                                    
                                    double totalUYU = balances.where((b) => b['currency'] == 'UYU').fold(0, (sum, b) => sum + (b['amount'] ?? 0));
                                    double totalUSD = balances.where((b) => b['currency'] == 'USD').fold(0, (sum, b) => sum + (b['amount'] ?? 0));
                                    
                                    double reservedUYU = goals
                                        .where((g) => g['currency'] == 'UYU' && g['linkedAccountId'] != null)
                                        .fold(0, (sum, g) => sum + (g['currentAmount'] ?? 0));
                                    double reservedUSD = goals
                                        .where((g) => g['currency'] == 'USD' && g['linkedAccountId'] != null)
                                        .fold(0, (sum, g) => sum + (g['currentAmount'] ?? 0));

                                    double freeUYU = totalUYU - reservedUYU;
                                    double freeUSD = totalUSD - reservedUSD;

                                    final now = DateTime.now();
                                    final viewingMonth = DateTime(_viewingDate.year, _viewingDate.month);
                                    final currentMonth = DateTime(now.year, now.month);
                                    
                                    final bool isPast = viewingMonth.isBefore(currentMonth);
                                    final bool isFuture = viewingMonth.isAfter(currentMonth);

                                    return Column(
                                      children: [
                                        SummaryBalanceCard(
                                          inUYU: inUYU,
                                          outUYU: outUYU,
                                          inUSD: inUSD,
                                          outUSD: outUSD,
                                          uyuFormat: _uyuFormat,
                                          usdFormat: _usdFormat,
                                          isVertical: true,
                                        ),
                                        if (!isFuture) ...[
                                          const SizedBox(height: 20),
                                          DebtCoverageCard(
                                            realUYU: isPast ? inUYU : freeUYU,
                                            debtUYU: isPast ? outUYU : debtUYU,
                                            realUSD: isPast ? inUSD : freeUSD,
                                            debtUSD: isPast ? outUSD : debtUSD,
                                            uyuFormat: _uyuFormat,
                                            usdFormat: _usdFormat,
                                            isClosureMode: isPast,
                                          ),
                                        ],
                                      ],
                                    );
                                  }
                                );
                              }
                            );
                          }
                        ),
                        const SizedBox(height: 20),
                        AccountBalanceGrid(
                          balancesStream: _service.getBalances(),
                          goalsStream: _service.getGoals(),
                          uyuFormat: _uyuFormat,
                          usdFormat: _usdFormat,
                          onAccountTap: _showUpdateBalanceDialog,
                          onManageTap: () => Navigator.pushNamed(context, '/setup'),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      _buildQuickAddButton(),
                      Expanded(child: _buildTransactionList()),
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              MonthSelector(
                selectedDate: _viewingDate,
                onDateChanged: (newDate) => setState(() => _viewingDate = newDate),
              ),
              Expanded(child: _buildTransactionList()),
              SafeArea(child: _buildQuickAddButton()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickAddButton() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: FilledButton.icon(
          onPressed: _showQuickAddDialog,
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text('REGISTRAR MOVIMIENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary, 
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final transactions = snapshot.data!;
        
        if (transactions.isEmpty) {
          return _buildEmptyState();
        }

        double inUYU = transactions.where((t) => t.type == 'INCOME' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
        double outUYU = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
        double inUSD = transactions.where((t) => t.type == 'INCOME' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
        double outUSD = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);

        double debtUYU = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU' && !t.isCompleted && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);
        double debtUSD = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'USD' && !t.isCompleted && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);

        final now = DateTime.now();
        final viewingMonth = DateTime(_viewingDate.year, _viewingDate.month);
        final currentMonth = DateTime(now.year, now.month);
        
        final bool isPast = viewingMonth.isBefore(currentMonth);
        final bool isFuture = viewingMonth.isAfter(currentMonth);

        final incomes = transactions.where((t) => t.type == 'INCOME').toList()
          ..sort((a, b) => a.orderIndex != b.orderIndex 
              ? a.orderIndex.compareTo(b.orderIndex) 
              : a.title.compareTo(b.title));
        
        final expenses = transactions.where((t) => t.type == 'EXPENSE').toList()
          ..sort((a, b) => a.orderIndex != b.orderIndex 
              ? a.orderIndex.compareTo(b.orderIndex) 
              : a.title.compareTo(b.title));

        final sortedItems = [
          if (incomes.isNotEmpty) 'INGRESOS',
          ...incomes,
          if (expenses.isNotEmpty) 'GASTOS',
          ...expenses,
        ];

        return Column(
          children: [
            if (MediaQuery.of(context).size.width <= 900) ...[
              SummaryBalanceCard(
                inUYU: inUYU,
                outUYU: outUYU,
                inUSD: inUSD,
                outUSD: outUSD,
                uyuFormat: _uyuFormat,
                usdFormat: _usdFormat,
                isCompact: true,
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getBalances(),
                builder: (context, balSnap) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _service.getGoals(),
                    builder: (context, goalSnap) {
                      final balances = balSnap.data ?? [];
                      final goals = goalSnap.data ?? [];
                      
                      double totalUYU = balances.where((b) => b['currency'] == 'UYU').fold(0, (sum, b) => sum + (b['amount'] ?? 0));
                      double totalUSD = balances.where((b) => b['currency'] == 'USD').fold(0, (sum, b) => sum + (b['amount'] ?? 0));
                      
                      double reservedUYU = goals
                          .where((g) => g['currency'] == 'UYU' && g['linkedAccountId'] != null)
                          .fold(0, (sum, g) => sum + (g['currentAmount'] ?? 0));
                      double reservedUSD = goals
                          .where((g) => g['currency'] == 'USD' && g['linkedAccountId'] != null)
                          .fold(0, (sum, g) => sum + (g['currentAmount'] ?? 0));

                      if (isFuture) return const SizedBox.shrink();

                      return DebtCoverageCard(
                        realUYU: isPast ? inUYU : totalUYU - reservedUYU,
                        debtUYU: isPast ? outUYU : debtUYU,
                        realUSD: isPast ? inUSD : totalUSD - reservedUSD,
                        debtUSD: isPast ? outUSD : debtUSD,
                        uyuFormat: _uyuFormat,
                        usdFormat: _usdFormat,
                        isMobile: true,
                        isClosureMode: isPast,
                      );
                    }
                  );
                }
              ),
              AccountBalanceRow(
                balancesStream: _service.getBalances(),
                goalsStream: _service.getGoals(),
                uyuFormat: _uyuFormat,
                usdFormat: _usdFormat,
                onAccountTap: _showUpdateBalanceDialog,
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedItems.length,
                itemBuilder: (context, index) {
                  final item = sortedItems[index];
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(item, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1)),
                    );
                  }
                  return TransactionItemTile(
                    transaction: item as TransactionModel,
                    uyuFormat: _uyuFormat,
                    usdFormat: _usdFormat,
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => EditTransactionDialog(transaction: item, service: _service),
                    ),
                    onDeleteConfirmed: () => _service.deleteTransaction(item.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No hay movimientos en este periodo.'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _service.generateMonthlyTransactions(_viewingDate.month, _viewingDate.year),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Cargar Plantillas de este Mes'),
          ),
        ],
      ),
    );
  }

  void _showUpdateBalanceDialog(Map<String, dynamic> b) {
    final controller = TextEditingController(
      text: CurrencyUtils.formatForInput((b['amount'] ?? 0.0).toDouble())
    );
    final format = b['currency'] == 'UYU' ? _uyuFormat : _usdFormat;

    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getGoals(),
        builder: (context, snapshot) {
          final goals = snapshot.data?.where((g) => g['linkedAccountId'] == b['id']).toList() ?? [];
          final double totalReserved = goals.fold(0.0, (sum, g) => sum + (g['currentAmount'] ?? 0.0));

          return AlertDialog(
            title: Text('Gestionar ${b['accountName']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Saldo Total en la Cuenta (${b['currency']})',
                    helperText: 'Usa punto (.) para decimales. No uses puntos de miles.',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                  ),
                ),
                if (goals.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DINERO DESTINADO A METAS:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...goals.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag, size: 14, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(g['title'], style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        Text(format.format(g['currentAmount'] ?? 0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Reservado:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(format.format(totalReserved), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Disponible Libre:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      Builder(builder: (context) {
                        final currentVal = double.tryParse(controller.text) ?? 0.0;
                        return Text(format.format(currentVal - totalReserved), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey));
                      }),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (context) => TransferDialog(sourceAccount: b, service: _service),
                  );
                },
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Mover Dinero'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  final val = double.tryParse(controller.text);
                  if (val != null) {
                    _service.updateBalance(b['id'], val);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Actualizar Saldo'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showQuickAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Qué quieres registrar?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.teal),
              title: const Text('Ingreso o Gasto Simple'),
              subtitle: const Text('Movimiento puntual en este mes'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => SimpleTransactionDialog(service: _service, initialDate: _viewingDate),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Compra con Tarjeta'),
              subtitle: const Text('Suma al total de la tarjeta y permite cuotas'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => CreditCardTransactionDialog(service: _service, initialDate: _viewingDate),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}
