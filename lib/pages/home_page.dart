import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/brand_icon.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseService _service = FirebaseService();
  DateTime _viewingDate = DateTime.now();

  final NumberFormat _uyuFormat = NumberFormat.currency(locale: 'es_UY', symbol: '\$', decimalDigits: 0);
  final NumberFormat _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: 'U\$S', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final monthYearLabel = DateFormat('MMMM yyyy', 'es_ES').format(_viewingDate).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text('MIS FINANZAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configuración rápida',
            onPressed: () => Navigator.pushNamed(context, '/setup'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro de que quieres salir?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await AuthService().signOut();
                }
              } else if (value == 'setup') {
                Navigator.pushNamed(context, '/setup');
              } else if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpiar Mes'),
                    content: Text('¿Borrar todos los movimientos de $monthYearLabel? (No borra las plantillas)'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Limpiar', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _service.clearMonth(_viewingDate.month, _viewingDate.year);
                }
              } else if (value == 'generate') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cargar Plantillas'),
                    content: Text('¿Deseas cargar los gastos e ingresos fijos para $monthYearLabel?\n\nNota: No se duplicarán los conceptos que ya existan.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cargar')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _service.generateMonthlyTransactions(_viewingDate.month, _viewingDate.year);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plantillas procesadas correctamente')));
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'setup',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Panel de Control'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: Colors.teal),
                    SizedBox(width: 12),
                    Text('Cargar Plantillas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Limpiar este Mes'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 900;
          
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PANEL IZQUIERDO (Resumen y Arqueo)
                SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthSelector(monthYearLabel),
                        const SizedBox(height: 20),
                        StreamBuilder<List<TransactionModel>>(
                          stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
                          builder: (context, txSnapshot) {
                            final txs = txSnapshot.data ?? [];
                            double inUYU = txs.where((t) => t.type == 'INCOME' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
                            double outUYU = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
                            double inUSD = txs.where((t) => t.type == 'INCOME' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
                            double outUSD = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
                            
                            // Obtener deudas (no pagas)
                            double debtUYU = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU' && !t.isCompleted).fold(0, (sum, t) => sum + t.amount);
                            double debtUSD = txs.where((t) => t.type == 'EXPENSE' && t.currency == 'USD' && !t.isCompleted).fold(0, (sum, t) => sum + t.amount);

                            return StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _service.getBalances(),
                              builder: (context, balSnapshot) {
                                final balances = balSnapshot.data ?? [];
                                double realUYU = balances.where((b) => b['currency'] == 'UYU').fold(0, (sum, b) => sum + (b['amount'] ?? 0));
                                double realUSD = balances.where((b) => b['currency'] == 'USD').fold(0, (sum, b) => sum + (b['amount'] ?? 0));

                                return Column(
                                  children: [
                                    _buildBalanceCard(inUYU, outUYU, inUSD, outUSD, isVertical: true),
                                    const SizedBox(height: 20),
                                    _buildComparisonCard(realUYU, debtUYU, realUSD, debtUSD),
                                  ],
                                );
                              }
                            );
                          }
                        ),
                        const SizedBox(height: 20),
                        _buildRealBalancesGrid(), 
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                // PANEL DERECHO (Lista de movimientos)
                Expanded(
                  child: Column(
                    children: [
                      _buildQuickAddButton(),
                      Expanded(child: _buildTransactionList(monthYearLabel)),
                    ],
                  ),
                ),
              ],
            );
          }

          // DISEÑO MÓVIL
          return Column(
            children: [
              _buildMonthSelector(monthYearLabel),
              Expanded(child: _buildTransactionList(monthYearLabel)),
              _buildQuickAddButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left, size: 24), 
            onPressed: () => setState(() => _viewingDate = DateTime(_viewingDate.year, _viewingDate.month - 1))
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right, size: 24), 
            onPressed: () => setState(() => _viewingDate = DateTime(_viewingDate.year, _viewingDate.month + 1))
          ),
        ],
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
            backgroundColor: Colors.blueGrey.shade800, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(String label) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _service.getTransactions(month: _viewingDate.month, year: _viewingDate.year),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final transactions = snapshot.data!;
        
        if (transactions.isEmpty) {
          return _buildEmptyState(label);
        }

        // Totales para móvil (se calculan aquí si no es web)
        double inUYU = transactions.where((t) => t.type == 'INCOME' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
        double outUYU = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU').fold(0, (sum, t) => sum + t.amount);
        double inUSD = transactions.where((t) => t.type == 'INCOME' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);
        double outUSD = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'USD').fold(0, (sum, t) => sum + t.amount);

        // Deudas (no pagas)
        double debtUYU = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'UYU' && !t.isCompleted).fold(0, (sum, t) => sum + t.amount);
        double debtUSD = transactions.where((t) => t.type == 'EXPENSE' && t.currency == 'USD' && !t.isCompleted).fold(0, (sum, t) => sum + t.amount);

        final incomes = transactions.where((t) => t.type == 'INCOME').toList()..sort((a, b) => a.title.compareTo(b.title));
        final expenses = transactions.where((t) => t.type == 'EXPENSE').toList()..sort((a, b) => a.title.compareTo(b.title));

        final sortedItems = [
          if (incomes.isNotEmpty) 'INGRESOS',
          ...incomes,
          if (expenses.isNotEmpty) 'GASTOS',
          ...expenses,
        ];

        return Column(
          children: [
            if (MediaQuery.of(context).size.width <= 900) ...[
              _buildBalanceCard(inUYU, outUYU, inUSD, outUSD, isCompact: true),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getBalances(),
                builder: (context, balSnap) {
                  final balances = balSnap.data ?? [];
                  double realUYU = balances.where((b) => b['currency'] == 'UYU').fold(0, (sum, b) => sum + (b['amount'] ?? 0));
                  double realUSD = balances.where((b) => b['currency'] == 'USD').fold(0, (sum, b) => sum + (b['amount'] ?? 0));
                  return _buildComparisonCard(realUYU, debtUYU, realUSD, debtUSD, isMobile: true);
                }
              ),
              _buildRealBalancesRow(),
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
                      child: Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
                    );
                  }
                  return _buildTransactionTile(item as TransactionModel);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No hay movimientos en $label.'),
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

  Widget _buildBalanceCard(double inUYU, double outUYU, double inUSD, double outUSD, {bool isVertical = false, bool isCompact = false}) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 4 : 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 20),
        child: isVertical 
          ? Column(
              children: [
                _balanceSmallRow('Resumen Pesos (UYU)', inUYU, outUYU, _uyuFormat),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                _balanceSmallRow('Resumen Dólares (USD)', inUSD, outUSD, _usdFormat),
              ],
            )
          : Row(
              children: [
                Expanded(child: _balanceSmallRow('UYU', inUYU, outUYU, _uyuFormat, isCompact: isCompact)),
                const VerticalDivider(width: 32),
                Expanded(child: _balanceSmallRow('USD', inUSD, outUSD, _usdFormat, isCompact: isCompact)),
              ],
            ),
      ),
    );
  }

  Widget _buildRealBalancesGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getBalances(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final balances = snapshot.data!;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DETALLE DE CUENTAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/setup'),
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
                  final format = b['currency'] == 'UYU' ? _uyuFormat : _usdFormat;
                  return GestureDetector(
                    onTap: () => _showUpdateBalanceDialog(b),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
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
                                Text(b['accountName'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                                Text(format.format(b['amount'] ?? 0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
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
  }

  Widget _buildComparisonCard(double realUYU, double debtUYU, double realUSD, double debtUSD, {bool isMobile = false}) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 4 : 0),
      color: Colors.blueGrey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: Colors.amber, size: 14),
                const SizedBox(width: 8),
                Text('COBERTURA DE DEUDAS', style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 16),
            _comparisonRow('Pesos (UYU)', realUYU, debtUYU, _uyuFormat, isMobile: isMobile),
            if (debtUSD > 0 || realUSD > 0) ...[
              Divider(color: Colors.white10, height: isMobile ? 12 : 24),
              _comparisonRow('Dólares (USD)', realUSD, debtUSD, _usdFormat, isMobile: isMobile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _comparisonRow(String label, double real, double debt, NumberFormat format, {bool isMobile = false}) {
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
            Text(label, style: TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isCovered ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isCovered ? 'CUBIERTO' : 'FALTANTE: ${format.format(debt - real)}',
                style: TextStyle(color: isCovered ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 4 : 12),
        // Barra de Dinero Real
        Row(
          children: [
            SizedBox(width: isMobile ? 65 : 80, child: Text('Disponible', style: TextStyle(color: Colors.white54, fontSize: isMobile ? 10 : 9))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: realProgress,
                  backgroundColor: Colors.white10,
                  color: Colors.tealAccent,
                  minHeight: isMobile ? 2 : 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 75, child: Text(format.format(real), textAlign: TextAlign.end, style: TextStyle(color: Colors.white, fontSize: isMobile ? 11 : 11, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 4),
        // Barra de Deuda
        Row(
          children: [
            SizedBox(width: isMobile ? 65 : 80, child: Text('Deuda', style: TextStyle(color: Colors.white54, fontSize: isMobile ? 10 : 9))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: debtProgress,
                  backgroundColor: Colors.white10,
                  color: Colors.orangeAccent,
                  minHeight: isMobile ? 2 : 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 75, child: Text(format.format(debt), textAlign: TextAlign.end, style: TextStyle(color: Colors.orangeAccent, fontSize: isMobile ? 11 : 11, fontWeight: FontWeight.bold))),
          ],
        ),
      ],
    );
  }

  Widget _buildRealBalancesRow() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getBalances(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final balances = snapshot.data!;
        
        // Calcular sumas totales por moneda
        double totalUYU = balances.where((b) => b['currency'] == 'UYU').fold(0, (sum, b) => sum + (b['amount'] ?? 0));
        double totalUSD = balances.where((b) => b['currency'] == 'USD').fold(0, (sum, b) => sum + (b['amount'] ?? 0));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 4, bottom: 4),
              child: Text('SALDOS REALES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
            ),
            SizedBox(
              height: 55,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // CARD DE SUMA TOTAL (MÓVIL)
                  Container(
                    width: 140, // Un poco más ancho para texto más grande
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal.shade600, Colors.teal.shade400]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL DISPONIBLE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(_uyuFormat.format(totalUYU), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        if (totalUSD > 0)
                          Text(_usdFormat.format(totalUSD), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                  // LISTA DE CUENTAS INDIVIDUALES
                  ...balances.map((b) {
                    final format = b['currency'] == 'UYU' ? _uyuFormat : _usdFormat;
                    return GestureDetector(
                      onTap: () => _showUpdateBalanceDialog(b),
                      child: Container(
                        width: 130, // Un poco más ancho para texto más grande
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))],
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
                                  Text(b['accountName'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                                  Text(format.format(b['amount'] ?? 0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateBalanceDialog(Map<String, dynamic> b) {
    final controller = TextEditingController(text: b['amount'].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Actualizar ${b['accountName']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Saldo Actual (${b['currency']})',
            prefixIcon: const Icon(Icons.account_balance_wallet),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                _service.updateBalance(b['id'], val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _balanceSmallRow(String label, double income, double expense, NumberFormat format, {bool isCompact = false}) {
    double balance = income - expense;
    double progress = (income > 0) ? (expense / income).clamp(0.0, 1.0) : (expense > 0 ? 1.0 : 0.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: isCompact ? 13 : 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        SizedBox(height: isCompact ? 4 : 12),
        _miniAmount('Ingresos', income, Colors.teal, format, isCompact: isCompact),
        SizedBox(height: isCompact ? 2 : 4),
        _miniAmount('Egresos', expense, Colors.deepOrange, format, isCompact: isCompact),
        if (!isCompact) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              color: progress > 0.9 ? Colors.red : (progress > 0.5 ? Colors.orange : Colors.teal),
              minHeight: 8,
            ),
          ),
        ],
        SizedBox(height: isCompact ? 8 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Disponible', style: TextStyle(fontSize: isCompact ? 12 : 13, color: Colors.grey)),
            Text(format.format(balance), style: TextStyle(fontSize: isCompact ? 16 : 18, fontWeight: FontWeight.bold, color: balance >= 0 ? Colors.teal : Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _miniAmount(String label, double amount, Color color, NumberFormat format, {bool isCompact = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isCompact ? 12 : 13, color: Colors.grey)),
        Text(format.format(amount), style: TextStyle(fontSize: isCompact ? 13 : 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildTransactionTile(TransactionModel t) {
    final format = t.currency == 'UYU' ? _uyuFormat : _usdFormat;
    final isExpense = t.type == 'EXPENSE';
    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Eliminar movimiento?'),
            content: Text('¿Estás seguro de que quieres eliminar "${t.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => _service.deleteTransaction(t.id),
      child: ListTile(
        dense: true,
        leading: BrandIcon(name: t.title, manualLogo: t.brandLogo, size: 32),
        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: t.dueDate != null ? Text('Vence: ${DateFormat('dd/MM').format(t.dueDate!)}', style: const TextStyle(fontSize: 11)) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(format.format(t.amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isExpense ? Colors.black : Colors.green)),
            if (isExpense) Icon(t.isCompleted ? Icons.check_circle : Icons.pending_actions, size: 14, color: t.isCompleted ? Colors.green : Colors.orange),
          ],
        ),
        onTap: () => _showEditDialog(t),
      ),
    );
  }

  void _showEditDialog(TransactionModel t) {
    final TextEditingController amountController = TextEditingController(text: t.amount.toString());
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final String rawDesc = t.description ?? '';
        final List<String> items = rawDesc.isEmpty ? [] : rawDesc.split(', ').where((s) => s.trim().isNotEmpty).toList();
        return AlertDialog(
          title: Text(t.title),
          scrollable: true,
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (items.isNotEmpty) ...[
                  const Align(alignment: Alignment.centerLeft, child: Text('Consumos (clic para borrar cuotas):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                  const SizedBox(height: 8),
                  ...items.map((item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onTap: () async {
                      final bool? ok = await showDialog<bool>(context: dialogContext, builder: (ctx) => AlertDialog(title: const Text('¿Eliminar cuotas?'), content: Text('Se borrará "$item" de todos los meses.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, borrar todo'))]));
                      if (ok == true) {
                        await _service.removeCreditCardExpense(cardName: t.title, fullItemText: item, startDate: t.date);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      }
                    },
                  )),
                  const Divider(),
                ],
                const SizedBox(height: 10),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto Total', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () async {
              final bool? confirm = await showDialog<bool>(context: dialogContext, builder: (ctx) => AlertDialog(title: const Text('¿Borrar ítem?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar', style: TextStyle(color: Colors.red)))]));
              if (confirm == true) {
                _service.deleteTransaction(t.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
            TextButton(onPressed: () { _service.updateTransaction(t.copyWith(isCompleted: !t.isCompleted)); Navigator.pop(dialogContext); }, child: Text(t.isCompleted ? 'Pendiente' : 'Pagado')),
            if (t.category != 'Tarjeta') IconButton(icon: const Icon(Icons.autorenew, color: Colors.blue), tooltip: 'Hacer recurrente', onPressed: () async {
              final confirm = await showDialog<bool>(context: dialogContext, builder: (ctx) => AlertDialog(title: const Text('¿Hacer recurrente?'), content: const Text('Este gasto se guardará como plantilla y aparecerá automáticamente en los próximos meses.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hacer Fijo'))]));
              if (confirm == true) {
                await _service.createTemplateFromTransaction(t);
                if (dialogContext.mounted) { Navigator.pop(dialogContext); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado como gasto fijo para el futuro'))); }
              }
            }),
            FilledButton(onPressed: () { final double? val = double.tryParse(amountController.text); if (val != null) { _service.updateTransaction(t.copyWith(amount: val)); Navigator.pop(dialogContext); } }, child: const Text('Guardar')),
          ],
        );
      },
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
            ListTile(leading: const Icon(Icons.add_circle, color: Colors.teal), title: const Text('Ingreso o Gasto Simple'), subtitle: const Text('Movimiento puntual en este mes'), onTap: () { Navigator.pop(context); _showSimpleTransactionDialog(); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.credit_card, color: Colors.blue), title: const Text('Compra con Tarjeta'), subtitle: const Text('Suma al total de la tarjeta y permite cuotas'), onTap: () { Navigator.pop(context); _showCreditCardDialog(); }),
          ],
        ),
      ),
    );
  }

  void _showSimpleTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'EXPENSE';
    String currency = 'UYU';
    DateTime selectedDate = _viewingDate;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Nuevo Movimiento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(segments: const [ButtonSegment(value: 'EXPENSE', label: Text('Gasto'), icon: Icon(Icons.remove_circle)), ButtonSegment(value: 'INCOME', label: Text('Ingreso'), icon: Icon(Icons.add_circle))], selected: {type}, onSelectionChanged: (val) => setS(() => type = val.first)),
              const SizedBox(height: 10),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Concepto')),
              Row(children: [Expanded(child: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto'))), const SizedBox(width: 10), DropdownButton<String>(value: currency, onChanged: (v) => setS(() => currency = v!), items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList())]),
              const SizedBox(height: 10),
              ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: Text('Mes de imputación: ${DateFormat('MMMM yyyy', 'es_ES').format(selectedDate)}'), onTap: () async { final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (picked != null) setS(() => selectedDate = picked); }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(onPressed: () { if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) { _service.addTransaction(TransactionModel(id: '', title: titleController.text, amount: double.parse(amountController.text), date: selectedDate, category: 'Extra', currency: currency, type: type, isCompleted: true)); Navigator.pop(context); } }, child: const Text('Añadir')),
          ],
        ),
      ),
    );
  }

  void _showCreditCardDialog() {
    final amountController = TextEditingController();
    final installmentsController = TextEditingController(text: '1');
    final conceptController = TextEditingController();
    String? selectedCard;
    String currency = 'UYU';
    DateTime selectedDate = _viewingDate;
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getTemplates(type: 'EXPENSE'),
        builder: (context, snapshot) {
          final cards = snapshot.data?.where((t) => t['isCreditCard'] == true).toList() ?? [];
          return StatefulBuilder(
            builder: (context, setS) => AlertDialog(
              title: const Row(children: [Icon(Icons.credit_card, color: Colors.blue), SizedBox(width: 10), Text('Compra con Tarjeta')]),
              content: cards.isEmpty ? const Text('Primero debes marcar alguna de tus plantillas de gastos como "Tarjeta de Crédito" en Configuración.') : SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(value: selectedCard, hint: const Text('Seleccionar Tarjeta'), items: cards.map((c) => DropdownMenuItem<String>(value: c['title'], child: Text(c['title']))).toList(), onChanged: (v) => setS(() => selectedCard = v), decoration: const InputDecoration(labelText: 'Tarjeta')), const SizedBox(height: 10), TextField(controller: conceptController, decoration: const InputDecoration(labelText: 'Concepto', hintText: 'Ej: Televisor, Supermercado')), const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto Total'))), const SizedBox(width: 10), DropdownButton<String>(value: currency, onChanged: (v) => setS(() => currency = v!), items: ['UYU', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList())]), const SizedBox(height: 10), TextField(controller: installmentsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad de Cuotas')), const SizedBox(height: 10), ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: Text('Mes de inicio: ${DateFormat('MMMM yyyy', 'es_ES').format(selectedDate)}'), onTap: () async { final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (picked != null) setS(() => selectedDate = picked); })])),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                if (cards.isNotEmpty) FilledButton(onPressed: () { if (selectedCard != null && amountController.text.isNotEmpty) { _service.addCreditCardExpense(cardName: selectedCard!, totalAmount: double.parse(amountController.text), installments: int.parse(installmentsController.text), currency: currency, startDate: selectedDate, concept: conceptController.text.isNotEmpty ? conceptController.text : null); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando gasto de tarjeta...'))); } }, child: const Text('Registrar Compra')),
              ],
            ),
          );
        }
      ),
    );
  }
}
