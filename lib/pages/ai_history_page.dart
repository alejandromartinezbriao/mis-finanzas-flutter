import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class AiHistoryPage extends StatelessWidget {
  const AiHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Asesoría IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.getAiReportsHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Aún no tienes informes guardados.', style: TextStyle(color: Colors.grey)),
                  const Text('Consulta a Finanz-IA para verlos aquí.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          final reports = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              final String reportId = r['id'].toString();
              final reportData = r['report'] as Map<String, dynamic>;
              final DateTime date = r['updatedAt'].toDate();
              
              // Detectar tipo de informe
              final bool isPlanning = reportId.startsWith('plan_');
              final String monthLabel = isPlanning 
                ? reportId.replaceAll('plan_', '').replaceAll('_', ' ').toUpperCase()
                : reportId.replaceAll('_', ' ');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: isPlanning 
                    ? _buildPlanningLeading(reportData['viabilidad'] ?? '')
                    : _buildAuditLeading(reportData['score'] ?? 0),
                  title: Text(isPlanning ? 'Planificación: $monthLabel' : monthLabel, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    'Generado el ${DateFormat('dd/MM HH:mm').format(date)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar Informe'),
                          content: const Text('¿Estás seguro de que quieres eliminar este informe del historial?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await service.deleteAiReport(r['id']);
                      }
                    },
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isPlanning 
                        ? _buildPlanningDetails(context, reportData)
                        : _buildAuditDetails(context, reportData),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAuditLeading(int score) {
    return CircleAvatar(
      backgroundColor: _getScoreColor(score).withOpacity(0.1),
      child: Text('$score', style: TextStyle(color: _getScoreColor(score), fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildPlanningLeading(String viabilidad) {
    Color color = Colors.grey;
    if (viabilidad.contains('Viable')) color = Colors.green;
    else if (viabilidad.contains('Arriesgada')) color = Colors.orange;
    else if (viabilidad.contains('Inviable')) color = Colors.red;

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(Icons.psychology_outlined, color: color, size: 20),
    );
  }

  Widget _buildAuditDetails(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data['resumen_ejecutivo'] != null) ...[
          _buildDetailItem(context, 'Análisis Estratégico', data['resumen_ejecutivo'], Colors.purple),
          const SizedBox(height: 12),
        ],
        _buildDetailItem(context, 'Alerta', data['alerta_critica'], Colors.red),
        const SizedBox(height: 12),
        _buildDetailItem(context, 'Categoría Crítica', data['categoria_mayor_gasto'], Colors.blue),
        const SizedBox(height: 12),
        _buildDetailItem(context, 'Consejo de Ahorro', data['consejo_ahorro'], Colors.teal),
        if (data['meta_sugerida'] != null) ...[
          const SizedBox(height: 12),
          _buildDetailItem(context, 'Meta Recomendada', data['meta_sugerida'], Colors.orange),
        ],
      ],
    );
  }

  Widget _buildPlanningDetails(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(context, 'Análisis de Viabilidad', data['analisis_detalle'], Colors.indigo),
        const SizedBox(height: 12),
        _buildDetailItem(context, 'Ahorro Proyectado', data['ahorro_proyectado'], Colors.teal),
        const SizedBox(height: 12),
        _buildDetailItem(context, 'Proyección a 6 meses', data['proyeccion_6_meses'], Colors.blueGrey),
        if (data['recomendaciones'] != null) ...[
          const SizedBox(height: 12),
          Text('RECOMENDACIONES ESTRATÉGICAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade300, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          ...(data['recomendaciones'] as List).map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• ${r.toString()}', style: const TextStyle(fontSize: 13)),
          )),
        ],
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, dynamic content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(content?.toString() ?? 'N/A', style: const TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
