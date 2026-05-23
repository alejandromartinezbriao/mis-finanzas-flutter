import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class AiAnalysisDialog extends StatefulWidget {
  final List<TransactionModel> transactions;
  final double monthlyBudget;
  final String monthLabel;

  const AiAnalysisDialog({
    super.key,
    required this.transactions,
    required this.monthlyBudget,
    required this.monthLabel,
  });

  @override
  State<AiAnalysisDialog> createState() => _AiAnalysisDialogState();
}

class _AiAnalysisDialogState extends State<AiAnalysisDialog> {
  final GeminiService _gemini = GeminiService();
  bool _isLoading = true;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      final Map<String, double> expensesByCategory = {};
      for (var t in widget.transactions) {
        if (t.type == 'EXPENSE') {
          expensesByCategory[t.category] = (expensesByCategory[t.category] ?? 0.0) + t.amount;
        }
      }

      final res = await _gemini.analizarFinanzas(
        presupuestoTotal: widget.monthlyBudget,
        gastosPorCategoria: expensesByCategory,
      );

      if (mounted) {
        setState(() {
          if (res != null) {
            _result = res;
          } else {
            _error = "No se pudo conectar con el asesor financiero.";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Error: $e"; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber),
          SizedBox(width: 12),
          Text('Asesor Financiero IA'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40),
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Analizando tus movimientos...'),
                  SizedBox(height: 40),
                ],
              )
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Análisis para ${widget.monthLabel}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 20),
                        if (_result?['alerta_critica'] != null)
                          _buildCard('Alerta', _result!['alerta_critica'], Colors.red),
                        const SizedBox(height: 12),
                        _buildCard('Mayor Gasto', _result?['categoria_mayor_gasto'] ?? 'N/A', Colors.blue),
                        const SizedBox(height: 12),
                        _buildCard('Consejo', _result?['consejo_ahorro'] ?? 'N/A', Colors.teal),
                      ],
                    ),
                  ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    );
  }

  Widget _buildCard(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
