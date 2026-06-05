import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyCircleTab extends StatefulWidget {
  final FirebaseService service;
  const FamilyCircleTab({super.key, required this.service});

  @override
  State<FamilyCircleTab> createState() => _FamilyCircleTabState();
}

class _FamilyCircleTabState extends State<FamilyCircleTab> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: widget.service.checkPremium(),
      builder: (context, snapshot) {
        final bool isPremium = snapshot.data ?? false;

        if (!isPremium) {
          return _buildPaywall();
        }

        return _buildAdminPanel();
      },
    );
  }

  Widget _buildPaywall() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text(
            'Círculo Familiar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestiona las finanzas de tu hogar en equipo. Invita a tu pareja o familiares para compartir gastos, cuentas y metas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, height: 1.5),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('FUNCIÓN PREMIUM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.amber)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'El Círculo Familiar está disponible exclusivamente para usuarios con suscripción activa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('¡PASARME A PREMIUM!'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    final String currentUid = widget.service.auth.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final String? familyId = userData['familyId'];
        final bool isMember = familyId != null;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.service.getSentInvitations(),
          builder: (context, invSnap) {
            final invitations = invSnap.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (isMember) ...[
                  _buildStatusCard(familyId, currentUid),
                  const SizedBox(height: 32),
                ],
                
                const Text('INVITAR A UN MIEMBRO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 16),
                const Text('Introduce el correo de la persona que deseas unir a tu círculo financiero.', style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _sendInvitation,
                    icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                    label: const Text('ENVIAR INVITACIÓN'),
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 24),
                const Text('ESTADO DEL CÍRCULO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(isMember ? 'Tú (Miembro)' : 'Tú (Administrador)'),
                  subtitle: const Text('Premium Activo'),
                  trailing: const Icon(Icons.verified, color: Colors.teal),
                ),
                ...invitations.map((inv) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.mail_outline, color: Colors.white)),
                  title: Text(inv['toEmail']),
                  subtitle: const Text('Invitación pendiente'),
                  trailing: const Text('Esperando...', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                )),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildStatusCard(String familyId, String currentUid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: Colors.teal),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Formas parte de un círculo familiar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              ),
              TextButton(
                onPressed: _leaveFamily,
                child: const Text('SALIR', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Ahora puedes compartir elementos y ver los registros compartidos por otros miembros.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Future<void> _leaveFamily() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir del Círculo?'),
        content: const Text('Dejarás de compartir tus datos y ya no verás los del resto de la familia. Tus datos personales se mantienen seguros en tu cuenta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar Salida'), style: FilledButton.styleFrom(backgroundColor: Colors.red)),
        ],
      ),
    );

    if (confirm == true) {
      final uid = widget.service.auth.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'familyId': FieldValue.delete(),
          'joinedFamilyAt': FieldValue.delete(),
        });
      }
    }
  }

  Future<void> _sendInvitation() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un correo válido')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.service.sendFamilyInvitation(email);
      if (mounted) {
        _emailController.clear();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Invitación Enviada'),
            content: Text('Se ha enviado una invitación a $email. Si aún no tiene la App, se le enviará un link de descarga por correo.'),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
