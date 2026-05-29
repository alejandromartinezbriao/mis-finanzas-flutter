import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para cerrar la app
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NECESARIO PARA GetOptions y Source
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';
import '../widgets/debt_coverage_card.dart';
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
  
  // Flag para el modo de acceso rápido enfocado
  bool _isFastActionActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) {
      _isFastActionActive = true;
    }
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // 1. Lanzamos la acción rápida inmediatamente si existe, sin esperar al perfil
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleFastAction(widget.initialAction!));
    }

    try {
      await _service.createUserProfileIfNotExist();
      
      final uid = _service.auth.currentUser?.uid;
      bool needsWelcomev35 = false;
      if (uid != null) {
        // CORRECCIÓN CRÍTICA: Forzamos lectura de cache si no hay red inmediata
        final doc = await _service.db.collection('users').doc(uid).get(GetOptions(source: Source.serverAndCache));
        if (doc.exists && doc.data()?['migratedToLocalV35'] != true) {
          needsWelcomev35 = true;
        }
      }

      await _service.checkAndPerformMigrations();
      
      final profile = await _service.getUserProfile().first;
      final String userName = profile?['displayName'] ?? 'Tester VIP';
      
      if (needsWelcomev35 && mounted) {
        _showV35WelcomeDialog(userName);
      }

      if (profile != null && (profile['displayName'] == null || profile['displayName'].toString().isEmpty)) {
        if (mounted) _showNameRequestDialog();
      }
    } catch (e) {
      print("Error silencioso en inicialización offline: $e");
    }
  }

  void _showV35WelcomeDialog(String userName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Hola, $userName!',
                style: const TextStyle(fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hemos blindado tu aplicación.\n\nA partir de ahora, todos tus datos están disponibles en modo local: puedes consultar y registrar tus finanzas sin conexión a internet.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Text(
              'Al ser un usuario Premium, tus datos siguen respaldados en tiempo real en la nube, permitiéndote acceso total desde tu PC y otros dispositivos.',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('¡Excelente!'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFastAction(String action, {bool fromQuickAction = true}) async {
    setState(() { _isFastActionActive = true; });

    Widget dialog;
    if (action == 'action_new_movement_v5') {
      dialog = SimpleTransactionDialog(service: _service, initialDate: _viewingDate);
    } else if (action == 'action_new_card_v5') {
      dialog = CreditCardTransactionDialog(service: _service, initialDate: _viewingDate);
    } else { 
      setState(() { _isFastActionActive = false; });
      return; 
    }

    final bool? success = await showDialog<bool>(context: context, builder: (context) => dialog);
    
    // REPARACIÓN CRÍTICA: Si guardó con éxito, mostramos aviso antes de salir
    if (mounted && success == true) {
      await showDialog(
        context: context,
        barrierDismissible: false, // Forzar clic en botón
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('¡Registro Exitoso!'),
            ],
          ),
          content: const Text('El movimiento ha quedado guardado correctamente en tu historial.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }

    if (mounted) {
      if (fromQuickAction) {
        // PRIMERO mandamos la App al fondo/cerramos para que el usuario deje de verla
        SystemNavigator.pop();
        
        // SEGUNDO (en segundo plano) reseteamos el modo para que al volver esté el Dashboard.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isFastActionActive = false;
            });
          }
        });
      } else {
        // Simplemente volvemos al dashboard
        setState(() {
          _isFastActionActive = false;
        });
      }
    }
  }

  void _showNameRequestDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.face, color: Colors.purple), SizedBox(width: 10), Text('¡Hola!', style: TextStyle(fontWeight: FontWeight.w900))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Para que Finanz-IA pueda darte consejos personalizados, ¿cómo te gustaría que te llame?'),
            const SizedBox(height: 20),
            TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Tu nombre o apodo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit)), textCapitalization: TextCapitalization.words),
          ],
        ),
        actions: [FilledButton(onPressed: () async { if (controller.text.trim().isNotEmpty) { await _service.updateUserName(controller.text.trim()); if (ctx.mounted) Navigator.pop(ctx); } }, child: const Text('Comenzar'))],
      ),
    );
  }

  final NumberFormat _uyuFormat = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2, customPattern: '¤#0.00');
  final NumberFormat _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 2, customPattern: '¤#0.00');

  @override
  Widget build(BuildContext context) {
    // SI ESTAMOS EN MODO ACCESO RÁPIDO, MOSTRAR INTERFAZ MINIMALISTA
    if (_isFastActionActive) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Theme.of(context).colorScheme.primary.withOpacity(0.1), Theme.of(context).colorScheme.surface],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: MainAppBar(service: _service, viewingDate: _viewingDate, uyuFormat: _uyuFormat, usdFormat: _usdFormat),
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
                        MonthSelector(selectedDate: _viewingDate, onDateChanged: (newDate) => setState(() => _viewingDate = newDate), onRefresh: _refreshMonthData),
                        const SizedBox(height: 20),
                        _buildCoverageCard(),
                        const SizedBox(height: 20),
                        AccountBalanceGrid(balancesStream: _service.getBalances(), goalsStream: _service.getGoals(), uyuFormat: _uyuFormat, usdFormat: _usdFormat, onAccountTap: _showUpdateBalanceDialog, onManageTap: () => Navigator.pushNamed(context, '/setup')),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: Column(children: [_buildQuickAddButton(), Expanded(child: _buildTransactionList())])),
              ],
            );
          }

          return Column(
            children: [
              MonthSelector(selectedDate: _viewingDate, onDateChanged: (newDate) => setState(() => _viewingDate = newDate), onRefresh: _refreshMonthData),
              Expanded(child: _buildTransactionList()),
              SafeArea(child: _buildQuickAddButton()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoverageCard() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
      builder: (context, txSnapshot) {
        final txs = txSnapshot.data ?? [];
        double inUYU = txs.where((t) => t.type == 'INCOME' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
        double outUYU = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU' && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);
        double inUSD = txs.where((t) => t.type == 'INCOME' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
        double outUSD = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'USD' && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);
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
                double totalUYU = balances.where((b) => b['currency'] == 'UYU' && (b['includeInCoverage'] ?? true)).fold(0.0, (sum, b) => sum + (b['amount'] ?? 0));
                double totalUSD = balances.where((b) => b['currency'] == 'USD' && (b['includeInCoverage'] ?? true)).fold(0.0, (sum, b) => sum + (b['amount'] ?? 0));
                double reservedUYU = goals.where((g) => g['currency'] == 'UYU' && g['linkedAccountId'] != null).fold(0, (sum, g) => sum + (g['currentAmount'] ?? 0));
                double reservedUSD = goals.where((g) => g['currency'] == 'USD' && g['linkedAccountId'] != null).fold(0, (sum, g) => sum + (g['currentAmount'] ?? 0));

                final now = DateTime.now();
                final viewingMonth = DateTime(_viewingDate.year, _viewingDate.month);
                final currentMonth = DateTime(now.year, now.month);
                final bool isPast = viewingMonth.isBefore(currentMonth);
                final bool isFuture = viewingMonth.isAfter(currentMonth);

                return DebtCoverageCard(
                  realUYU: isPast ? inUYU : (isFuture ? inUYU : totalUYU - reservedUYU),
                  debtUYU: isPast ? outUYU : (isFuture ? outUYU : debtUYU),
                  realUSD: isPast ? inUSD : (isFuture ? inUSD : totalUSD - reservedUSD),
                  debtUSD: isPast ? outUSD : (isFuture ? outUSD : debtUSD),
                  uyuFormat: _uyuFormat, usdFormat: _usdFormat,
                  isClosureMode: isPast, isProjectionMode: isFuture,
                  isMobile: MediaQuery.of(context).size.width <= 900,
                );
              }
            );
          }
        );
      }
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
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getCategories(),
      builder: (context, catSnapshot) {
        final categories = {for (var c in catSnapshot.data ?? []) c['name'] as String: c};

        return StreamBuilder<List<TransactionModel>>(
          stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final transactions = snapshot.data!;
            
            if (transactions.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshMonthData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.6, child: _buildEmptyState()),
                ),
              );
            }

            final incomes = transactions.where((t) => t.type == 'INCOME').toList()..sort((a, b) => a.orderIndex != b.orderIndex ? a.orderIndex.compareTo(b.orderIndex) : a.title.compareTo(b.title));
            final expenses = transactions.where((t) => t.type == 'EXPENSE').toList()..sort((a, b) => a.orderIndex != b.orderIndex ? a.orderIndex.compareTo(b.orderIndex) : a.title.compareTo(b.title));

            final sortedItems = [if (incomes.isNotEmpty) 'INGRESOS', ...incomes, if (expenses.isNotEmpty) 'GASTOS', ...expenses];

            return Column(
              children: [
                if (MediaQuery.of(context).size.width <= 900) ...[
                  _buildCoverageCard(),
                  AccountBalanceRow(balancesStream: _service.getBalances(), goalsStream: _service.getGoals(), uyuFormat: _uyuFormat, usdFormat: _usdFormat, onAccountTap: _showUpdateBalanceDialog),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshMonthData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: sortedItems.length,
                      itemBuilder: (context, index) {
                        final item = sortedItems[index];
                        if (item is String) {
                          return Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(item, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1)));
                        }
                        final tx = item as TransactionModel;
                        final catData = categories[tx.category];
                        return TransactionItemTile(
                          transaction: tx, 
                          uyuFormat: _uyuFormat, 
                          usdFormat: _usdFormat, 
                          categoryIcon: tx.brandLogo ?? catData?['icon'], 
                          categoryColor: tx.categoryColor != null ? Color(tx.categoryColor!) : (catData != null ? Color(catData['color']) : null), 
                          onTap: () => showDialog(context: context, builder: (context) => EditTransactionDialog(transaction: tx, service: _service)), 
                          onDeleteConfirmed: () => _service.deleteTransaction(tx.id)
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.swipe_vertical_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No hay movimientos en este periodo.'),
          const SizedBox(height: 8),
          const Text('Desliza hacia abajo para actualizar los datos del mes.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  void _showUpdateBalanceDialog(Map<String, dynamic> b) {
    final controller = TextEditingController(text: CurrencyUtils.formatForInput((b['amount'] ?? 0.0).toDouble()));
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
                TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [ThousandsSeparatorInputFormatter()], decoration: InputDecoration(labelText: 'Saldo Total en la Cuenta (${b['currency']})', helperText: 'Usa punto (.) para decimales. No uses puntos de miles.', prefixIcon: const Icon(Icons.account_balance_wallet))),
                if (goals.isNotEmpty) ...[
                  const SizedBox(height: 20), const Divider(), const SizedBox(height: 10),
                  const Align(alignment: Alignment.centerLeft, child: Text('DINERO DESTINADO A METAS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5))),
                  const SizedBox(height: 10),
                  ...goals.map((g) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.flag, size: 14, color: Colors.teal), const SizedBox(width: 8), Text(g['title'], style: const TextStyle(fontSize: 13))]), Text(format.format(g['currentAmount'] ?? 0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]))),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Reservado:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), Text(format.format(totalReserved), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Disponible Libre:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)), Builder(builder: (context) { final currentVal = double.tryParse(controller.text) ?? 0.0; return Text(format.format(currentVal - totalReserved), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)); })]),
                ],
              ],
            ),
            actions: [
              TextButton.icon(onPressed: () { Navigator.pop(ctx); showDialog(context: context, builder: (context) => TransferDialog(sourceAccount: b, service: _service)); }, icon: const Icon(Icons.swap_horiz, size: 18), label: const Text('Mover Dinero')),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(onPressed: () { final val = double.tryParse(controller.text); if (val != null) { _service.updateBalance(b['id'], val); Navigator.pop(ctx); } }, child: const Text('Actualizar Saldo')),
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
                _handleFastAction('action_new_movement_v5', fromQuickAction: false);
              }
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue), 
              title: const Text('Compra con Tarjeta'), 
              subtitle: const Text('Suma al total de la tarjeta y permite cuotas'), 
              onTap: () { 
                Navigator.pop(context); 
                _handleFastAction('action_new_card_v5', fromQuickAction: false);
              }
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshMonthData() async {
    await _service.generateMonthlyTransactions(_viewingDate.month, _viewingDate.year);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos del mes actualizados')));
    }
  }
}
