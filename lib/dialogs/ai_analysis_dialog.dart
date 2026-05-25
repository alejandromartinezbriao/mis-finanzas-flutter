import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class AiAnalysisDialog extends StatefulWidget {
  final List<TransactionModel> transactions; // Mantener por compatibilidad visual si fuera necesario, pero no para el Hash
  final double monthlyBudget;
  final String monthLabel;
  final FirebaseService service;

  const AiAnalysisDialog({
    super.key,
    required this.transactions,
    required this.monthlyBudget,
    required this.monthLabel,
    required this.service,
  });

  @override
  State<AiAnalysisDialog> createState() => _AiAnalysisDialogState();
}

class _AiAnalysisDialogState extends State<AiAnalysisDialog> {
  final GeminiService _gemini = GeminiService();
  bool _isLoading = true;
  Map<String, dynamic>? _result;
  String? _error;
  
  String _loadingMessage = 'Conectando con el servidor central...';
  late Timer _timer;
  final List<String> _messages = [
    'El servidor está recolectando tus datos...',
    'Calculando firma de estado bimonetaria...',
    'Consultando a Finanz-IA en la nube...',
    'Preparando tu reporte ejecutivo...',
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startLoadingMessages();
    _runAnalysis();
  }

  void _startLoadingMessages() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
          _loadingMessage = _messages[_messageIndex];
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    try {
      final uid = widget.service.auth.currentUser?.uid;
      if (uid == null) {
        setState(() { _error = "Sesión no válida."; _isLoading = false; });
        return;
      }

      final profile = await widget.service.getUserProfile().first;
      final String userName = profile?['displayName'] ?? 'Usuario';

      // Parsear mes y año desde el label (o usar widget.transactions para inferirlo)
      // Para mayor precisión, usamos el mes/año actual o de la primera transacción
      final now = DateTime.now();
      int month = now.month;
      int year = now.year;
      
      if (widget.transactions.isNotEmpty) {
        month = widget.transactions.first.date.month;
        year = widget.transactions.first.date.year;
      }

      // LLAMADA SIMPLIFICADA: Todo el trabajo se hace en el servidor
      final res = await _gemini.analizarFinanzas(
        uid: uid,
        month: month,
        year: year,
        userName: userName,
      );

      if (mounted) {
        setState(() {
          if (res != null) {
            _result = res;
          } else {
            _error = "Finanz-IA central no pudo responder.";
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Finanz-IA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(strokeWidth: 3, color: Colors.purple),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(_loadingMessage, key: ValueKey(_loadingMessage), textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                  const SizedBox(height: 40),
                ],
              )
            : _error != null
                ? Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScoreHeader(),
                        const SizedBox(height: 30),
                        if (_result?['resumen_ejecutivo'] != null) ...[
                          const Text('ANÁLISIS ESTRATÉGICO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Text(_result!['resumen_ejecutivo'], style: const TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                        ],
                        if (_result?['alerta_critica'] != null && _result?['alerta_critica'] != "null")
                          _buildInsightCard(title: 'Alerta Crítica', content: _result!['alerta_critica'], color: Colors.red, icon: Icons.warning_amber_rounded),
                        const SizedBox(height: 12),
                        _buildInsightCard(title: 'Foco de Gasto', content: 'Tu mayor egreso está en "${_result?['categoria_mayor_gasto'] ?? 'N/A'}".', color: Colors.blue, icon: Icons.trending_up),
                        const SizedBox(height: 12),
                        _buildInsightCard(title: 'Consejo Directo', content: _result?['consejo_ahorro'] ?? 'Sigue registrando tus movimientos.', color: Colors.teal, icon: Icons.lightbulb_outline),
                        if (_result?['meta_sugerida'] != null) ...[
                          const SizedBox(height: 12),
                          _buildInsightCard(title: 'Meta Recomendada', content: _result!['meta_sugerida'], color: Colors.amber, icon: Icons.flag_outlined),
                        ],
                        const SizedBox(height: 32),
                        const Center(child: Text('Consultoría centralizada generada con Google Gen AI', style: TextStyle(fontSize: 9, color: Colors.grey))),
                      ],
                    ),
                  ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)))],
    );
  }

  Widget _buildScoreHeader() {
    final int score = _result?['score'] ?? 0;
    final Color color = score >= 80 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);
    return Center(
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(height: 80, width: 80, child: CircularProgressIndicator(value: score / 100, strokeWidth: 8, color: color, backgroundColor: Colors.grey.withOpacity(0.1))),
          Text('$score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        Text(_result?['score_label']?.toUpperCase() ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
      ]),
    );
  }

  Widget _buildInsightCard({required String title, required String content, required Color color, required IconData icon}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 8), Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1))]),
        const SizedBox(height: 10),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
