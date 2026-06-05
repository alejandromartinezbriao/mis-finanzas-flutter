import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/firebase_service.dart';
import '../widgets/debt_coverage_card.dart';
import '../widgets/account_balance_display.dart';
import '../widgets/transaction_item_tile.dart';
import '../widgets/month_selector.dart';
import '../widgets/main_app_bar.dart';
import '../dialogs/transaction_dialogs.dart';
import '../utils/currency_formatter.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  final String? initialAction;
  const HomePage({super.key, this.initialAction});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _service = FirebaseService();
  DateTime _viewingDate = DateTime.now();
  bool _isFastActionActive = false;
  bool _isFamilyMode = false;

  final Map<String, Map<String, dynamic>> _systemCategories = {
    'tarjeta': {'color': 0xFF1976D2, 'icon': 'credit_card'},
    'fijo': {'color': 0xFF00796B, 'icon': 'push_pin'},
    'ingreso': {'color': 0xFF388E3C, 'icon': 'add_circle'},
    'servicios': {'color': 0xFFF57C00, 'icon': 'bolt'},
    'suscripción': {'color': 0xFF7B1FA2, 'icon': 'subscriptions'},
    'otros': {'color': 0xFF607D8B, 'icon': 'category'},
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) _isFastActionActive = true;
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    await _service.createUserProfileIfNotExist();
    await _service.checkAndPerformMigrations();
    _listenForInvitations();
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleFastAction(widget.initialAction!));
    }
  }

  void _listenForInvitations() {
    _service.getPendingInvitation().listen((invitation) {
      if (invitation != null && mounted) _showInvitationDialog(invitation);
    });
  }

  // --- COMPROBACIÓN DE INTERNET ---
  Future<bool> _hasInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _toggleMode(bool wantFamily) async {
    if (wantFamily) {
      final online = await _hasInternet();
      if (!online) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [Icon(Icons.cloud_off, color: Colors.orange), SizedBox(width: 10), Text('Modo Offline')]),
              content: const Text('La vista del Círculo Familiar requiere conexión a internet para sincronizar los datos de otros miembros en tiempo real.'),
              actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
            ),
          );
        }
        return;
      }
    }
    setState(() => _isFamilyMode = wantFamily);
  }

  void _showInvitationDialog(Map<String, dynamic> inv) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.family_restroom, color: Colors.teal), SizedBox(width: 10), Text('¡Invitación Familiar!', style: TextStyle(fontWeight: FontWeight.w900))]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [Text.rich(TextSpan(text: 'Hola, ', children: [TextSpan(text: inv['fromName'], style: const TextStyle(fontWeight: FontWeight.bold)), const TextSpan(text: ' te ha invitado a formar parte de su círculo familiar.')])), const SizedBox(height: 16), const Text('Podrás compartir gastos, cuentas y metas. Tus datos privados se mantienen seguros.', style: TextStyle(fontSize: 13, color: Colors.blueGrey))]),
        actions: [
          TextButton(onPressed: () async { await _service.rejectFamilyInvitation(inv['toEmail']); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Rechazar', style: TextStyle(color: Colors.red))),
          FilledButton(onPressed: () async { await _service.acceptFamilyInvitation(inv); if (ctx.mounted) Navigator.pop(ctx); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Bienvenido al Círculo Familiar! 👪'))); }, child: const Text('Aceptar y Unirse')),
        ],
      ),
    );
  }

  Future<void> _handleFastAction(String action) async {
    Widget dialog;
    if (action == 'action_new_movement_v5') {
      dialog = SimpleTransactionDialog(service: _service, initialDate: _viewingDate);
    } else if (action == 'action_new_card_v5') {
      dialog = CreditCardTransactionDialog(service: _service, initialDate: _viewingDate);
    } else return;

    final bool? success = await showDialog<bool>(context: context, builder: (context) => dialog);
    if (mounted && success == true) {
      await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('¡Registro Exitoso!'), content: const Text('El movimiento ha quedado guardado correctamente.'), actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))]));
    }
    if (mounted) {
      SystemNavigator.pop();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() { _isFastActionActive = false; });
      });
    }
  }

  final NumberFormat _uyuFormat = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2, customPattern: '¤#0.00');
  final NumberFormat _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 2, customPattern: '¤#0.00');

  @override
  Widget build(BuildContext context) {
    if (_isFastActionActive) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: _isFamilyMode ? Colors.teal.shade50.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
      appBar: MainAppBar(
        service: _service, viewingDate: _viewingDate, 
        uyuFormat: _uyuFormat, usdFormat: _usdFormat,
        isFamilyMode: _isFamilyMode,
        onModeChanged: _toggleMode, // USAR LA NUEVA FUNCIÓN CON FILTRO
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
                      children: [
                        MonthSelector(selectedDate: _viewingDate, onDateChanged: (newDate) => setState(() => _viewingDate = newDate), onRefresh: _refreshFullSync),
                        const SizedBox(height: 20),
                        _buildCoverageCard(),
                        const SizedBox(height: 20),
                        AccountBalanceGrid(
                          balancesStream: _getFilteredBalances(), 
                          goalsStream: _getFilteredGoals(), 
                          uyuFormat: _uyuFormat, usdFormat: _usdFormat, 
                          onAccountTap: _showUpdateBalanceDialog, 
                          onManageTap: () => Navigator.pushNamed(context, '/setup')
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildTransactionList()),
              ],
            );
          }

          return Column(
            children: [
              MonthSelector(selectedDate: _viewingDate, onDateChanged: (newDate) => setState(() => _viewingDate = newDate), onRefresh: _refreshFullSync),
              _buildCoverageCard(),
              AccountBalanceRow(balancesStream: _getFilteredBalances(), goalsStream: _getFilteredGoals(), uyuFormat: _uyuFormat, usdFormat: _usdFormat, onAccountTap: _showUpdateBalanceDialog),
              const Divider(height: 1),
              Expanded(child: _buildTransactionList()),
              SafeArea(child: _buildQuickAddButton()),
            ],
          );
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getFilteredBalances() {
    return _service.getBalances().map((list) {
      if (!_isFamilyMode) return list;
      return list.where((b) => b['familyId'] != null).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> _getFilteredGoals() {
    return _service.getGoals().map((list) {
      if (!_isFamilyMode) return list;
      return list.where((g) => g['familyId'] != null).toList();
    });
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
          label: const Text('REGISTRAR MOVIMIENTO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getCategories(),
      builder: (context, catSnapshot) {
        final userCategories = {for (var c in catSnapshot.data ?? []) c['name'].toString().trim().toLowerCase(): CategoryModel.fromMap(c, c['id'])};

        return StreamBuilder<List<TransactionModel>>(
          stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            List<TransactionModel> transactions = snapshot.data!;
            if (_isFamilyMode) {
              transactions = transactions.where((t) => t.familyId != null).toList();
            }

            if (transactions.isEmpty) {
              return RefreshIndicator(onRefresh: _refreshFullSync, child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: SizedBox(height: 300, child: Center(child: Text(_isFamilyMode ? 'No hay gastos compartidos este mes.' : 'No hay movimientos. Desliza para sincronizar.')))));
            }

            final incomes = transactions.where((t) => t.type == 'INCOME').toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
            final expenses = transactions.where((t) => t.type == 'EXPENSE').toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
            final sortedItems = [if (incomes.isNotEmpty) 'INGRESOS', ...incomes, if (expenses.isNotEmpty) 'GASTOS', ...expenses];

            return RefreshIndicator(
              onRefresh: _refreshFullSync,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedItems.length,
                itemBuilder: (context, index) {
                  final item = sortedItems[index];
                  if (item is String) return Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(item, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1)));
                  final tx = item as TransactionModel;
                  final String catKey = tx.category.trim().toLowerCase();
                  String? icon; Color? color;
                  if (userCategories.containsKey(catKey)) { icon = userCategories[catKey]!.icon; color = userCategories[catKey]!.colorValue; }
                  else if (_systemCategories.containsKey(catKey)) { icon = _systemCategories[catKey]!['icon']; color = Color(_systemCategories[catKey]!['color']); }
                  return TransactionItemTile(transaction: tx, uyuFormat: _uyuFormat, usdFormat: _usdFormat, categoryIcon: (tx.brandLogo != null && tx.brandLogo!.endsWith('.png')) ? tx.brandLogo : (icon ?? tx.brandLogo), categoryColor: color ?? tx.colorValue, onTap: () => showDialog(context: context, builder: (context) => EditTransactionDialog(transaction: tx, service: _service)), onDeleteConfirmed: () => _service.deleteTransaction(tx.id));
                },
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildCoverageCard() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
      builder: (context, txSnapshot) {
        final allTxs = txSnapshot.data ?? [];
        final txs = _isFamilyMode ? allTxs.where((t) => t.familyId != null).toList() : allTxs;

        double inUYU = txs.where((t) => t.type == 'INCOME' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
        double outUYU = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU' && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);
        double inUSD = txs.where((t) => t.type == 'INCOME' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
        double outUSD = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'USD' && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);
        double debtUYU = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU' && !t.isCompleted && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);
        double debtUSD = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'USD' && !t.isCompleted && !t.includedInCard).fold(0, (sum, t) => sum + t.amount);

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _service.getBalances(),
          builder: (context, balSnapshot) {
            final allBalances = balSnapshot.data ?? [];
            final balances = _isFamilyMode ? allBalances.where((b) => b['familyId'] != null).toList() : allBalances;
            
            double totalUYU = balances.where((b) => b['currency'] == 'UYU' && b['includeInCoverage'] != false && b['includeInCoverage'] != 0).fold(0.0, (sum, b) => sum + (b['amount'] ?? 0));
            double totalUSD = balances.where((b) => b['currency'] == 'USD' && b['includeInCoverage'] != false && b['includeInCoverage'] != 0).fold(0.0, (sum, b) => sum + (b['amount'] ?? 0));

            final now = DateTime.now();
            final bool isPast = DateTime(_viewingDate.year, _viewingDate.month).isBefore(DateTime(now.year, now.month));
            final bool isFuture = DateTime(_viewingDate.year, _viewingDate.month).isAfter(DateTime(now.year, now.month));

            return DebtCoverageCard(
              realUYU: isPast ? inUYU : (isFuture ? inUYU : totalUYU),
              debtUYU: isPast ? outUYU : (isFuture ? outUYU : debtUYU),
              realUSD: isPast ? inUSD : (isFuture ? inUSD : totalUSD),
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

  void _showUpdateBalanceDialog(Map<String, dynamic> b) {
    final controller = TextEditingController(text: CurrencyUtils.formatForInput((b['amount'] ?? 0.0).toDouble()));
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('Gestionar ${b['accountName']}'), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Saldo Total', border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () { final val = double.tryParse(controller.text); if (val != null) { _service.updateBalance(b['id'].toString(), val); Navigator.pop(ctx); } }, child: const Text('Actualizar'))]));
  }

  void _showQuickAddDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('¿Qué quieres registrar?'), content: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.add_circle, color: Colors.teal), title: const Text('Movimiento Simple'), onTap: () { Navigator.pop(context); showDialog(context: context, builder: (context) => SimpleTransactionDialog(service: _service, initialDate: _viewingDate)); }), ListTile(leading: const Icon(Icons.credit_card, color: Colors.blue), title: const Text('Compra con Tarjeta'), onTap: () { Navigator.pop(context); showDialog(context: context, builder: (context) => CreditCardTransactionDialog(service: _service, initialDate: _viewingDate)); })])));
  }

  Future<void> _refreshFullSync() async {
    await Future.wait([_service.syncTransactionsFromCloud(month: _viewingDate.month, year: _viewingDate.year), _service.syncBalancesFromCloud(), _service.syncGoalsFromCloud(), _service.syncCategoriesFromCloud()]);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todo actualizado desde la nube 🚀')));
  }
}
