import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';

mixin UserService on FirebaseBase {
  // --- USUARIOS / PERFIL ---

  Stream<Map<String, dynamic>?> getUserProfile() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return db.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }

  Future<void> createUserProfileIfNotExist() async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final ref = db.collection('users').doc(user.uid);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({
          'email': user.email,
          'displayName': user.displayName ?? '', // Intenta obtener el nombre de Google/Auth
          'isPremium': true,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print("Error createUserProfileIfNotExist: $e");
    }
  }

  Future<void> updateUserName(String name) async {
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      await db.collection('users').doc(uid).update({'displayName': name});
    } catch (e) {
      print("Error updateUserName: $e");
    }
  }

  /// Ejecuta migraciones estructurales y sincronización inicial de base de datos local
  Future<void> checkAndPerformMigrations() async {
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;

      // CORRECCIÓN: Usamos caché para que no se bloquee en modo avión
      final userDoc = await db.collection('users').doc(uid).get(GetOptions(source: Source.serverAndCache));
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      
      // 1. MIGRACIÓN v3.1: Presupuestos a Categorías (Existente)
      if (userData['migratedToV31'] != true) {
        await db.collection('users').doc(uid).update({'migratedToV31': true});
        await (this as dynamic).migrateBudgetsToCategories();
      }

      // 2. MIGRACIÓN v3.5+: Clonación agresiva a Base de Datos Local
      // Usamos el flag 'migratedToLocalV35' para cualquier versión 3.5.x o superior
      if (userData['migratedToLocalV35'] != true) {
        print("Iniciando Sincronización Inicial v3.5+ (Agresiva)...");
        
        // Sincronizar Categorías
        final cats = await (this as dynamic).getCategories().first;
        
        // Sincronizar Cuentas
        final accs = await (this as dynamic).getBalances().first;
        
        // Sincronizar Metas
        final goals = await (this as dynamic).getGoals().first;

        // Sincronizar Plantillas
        final templates = await (this as dynamic).getTemplates().first;

        // Marcamos como completado para que no se repita este proceso pesado
        await db.collection('users').doc(uid).update({'migratedToLocalV35': true});
        print("Sincronización v3.5 finalizada con éxito.");
      }
    } catch (e) {
      print("Error en checkAndPerformMigrations Híbrido: $e");
    }
  }

  // --- CACHÉ DE INFORMES IA ---

  Future<Map<String, dynamic>?> getCachedAiReport(String monthId, String dataHash) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;

    // Buscamos el reporte más reciente de ese mes que coincida con el Hash
    final snap = await db.collection('users').doc(uid).collection('ai_reports')
        .where('monthId', isEqualTo: monthId)
        .where('dataHash', isEqualTo: dataHash)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return Map<String, dynamic>.from(snap.docs.first.data()['report']);
    }
    return null;
  }

  Future<void> saveAiReport(String monthId, String dataHash, Map<String, dynamic> report) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    // Usar un ID único por reporte (timestamp) para permitir múltiples versiones
    final String reportId = "${monthId}_${DateTime.now().millisecondsSinceEpoch}";

    await db.collection('users').doc(uid).collection('ai_reports').doc(reportId).set({
      'monthId': monthId, // Guardamos a qué mes pertenece
      'dataHash': dataHash,
      'report': report,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteAiReport(String reportDocId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await db.collection('users').doc(uid).collection('ai_reports').doc(reportDocId).delete();
  }

  Stream<List<Map<String, dynamic>>> getAiReportsHistory() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return db
        .collection('users')
        .doc(uid)
        .collection('ai_reports')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }
}
