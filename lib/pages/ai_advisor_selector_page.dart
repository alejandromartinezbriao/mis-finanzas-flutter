import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../dialogs/ai_analysis_dialog.dart';
import '../dialogs/planning_analysis_dialog.dart';
import '../utils/dialog_utils.dart';

class AiAdvisorSelectorPage extends StatefulWidget {
  const AiAdvisorSelectorPage({super.key});

  @override
  State<AiAdvisorSelectorPage> createState() => _AiAdvisorSelectorPageState();
}

class _AiAdvisorSelectorPageState extends State<AiAdvisorSelectorPage> {
  final FirebaseService service = FirebaseService();
  final GeminiService _gemini = GeminiService();
  Map<String, dynamic>? _cotizacion;
  bool _isLoadingCotizacion = true;

  @override
  void initState() {
    super.initState();
    _fetchCotizacion();
  }

  Future<void> _fetchCotizacion() async {
    final res = await _gemini.obtenerCotizacionDolar();
    if (mounted) {
      setState(() {
        _cotizacion = res;
        _isLoadingCotizacion = false;
      });
    }
  }

  String _getGreetingBase() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buen día';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asesor Financiero IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: service.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final String userName = snapshot.data?['displayName'] ?? 'Usuario';

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withOpacity(0.8)]
                  : [Colors.purple.withOpacity(0.05), Colors.white],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    children: [
                      // Avatar Personalizado de Finanz-IA
                      _buildAiAvatar(),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        '¡${_getGreetingBase()}, $userName!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Soy Finanz-IA, tu consultor estratégico. He preparado un par de herramientas para optimizar tu salud financiera.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.5),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Sección de Mercado (Cotización)
                      _buildCotizacionBanner(isDark),
                      
                      const SizedBox(height: 32),

                      // Opciones de Análisis
                      _buildOptionCard(
                        context: context,
                        title: 'Auditoría Mensual',
                        subtitle: 'Analiza tus gastos reales de este mes y detecta fugas de dinero.',
                        icon: Icons.analytics_rounded,
                        color: Colors.purple,
                        onTap: () => _startMonthlyAudit(context, service),
                      ),

                      const SizedBox(height: 16),

                      _buildOptionCard(
                        context: context,
                        title: 'Planificación Estratégica',
                        subtitle: 'Evalúa si tu plan de gastos es sostenible frente a tus ingresos futuros.',
                        icon: Icons.psychology_rounded,
                        color: Colors.indigo,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => PlanningAnalysisDialog(service: service),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                      
                      // Footer: Historial
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/ai_history'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded, size: 18, color: Colors.purple.shade300),
                              const SizedBox(width: 10),
                              Text(
                                'Ver mi historial de informes',
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.w600, 
                                  color: Colors.purple.shade300,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.indigo.shade600],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ]
          ),
        ),
        const Icon(Icons.auto_awesome, size: 60, color: Colors.white),
        // Pequeño indicador de "Online"
        Positioned(
          bottom: 5,
          right: 5,
          child: Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildCotizacionBanner(bool isDark) {
    if (_isLoadingCotizacion) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Consultando mercado oficial...', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
    
    if (_cotizacion == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: const Text('⚠️ Cotización no disponible momentáneamente', style: TextStyle(fontSize: 12, color: Colors.orange)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.teal.withOpacity(0.1) : Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_exchange_rounded, color: Colors.teal, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MERCADO URUGUAY (BROU)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.teal)),
                const SizedBox(height: 2),
                Text(
                  'Dólar oficial a \$${(_cotizacion!['venta'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('EN VIVO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal)),
          )
        ],
      ),
    );
  }

  Future<void> _startMonthlyAudit(BuildContext context, FirebaseService service) async {
    final now = DateTime.now();
    final String monthLabel = '${_getMonthName(now.month)} ${now.year}';
    final String monthId = monthLabel.replaceAll(' ', '_');

    final txs = await service.getTransactions(month: now.month, year: now.year).first;
    final budgets = await service.getBudgets(now.month, now.year).first;
    final double totalBudget = budgets.fold(0.0, (sum, b) => sum + (b['amount'] ?? 0.0));
    
    final profile = await service.getUserProfile().first;
    final String userName = profile?['displayName'] ?? 'Usuario';
    
    final String dataFingerprint = "$userName|$totalBudget|${txs.length}";

    final cached = await service.getCachedAiReport(monthId, dataFingerprint);

    if (cached != null) {
      final bool? update = await DialogUtils.confirmAction(
        context,
        title: 'Análisis Existente',
        message: 'Hola $userName, ya tienes un análisis para este mes. ¿Quieres que Finanz-IA lo actualice con la cotización de hoy?',
        confirmText: 'Actualizar',
      );
      
      if (update != true) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AiAnalysisDialog(
              transactions: txs,
              monthlyBudget: totalBudget > 0 ? totalBudget : 1000.0,
              monthLabel: monthLabel,
              service: service,
            ),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AiAnalysisDialog(
          transactions: txs,
          monthlyBudget: totalBudget > 0 ? totalBudget : 1000.0,
          monthLabel: monthLabel,
          service: service,
        ),
      );
    }
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return names[month - 1];
  }
}
