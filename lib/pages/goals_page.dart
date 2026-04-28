import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import 'setup_page.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final FirebaseService _service = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Metas de Ahorro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const SetupPage(initialIndex: 5))
            ),
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getGoals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final goals = snapshot.data!;

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aún no tienes metas definidas.'),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const SetupPage(initialIndex: 5))
                    ),
                    child: const Text('Configurar mi primera meta'),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final g = goals[index];
              final double target = (g['targetAmount'] as num).toDouble();
              final double current = (g['currentAmount'] as num).toDouble();
              final double percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
              final double remaining = (target - current).clamp(0.0, double.infinity);
              final currency = g['currency'] ?? 'UYU';
              
              final format = currency == 'UYU' 
                  ? NumberFormat.currency(locale: 'es_UY', symbol: r'$', decimalDigits: 0)
                  : NumberFormat.currency(locale: 'en_US', symbol: r'U$S', decimalDigits: 2);

              return GestureDetector(
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => SetupPage(initialIndex: 5, goalToEdit: g))
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(_getIconData(g['icon']), color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('Objetivo: ${format.format(target)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                                ],
                              ),
                            ),
                            Text('${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 12,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            color: percent >= 1.0 ? Colors.green : Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ahorrado', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(format.format(current), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Faltante', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(format.format(remaining), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              ],
                            ),
                          ],
                        ),
                        if (percent >= 1.0)
                          const Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text('¡Meta cumplida!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'flag': return Icons.flag;
      case 'flight': return Icons.flight;
      case 'directions_car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'school': return Icons.school;
      case 'fitness_center': return Icons.fitness_center;
      case 'movie': return Icons.movie;
      case 'redeem': return Icons.redeem;
      case 'pets': return Icons.pets;
      case 'work': return Icons.work;
      default: return Icons.flag;
    }
  }
}
