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
              final reportData = r['report'] as Map<String, dynamic>;
              final DateTime date = r['updatedAt'].toDate();
              final String monthLabel = r['id'].toString().replaceAll('_', ' ');
              final int score = reportData['score'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getScoreColor(score).withOpacity(0.1),
                    child: Text('$score', style: TextStyle(color: _getScoreColor(score), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(monthLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Generado el ${DateFormat('dd/MM HH:mm').format(date)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(context, 'Alerta', reportData['alerta_critica'], Colors.red),
                          const SizedBox(height: 12),
                          _buildDetailItem(context, 'Categoría Crítica', reportData['categoria_mayor_gasto'], Colors.blue),
                          const SizedBox(height: 12),
                          _buildDetailItem(context, 'Consejo de Ahorro', reportData['consejo_ahorro'], Colors.teal),
                          if (reportData['meta_sugerida'] != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailItem(context, 'Meta Recomendada', reportData['meta_sugerida'], Colors.orange),
                          ],
                        ],
                      ),
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
