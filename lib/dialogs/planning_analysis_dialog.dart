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
      final uid = widget.service.auth.currentUser?.uid;
      if (uid == null) {
        setState(() { _error = "Sesión no válida."; _isLoading = false; });
        return;
      }

      final profile = await widget.service.getUserProfile().first;
      final String userName = profile?['displayName'] ?? 'Usuario';

      // LLAMADA SIMPLIFICADA: El servidor busca presupuestos, ingresos y saldos actuales.
      final res = await _gemini.analizarPlanificacion(
        uid: uid,
        userName: userName,
      );

      if (mounted) {
        setState(() {
          if (res != null) {
            _result = res;
          } else {
            _error = "No se pudo conectar con el motor estratégico central.";
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
      title: const Row(children: [Icon(Icons.psychology_outlined, color: Colors.indigo), SizedBox(width: 12), Text('Planificación Estratégica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Column(mainAxisSize: MainAxisSize.min, children: [SizedBox(height: 40), CircularProgressIndicator(color: Colors.indigo), SizedBox(height: 20), Text('Consultoría central en curso...', style: TextStyle(fontStyle: FontStyle.italic)), SizedBox(height: 40)])
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 20),
                        _buildSection('ANÁLISIS DE VIABILIDAD', _result?['analisis_detalle']),
                        _buildSection('AHORRO MENSUAL PROYECTADO', _result?['ahorro_proyectado'], color: Colors.teal, bold: true),
                        _buildSection('PROYECCIÓN A 6 MESES', _result?['proyeccion_6_meses'], italic: true),
                        if (_result?['recomendaciones'] != null) ...[
                          const SizedBox(height: 20),
                          const Text('RECOMENDACIONES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 0.5)),
                          ...(_result?['recomendaciones'] as List).map((r) => Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [const Icon(Icons.check_circle_outline, size: 14, color: Colors.indigo), const SizedBox(width: 8), Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 13)))]))),
                        ],
                        const SizedBox(height: 24),
                        const Center(child: Text('Planificación centralizada generada con Google Gen AI', style: TextStyle(fontSize: 9, color: Colors.grey))),
                      ],
                    ),
                  ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
    );
  }

  Widget _buildSection(String title, dynamic content, {Color? color, bool bold = false, bool italic = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade300, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(content?.toString() ?? '', style: TextStyle(fontSize: 14, height: 1.4, color: color, fontWeight: bold ? FontWeight.bold : null, fontStyle: italic ? FontStyle.italic : null)),
    ]);
  }

  Widget _buildHeaderCard() {
    final String viabilidad = _result?['viabilidad'] ?? 'Desconocida';
    Color color = viabilidad.contains('Viable') ? Colors.green : (viabilidad.contains('Arriesgada') ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [const Icon(Icons.verified_user_outlined, size: 32, color: Colors.green), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ESTADO DEL PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), Text(viabilidad.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))]))]),
    );
  }
}
