import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../dialogs/maintenance/recover_installments_dialog.dart';
import '../dialogs/maintenance/global_unify_dialog.dart';
import '../dialogs/maintenance/decimal_repair_dialog.dart';
import '../dialogs/maintenance/template_reconnect_dialog.dart';
import '../dialogs/maintenance/sync_installments_dialog.dart';
import '../dialogs/maintenance/deep_repair_dialog.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final FirebaseService _service = FirebaseService();
  bool _isNormalizeLoading = false;

  void _showReport(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
      ),
    );
  }

  void _showError(dynamic e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _runNormalization() async {
    setState(() => _isNormalizeLoading = true);
    try {
      final fixed = await _service.normalizeAllDescriptions();
      if (mounted) {
        _showReport('Normalización Finalizada', 'Se limpiaron las comas de $fixed transacciones en total.');
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isNormalizeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mantenimiento de Datos'), elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 1. FUNDACIÓN: Limpieza de texto
              _buildMaintenanceCard(
                title: 'Normalizar Formatos (Quitar Comas)',
                subtitle: 'Purifica la base de datos eliminando comas de miles. Es el primer paso recomendado.',
                icon: Icons.cleaning_services,
                iconColor: Colors.blueGrey,
                onTap: _isNormalizeLoading ? null : _runNormalization,
                isLoading: _isNormalizeLoading,
              ),
              const SizedBox(height: 16),
              
              // 2. CORRECCIÓN: Errores críticos de monto
              _buildMaintenanceCard(
                title: 'Corregir Error 100x (Decimales)',
                subtitle: 'Detecta y arregla montos inflados (96163 -> 961.63) por errores de coma previa.',
                icon: Icons.exposure_minus_2,
                iconColor: Colors.orange.shade800,
                onTap: () => showDialog(context: context, builder: (c) => DecimalRepairDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              // 3. COHERENCIA: Series históricas
              _buildMaintenanceCard(
                title: 'Sincronizar Montos de Cuotas',
                subtitle: 'Corrige diferencias en las cuotas comparando los mismos consumos en otros meses.',
                icon: Icons.sync_problem,
                iconColor: Colors.purple,
                onTap: () => showDialog(context: context, builder: (c) => SyncInstallmentsDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              // 4. VINCULACIÓN: Gastos sueltos a sus dueños
              _buildMaintenanceCard(
                title: 'Mantenimiento Automático (Reconexión)',
                subtitle: 'Identifica gastos que no están vinculados a sus plantillas originales y los reconecta.',
                icon: Icons.settings_suggest,
                iconColor: Colors.teal,
                onTap: () => showDialog(context: context, builder: (c) => TemplateReconnectDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              // 5. REPARACIÓN: Limpieza de duplicados internos
              _buildMaintenanceCard(
                title: 'Reparación de Emergencia',
                subtitle: 'Elimina ítems duplicados accidentalmente dentro de una misma tarjeta.',
                icon: Icons.health_and_safety_outlined,
                iconColor: Colors.red.shade700,
                onTap: () => showDialog(context: context, builder: (c) => DeepRepairDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              // 6. RESTAURACIÓN: Datos perdidos
              _buildMaintenanceCard(
                title: 'Recuperar Cuotas Perdidas',
                subtitle: 'Restaura cuotas que faltan en meses pasados basándose en el historial futuro.',
                icon: Icons.history_edu,
                iconColor: Colors.blue,
                onTap: () => showDialog(context: context, builder: (c) => RecoverInstallmentsDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              // 7. UNIFICACIÓN: Consistencia global
              _buildMaintenanceCard(
                title: 'Unificación Global',
                subtitle: 'Permite unificar variaciones de nombres de tarjetas o comercios en toda la historia.',
                icon: Icons.language,
                iconColor: Colors.indigo,
                onTap: () => showDialog(context: context, builder: (c) => GlobalUnifyDialog(service: _service)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: isLoading 
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: iconColor))
            : Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle, style: const TextStyle(fontSize: 13)),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
