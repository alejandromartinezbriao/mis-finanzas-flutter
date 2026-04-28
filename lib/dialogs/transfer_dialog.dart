import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../utils/currency_formatter.dart';

class TransferDialog extends StatefulWidget {
  final Map<String, dynamic> sourceAccount;
  final FirebaseService service;

  const TransferDialog({
    super.key,
    required this.sourceAccount,
    required this.service,
  });

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String _destinationType = 'ACCOUNT'; // 'ACCOUNT' or 'GOAL'
  String? _selectedDestinationId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.sourceAccount['currency'];

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mover desde ${widget.sourceAccount['accountName']}', 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            )
          ),
        ],
      ),
      content: Container(
        width: 400, // Ancho fijo para evitar que se expanda infinitamente
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿A DÓNDE QUIERES MOVER EL DINERO?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ACCOUNT', label: Text('Otra Cuenta'), icon: Icon(Icons.account_balance, size: 18)),
                    ButtonSegment(value: 'GOAL', label: Text('Una Meta'), icon: Icon(Icons.flag, size: 18)),
                  ],
                  selected: {_destinationType},
                  onSelectionChanged: (val) => setState(() {
                    _destinationType = val.first;
                    _selectedDestinationId = null;
                  }),
                ),
                const SizedBox(height: 24),
                if (_destinationType == 'ACCOUNT')
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.service.getBalances(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()));
                      }
                      final accounts = snapshot.data?.where((a) => a['id'] != widget.sourceAccount['id'] && a['currency'] == currency).toList() ?? [];
                      
                      if (accounts.isEmpty) {
                        return _buildEmptyState('No hay otras cuentas disponibles en $currency.');
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedDestinationId,
                        decoration: const InputDecoration(labelText: 'Cuenta Destino', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance_wallet)),
                        items: accounts.map((a) => DropdownMenuItem(value: a['id'] as String, child: Text(a['accountName']))).toList(),
                        onChanged: (v) => setState(() => _selectedDestinationId = v),
                        validator: (v) => v == null ? 'Selecciona un destino' : null,
                      );
                    },
                  )
                else
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: widget.service.getGoals(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()));
                      }
                      final goals = snapshot.data?.where((g) => g['currency'] == currency).toList() ?? [];
                      
                      if (goals.isEmpty) {
                        return _buildEmptyState('No hay metas configuradas en $currency.');
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedDestinationId,
                        decoration: const InputDecoration(labelText: 'Meta de Ahorro', border: OutlineInputBorder(), prefixIcon: Icon(Icons.outlined_flag)),
                        items: goals.map((g) => DropdownMenuItem(value: g['id'] as String, child: Text(g['title']))).toList(),
                        onChanged: (v) => setState(() => _selectedDestinationId = v),
                        validator: (v) => v == null ? 'Selecciona una meta' : null,
                      );
                    },
                  ),
                const SizedBox(height: 20),
                const Text('¿CUÁNTO QUIERES MOVER?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Monto ($currency)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.teal),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa un monto';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() && _selectedDestinationId != null) {
              final double amount = double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', '.'));
              
              try {
                await widget.service.transferFunds(
                  fromAccountId: widget.sourceAccount['id'],
                  amount: amount,
                  toAccountId: _destinationType == 'ACCOUNT' ? _selectedDestinationId : null,
                  toGoalId: _destinationType == 'GOAL' ? _selectedDestinationId : null,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Movimiento realizado con éxito'), backgroundColor: Colors.teal),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: Colors.orange))),
        ],
      ),
    );
  }
}
