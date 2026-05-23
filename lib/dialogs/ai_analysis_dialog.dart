import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class AiAnalysisDialog extends StatefulWidget {
  final List<TransactionModel> transactions;
  final double monthlyBudget;
  final String monthLabel;
  final FirebaseService service; // Necesario para obtener el perfil

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
  
  // Lógica para mensajes de carga dinámicos
  String _loadingMessage = 'Iniciando auditoría...';
  late Timer _timer;
  final List<String> _messages = [
    'Saludando a la IA...',
    'Analizando patrones de consumo...',
    'Auditando tus categorías...',
    'Buscando posibles fugas de dinero...',
    'Preparando tu informe ejecutivo...'
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
      // 1. Obtener el nombre del usuario desde el perfil
      final profile = await widget.service.getUserProfile().first;
      final String userName = profile?['displayName'] ?? 'Usuario';

      // 2. Obtener saldos disponibles para cobertura (Inteligencia Financiera)
      final balances = await widget.service.getBalances().first;
      final Map<String, double> saldosResumen = {};
      for (var b in balances) {
        if (b['includeInCoverage'] != false) {
          final String cur = b['currency'] ?? 'UYU';
          final double amt = (b['amount'] ?? 0.0).toDouble();
          saldosResumen[cur] = (saldosResumen[cur] ?? 0.0) + amt;
        }
      }

      // 3. Calcular Pagado vs Pendiente e Ingreso Total por moneda
      final Map<String, double> pagadoPorMoneda = {'UYU': 0, 'USD': 0};
      final Map<String, double> pendientePorMoneda = {'UYU': 0, 'USD': 0};
      final Map<String, double> ingresoPorMoneda = {'UYU': 0, 'USD': 0};
      final Map<String, Map<String, double>> gastosPorCatYMoneda = {
        'UYU': {},
        'USD': {},
      };

      for (var t in widget.transactions) {
        final String cur = t.currency;
        final double amt = (t.amount ?? 0.0).toDouble();
        
        if (t.type == 'EXPENSE') {
          gastosPorCatYMoneda[cur]![t.category] = (gastosPorCatYMoneda[cur]![t.category] ?? 0.0) + amt;
          if (t.isCompleted) {
            pagadoPorMoneda[cur] = (pagadoPorMoneda[cur] ?? 0.0) + amt;
          } else {
            pendientePorMoneda[cur] = (pendientePorMoneda[cur] ?? 0.0) + amt;
          }
        } else if (t.type == 'INCOME') {
          ingresoPorMoneda[cur] = (ingresoPorMoneda[cur] ?? 0.0) + amt;
        }
      }

      final res = await _gemini.analizarFinanzas(
        presupuestoTotal: (widget.monthlyBudget ?? 0.0).toDouble(),
        gastosPorCategoria: gastosPorCatYMoneda,
        pagadoTotal: pagadoPorMoneda,
        pendienteTotal: pendientePorMoneda,
        ingresoTotal: ingresoPorMoneda,
        userName: userName,
        saldosActuales: saldosResumen,
      );

      if (mounted) {
        setState(() {
          if (res != null) {
            _result = res;
          } else {
            _error = "Finanz-IA no pudo responder en este momento.";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Error de conexión: No se pudo procesar el análisis."; _isLoading = false; });
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
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
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
                    child: Text(
                      _loadingMessage,
                      key: ValueKey(_loadingMessage),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'REPORTE DE SALUD: ${widget.monthLabel.toUpperCase()}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade300, letterSpacing: 1.2),
                            ),
                            if (_result?['score'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getScoreColor(_result!['score']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Score: ${_result!['score']}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getScoreColor(_result!['score'])),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Nuevo: Indicador visual de Score
                        if (_result?['score'] != null) ...[
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: 80,
                                      width: 80,
                                      child: CircularProgressIndicator(
                                        value: _result!['score'] / 100,
                                        strokeWidth: 8,
                                        color: _getScoreColor(_result!['score']),
                                        backgroundColor: Colors.grey.withOpacity(0.1),
                                      ),
                                    ),
                                    Text(
                                      '${_result!['score']}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _result?['score_label']?.toUpperCase() ?? '',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _getScoreColor(_result!['score']), letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],

                        if (_result?['alerta_critica'] != null && _result?['alerta_critica'] != "null")
                          _buildInsightCard(
                            title: 'Alerta Crítica',
                            content: _result!['alerta_critica'],
                            color: Colors.red,
                            icon: Icons.warning_amber_rounded,
                          ),
                        
                        const SizedBox(height: 12),
                        
                        _buildInsightCard(
                          title: 'Foco de Gasto',
                          content: 'Tu mayor egreso está en la categoría "${_result?['categoria_mayor_gasto'] ?? 'N/A'}".',
                          color: Colors.blue,
                          icon: Icons.trending_up,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildInsightCard(
                          title: 'Consejo de Finanz-IA',
                          content: _result?['consejo_ahorro'] ?? 'Sigue registrando tus movimientos para mejorar mi análisis.',
                          color: Colors.teal,
                          icon: Icons.lightbulb_outline,
                        ),

                        if (_result?['meta_sugerida'] != null)
                          const SizedBox(height: 12),
                        
                        if (_result?['meta_sugerida'] != null)
                          _buildInsightCard(
                            title: 'Meta Recomendada',
                            content: _result!['meta_sugerida'],
                            color: Colors.amber,
                            icon: Icons.flag_outlined,
                          ),
                        
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'Análisis basado en modelos Gemini de Vertex AI',
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInsightCard({required String title, required String content, required Color color, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
