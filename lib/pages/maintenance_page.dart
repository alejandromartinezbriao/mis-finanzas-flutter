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
  bool _isNuclearLoading = false;

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
      if (mounted) _showReport('Normalización Finalizada', 'Se limpiaron las comas de $fixed transacciones.');
    } catch (e) { _showError(e); } 
    finally { if (mounted) setState(() => _isNormalizeLoading = false); }
  }

  Future<void> _runNuclearSync() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.orange.shade50,
        title: const Text('⚡ ACTIVAR RELOJ SUIZO'),
        content: const Text('Esta acción borrará el caché del teléfono y descargará todos tus datos desde Firebase (gastos, tarjetas, ingresos y cuentas).\n\nEs el paso final para ver tu información en esta nueva versión.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade900),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Comenzar Espejo'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isNuclearLoading = true);
    try {
      await _service.mirrorFirebaseToLocal();
      if (mounted) {
        _showReport('Sincronización Exitosa', 'El teléfono es ahora un espejo de la nube. Tus datos aparecerán en el Dashboard ahora mismo.');
      }
    } catch (e) { _showError(e); } 
    finally { if (mounted) setState(() => _isNuclearLoading = false); }
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
              // BOTÓN NUCLEAR
              _buildMaintenanceCard(
                title: '⚡ ACTIVAR RELOJ SUIZO (Fase Final)',
                subtitle: 'IMPORTANTE: Ejecuta esto para ver tus datos actuales de la web en el teléfono.',
                icon: Icons.bolt,
                iconColor: Colors.orange.shade900,
                onTap: _isNuclearLoading ? null : _runNuclearSync,
                isLoading: _isNuclearLoading,
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Normalizar Formatos (Quitar Comas)',
                subtitle: 'Purifica la base de datos eliminando comas de miles.',
                icon: Icons.cleaning_services,
                iconColor: Colors.blueGrey,
                onTap: _isNormalizeLoading ? null : _runNormalization,
                isLoading: _isNormalizeLoading,
              ),
              const SizedBox(height: 16),
              
              _buildMaintenanceCard(
                title: 'Corregir Error 100x (Decimales)',
                subtitle: 'Detecta y arregla montos inflados.',
                icon: Icons.exposure_minus_2,
                iconColor: Colors.orange.shade800,
                onTap: () => showDialog(context: context, builder: (c) => DecimalRepairDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Sincronizar Montos de Cuotas',
                subtitle: 'Corrige diferencias en las cuotas.',
                icon: Icons.sync_problem,
                iconColor: Colors.purple,
                onTap: () => showDialog(context: context, builder: (c) => SyncInstallmentsDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Mantenimiento Automático (Reconexión)',
                subtitle: 'Vincula gastos a plantillas.',
                icon: Icons.settings_suggest,
                iconColor: Colors.teal,
                onTap: () => showDialog(context: context, builder: (c) => TemplateReconnectDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Reparación de Emergencia',
                subtitle: 'Elimina ítems duplicados en tarjetas.',
                icon: Icons.health_and_safety_outlined,
                iconColor: Colors.red.shade700,
                onTap: () => showDialog(context: context, builder: (c) => DeepRepairDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Recuperar Cuotas Perdidas',
                subtitle: 'Restaura cuotas que faltan.',
                icon: Icons.history_edu,
                iconColor: Colors.blue,
                onTap: () => showDialog(context: context, builder: (c) => RecoverInstallmentsDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Unificación Global',
                subtitle: 'Unifica variaciones de nombres.',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
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
        subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: Text(subtitle, style: const TextStyle(fontSize: 13))),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
