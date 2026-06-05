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
  final _targetController = TextEditingController();
  bool _isNormalizeLoading = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

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

  Future<void> _resolveTarget() async {
    final input = _targetController.text.trim();
    if (input.isEmpty) {
      _service.setOverrideUid(null);
      setState(() {});
      return;
    }

    // Si parece un email, intentamos buscar el UID
    if (input.contains('@')) {
      setState(() => _isSearching = true);
      final uid = await _service.getUidByEmail(input);
      setState(() => _isSearching = false);

      if (uid != null) {
        _targetController.text = uid;
        _service.setOverrideUid(uid);
        _showToast('Usuario encontrado: $input', isError: false);
      } else {
        _showToast('No se encontró ningún usuario con ese email', isError: true);
      }
    } else {
      // Si no es un email, asumimos que ya es un UID
      _service.setOverrideUid(input);
      _showToast('Modo remoto activado por UID', isError: false);
    }
    setState(() {});
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.orange.shade900),
    );
  }

  Future<void> _runNormalization() async {
    setState(() => _isNormalizeLoading = true);
    try {
      final fixed = await _service.normalizeAllDescriptions();
      if (mounted) _showReport('Proceso Finalizado', 'Se limpiaron las comas de $fixed transacciones en el usuario objetivo.');
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally { 
      if (mounted) setState(() => _isNormalizeLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRemote = _service.currentUid != _service.auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Maestro (Admin)'), 
        elevation: 0,
        backgroundColor: isRemote ? Colors.orange.shade900 : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // PANEL DE BÚSQUEDA POR EMAIL O UID
              Card(
                color: Colors.blueGrey.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('OBJETIVO DE ADMINISTRACIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _targetController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Email o UID del Usuario',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Dejar vacío para tus propios datos',
                          hintStyle: const TextStyle(color: Colors.white30),
                          border: const OutlineInputBorder(),
                          suffixIcon: _isSearching 
                            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                            : IconButton(
                                icon: const Icon(Icons.search, color: Colors.amber),
                                onPressed: _resolveTarget,
                              ),
                        ),
                        onSubmitted: (_) => _resolveTarget(),
                      ),
                      if (isRemote)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              const Text('MODO REMOTO ACTIVO', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  _targetController.clear();
                                  _resolveTarget();
                                }, 
                                child: const Text('DESACTIVAR', style: TextStyle(color: Colors.white, fontSize: 10, decoration: TextDecoration.underline))
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              _buildMaintenanceCard(
                title: 'Normalizar Formatos',
                subtitle: 'Elimina comas de miles en la nube del usuario.',
                icon: Icons.cleaning_services,
                iconColor: Colors.blueGrey,
                onTap: _isNormalizeLoading ? null : _runNormalization,
                isLoading: _isNormalizeLoading,
              ),
              const SizedBox(height: 16),
              
              _buildMaintenanceCard(
                title: 'Corregir Error 100x',
                subtitle: 'Repara montos inflados del usuario.',
                icon: Icons.exposure_minus_2,
                iconColor: Colors.orange.shade800,
                onTap: () => showDialog(context: context, builder: (c) => DecimalRepairDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Sincronizar Cuotas',
                subtitle: 'Corrige diferencias de cuotas en su historial.',
                icon: Icons.sync_problem,
                iconColor: Colors.purple,
                onTap: () => showDialog(context: context, builder: (c) => SyncInstallmentsDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Mantenimiento de Plantillas',
                subtitle: 'Vincula sus gastos huérfanos a plantillas.',
                icon: Icons.settings_suggest,
                iconColor: Colors.teal,
                onTap: () => showDialog(context: context, builder: (c) => TemplateReconnectDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Reparación de Emergencia',
                subtitle: 'Elimina duplicados en sus tarjetas.',
                icon: Icons.health_and_safety_outlined,
                iconColor: Colors.red.shade700,
                onTap: () => showDialog(context: context, builder: (c) => DeepRepairDialog(service: _service)),
              ),
              const SizedBox(height: 16),

              _buildMaintenanceCard(
                title: 'Unificación Global',
                subtitle: 'Unifica variaciones de nombres del usuario.',
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
