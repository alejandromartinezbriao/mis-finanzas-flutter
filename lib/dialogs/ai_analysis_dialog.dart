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
      // SEGURIDAD DE TIPOS (Para Flutter Web): Convertimos todo a double explícitamente
      final Map<String, double> expensesByCategory = {};
      for (var t in widget.transactions) {
        if (t.type == 'EXPENSE') {
          final String cat = t.category;
          final double amt = t.amount.toDouble(); // Forzamos double
          expensesByCategory[cat] = (expensesByCategory[cat] ?? 0.0) + amt;
        }
      }

      final res = await _gemini.analizarFinanzas(
        presupuestoTotal: widget.monthlyBudget.toDouble(), // Forzamos double
        gastosPorCategoria: expensesByCategory,
      );

      if (mounted) {
        setState(() {
          if (res != null && res.containsKey('error')) {
            _error = "Error de la IA: ${res['error']}";
          } else if (res != null) {
            _result = res;
          } else {
            _error = "No se pudo conectar con el asesor. Revisa los logs.";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Error local: $e"; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          const Text('Asesor Financiero IA', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  Text('Gemini está analizando tus datos...', style: TextStyle(fontStyle: FontStyle.italic)),
                  SizedBox(height: 40),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 10),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Análisis para ${widget.monthLabel}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 20),
                        if (_result?['alerta_critica'] != null && _result?['alerta_critica'] != "null")
                          _buildInsightCard(context, title: 'Alerta', content: _result!['alerta_critica'], color: Colors.red, icon: Icons.warning_amber_rounded),
                        const SizedBox(height: 12),
                        _buildInsightCard(context, title: 'Mayor Gasto', content: 'Categoría: ${_result?['categoria_mayor_gasto'] ?? 'N/A'}', color: Colors.blue, icon: Icons.trending_up),
                        const SizedBox(height: 12),
                        _buildInsightCard(context, title: 'Consejo de Ahorro', content: _result?['consejo_ahorro'] ?? 'Sigue gestionando tus gastos.', color: Colors.teal, icon: Icons.lightbulb_outline),
                        const SizedBox(height: 24),
                        const Center(child: Text('Análisis generado por Gemini 1.5 Flash', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic))),
                      ],
                    ),
                  ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
    );
  }

  Widget _buildInsightCard(BuildContext context, {required String title, required String content, required Color color, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1))]),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
