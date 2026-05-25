import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';

class PlanningAnalysisDialog extends StatefulWidget {
  final FirebaseService service;
  const PlanningAnalysisDialog({super.key, required this.service});

  @override
  State<PlanningAnalysisDialog> createState() => _PlanningAnalysisDialogState();
}

class _PlanningAnalysisDialogState extends State<PlanningAnalysisDialog> {
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
      final now = DateTime.now();
      
      // 1. Obtener Datos Maestros
      final budgets = await widget.service.getBudgets(now.month, now.year).first;
      final incomeTemplates = await widget.service.getTemplates(type: 'INCOME').first;
      final subscriptions = await widget.service.getSubscriptions().first;
      final balances = await widget.service.getBalances().first;
      final actualTxs = await widget.service.getTransactions(month: now.month, year: now.year).first;

      // 2. Procesar Datos Reales del Mes (BIMONETARIO)
      final Map<String, Map<String, double>> gastosActualesBimonetarios = {'UYU': {}, 'USD': {}};
      for (var t in actualTxs) {
        if (t.type == 'EXPENSE') {
          gastosActualesBimonetarios[t.currency]![t.category] = (gastosActualesBimonetarios[t.currency]![t.category] ?? 0.0) + t.amount;
        }
      }

      final Map<String, double> saldosActuales = {};
      for (var b in balances) {
        if (b['includeInCoverage'] != false) {
          final String cur = b['currency'] ?? 'UYU';
          saldosActuales[cur] = (saldosActuales[cur] ?? 0.0) + (b['amount'] ?? 0.0).toDouble();
        }
      }

      final profile = await widget.service.getUserProfile().first;
      final String userName = profile?['displayName'] ?? 'Usuario';

      // 3. Huella Digital DETERMINISTA (Celular y PC idénticos)
      final Map<String, dynamic> fingerprintData = {
        'type': 'PLAN_V3',
        'user': userName,
        'budgets': budgets.toString(),
        'templates': incomeTemplates.toString(),
        'balances': Map.fromEntries(saldosActuales.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
        'subs': subscriptions.toString(),
        'actual': gastosActualesBimonetarios.toString(),
      };
      
      final String rawFingerprint = jsonEncode(fingerprintData);
      final String dataFingerprint = md5.convert(utf8.encode(rawFingerprint)).toString();
      final String planMonthId = "plan_${now.year}_${now.month}";

      // 4. Intentar recuperar desde Caché
      final cached = await widget.service.getCachedAiReport(planMonthId, dataFingerprint);
      if (cached != null) {
        if (mounted) setState(() { _result = cached; _isLoading = false; });
        return;
      }

      // 5. Llamar a la IA
      final res = await _gemini.analizarPlanificacion(
        presupuestos: budgets,
        ingresosPrevistos: incomeTemplates,
        saldosActuales: saldosActuales,
        gastosActuales: gastosActualesBimonetarios,
        suscripciones: subscriptions,
        userName: userName,
      );

      if (mounted) {
        setState(() {
          if (res != null) {
            _result = res;
            widget.service.saveAiReport(planMonthId, dataFingerprint, res);
          } else {
            _error = "No se pudo realizar el análisis estratégico.";
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
      title: const Row(
        children: [
          Icon(Icons.psychology_outlined, color: Colors.indigo),
          SizedBox(width: 12),
          Text('Planificación Estratégica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40),
                  CircularProgressIndicator(color: Colors.indigo),
                  SizedBox(height: 20),
                  Text('Finanz-IA está auditando tu futuro...', style: TextStyle(fontStyle: FontStyle.italic)),
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
                        _buildHeaderCard(),
                        const SizedBox(height: 20),
                        _buildSectionTitle('ANÁLISIS DE VIABILIDAD'),
                        Text(_result?['analisis_detalle'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                        const SizedBox(height: 20),
                        _buildSectionTitle('AHORRO MENSUAL PROYECTADO'),
                        Text(_result?['ahorro_proyectado'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                        const SizedBox(height: 20),
                        _buildSectionTitle('RECOMENDACIONES ESTRATÉGICAS'),
                        ...(_result?['recomendaciones'] as List? ?? []).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: Colors.indigo),
                              const SizedBox(width: 8),
                              Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                        const SizedBox(height: 20),
                        _buildSectionTitle('PROYECCIÓN A 6 MESES'),
                        Text(_result?['proyeccion_6_meses'] ?? '', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 24),
                        const Center(child: Text('Consultoría inteligente generada con Google Gen AI', style: TextStyle(fontSize: 9, color: Colors.grey))),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final String viabilidad = _result?['viabilidad'] ?? 'Desconocida';
    Color color = Colors.grey;
    IconData icon = Icons.help_outline;

    if (viabilidad.contains('Viable')) { color = Colors.green; icon = Icons.verified_user_outlined; }
    else if (viabilidad.contains('Arriesgada')) { color = Colors.orange; icon = Icons.warning_amber_rounded; }
    else if (viabilidad.contains('Inviable')) { color = Colors.red; icon = Icons.gpp_bad_outlined; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESTADO DEL PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text(viabilidad.toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade300, letterSpacing: 0.5)),
    );
  }
}
