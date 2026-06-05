import 'package:cloud_firestore/cloud_firestore.dart';
import '../local_db_service.dart';
import 'firebase_base.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/balance_model.dart';
import '../../models/recurring_model.dart';

mixin UserService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- EL ESPEJO TOTAL v20 (ADN Real) ---

  Future<void> mirrorFirebaseToLocal() async {
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;

      print("📡 INICIANDO ESPEJO TOTAL v20...");
      await _local.clearAllData();

      // 1. Categorías
      final catsSnap = await categoriesRef?.get();
      if (catsSnap != null && catsSnap.docs.isNotEmpty) {
        final items = catsSnap.docs.map((d) => 
          CategoryModel.fromMap(d.data() as Map<String, dynamic>, d.id).toLocalMap()
        ).toList();
        await _local.insertBatch('categories', items);
      }

      // 2. Balances (Cuentas)
      final balsSnap = await balancesRef?.get();
      if (balsSnap != null && balsSnap.docs.isNotEmpty) {
        final items = balsSnap.docs.map((d) => 
          BalanceModel.fromMap(d.data() as Map<String, dynamic>, d.id).toLocalMap()
        ).toList();
        await _local.insertBatch('balances', items);
      }

      // 3. Plantillas (Templates)
      final tempsSnap = await templatesRef?.get();
      if (tempsSnap != null && tempsSnap.docs.isNotEmpty) {
        final items = tempsSnap.docs.map((d) => 
          RecurringModel.fromMap(d.data() as Map<String, dynamic>, d.id).toLocalMap()
        ).toList();
        await _local.insertBatch('templates', items);
      }

      // 4. Transacciones (Gastos/Ingresos/Tarjetas) - COLECCIÓN 'expenses'
      final txSnap = await transactionsRef?.get();
      if (txSnap != null && txSnap.docs.isNotEmpty) {
        print("📥 Inyectando ${txSnap.docs.length} movimientos...");
        final items = txSnap.docs.map((d) => 
          TransactionModel.fromMap(d.data() as Map<String, dynamic>, d.id).toLocalMap()
        ).toList();
        await _local.insertBatch('transactions', items);
      }

      // 5. Suscripciones y Metas (Copia directa)
      final goalsSnap = await goalsRef?.get();
      if (goalsSnap != null) {
        for (var d in goalsSnap.docs) {
          final data = d.data() as Map<String, dynamic>;
          await _local.insert('goals', {
            ...data,
            'id': d.id,
            'createdAt': data['createdAt'] != null ? (data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate().toIso8601String() : data['createdAt'].toString()) : null,
            'syncStatus': 'synced'
          }, silent: true);
        }
      }

      final subsSnap = await subscriptionsRef?.get();
      if (subsSnap != null) {
        for (var d in subsSnap.docs) {
          await _local.insert('subscriptions', {
            ...d.data() as Map<String, dynamic>,
            'id': d.id,
            'syncStatus': 'synced'
          }, silent: true);
        }
      }

      // Marcar como completado
      await _local.insert('settings', {'id': 'mirror_sync_done', 'value': 'true'});
      
      _local.notify('balances');
      _local.notify('transactions');
      _local.notify('categories');
      
      print("✅ ESPEJO v20 FINALIZADO.");
    } catch (e) {
      print("❌ FALLO EN EL ESPEJO: $e");
      rethrow;
    }
  }

  Future<bool> isMirrorSyncDone() async {
    final res = await _local.query('settings', where: 'id = ?', whereArgs: ['mirror_sync_done']);
    return res.isNotEmpty;
  }

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
        await ref.set({'email': user.email, 'displayName': user.displayName ?? '', 'isPremium': true, 'createdAt': Timestamp.now()});
      }
    } catch (e) {}
  }

  Future<void> updateUserName(String name) async {
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      await db.collection('users').doc(uid).update({'displayName': name});
    } catch (e) {}
  }

  Future<void> checkAndPerformMigrations() async {}

  Future<void> deleteAiReport(String reportDocId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    await db.collection('users').doc(uid).collection('ai_reports').doc(reportDocId).delete();
  }

  Stream<List<Map<String, dynamic>>> getAiReportsHistory() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return db.collection('users').doc(uid).collection('ai_reports').orderBy('updatedAt', descending: true).snapshots().map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }
}
