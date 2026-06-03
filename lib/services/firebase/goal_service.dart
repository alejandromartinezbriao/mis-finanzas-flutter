import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';

mixin GoalService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- METAS (PULL SYNC) ---

  Future<void> syncGoalsFromCloud() async {
    try {
      final ref = goalsRef;
      if (ref == null || kIsWeb) return;

      final snap = await ref.get();
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
            'createdAt': data['createdAt'] != null ? (data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate().toIso8601String() : data['createdAt'].toString()) : null,
            'syncStatus': 'synced'
          };
        }).toList();
        await _local.insertBatch('goals', items);
      }
    } catch (e) { print("Error syncing goals: $e"); }
  }

  // --- METAS (OPERACIONES) ---

  Stream<List<Map<String, dynamic>>> getGoals() {
    if (kIsWeb) {
      final ref = goalsRef; if (ref == null) return Stream.value([]);
      return ref.snapshots().map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    void _load() async {
      try {
        final list = await _local.query('goals', where: 'isDeleted = 0');
        if (!controller.isClosed) controller.add(list);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }
    _load();
    final sub = _local.onTableChanged.where((t) => t == 'goals').listen((_) => _load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Future<void> addGoal(Map<String, dynamic> data) async {
    try {
      final String tid = DateTime.now().millisecondsSinceEpoch.toString();
      if (!kIsWeb) await _local.insert('goals', {...data, 'id': tid, 'syncStatus': 'synced'});
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        final doc = await goalsRef?.add({...data, 'createdAt': FieldValue.serverTimestamp()});
        if (!kIsWeb && doc != null) {
          await _local.delete('goals', tid);
          await _local.insert('goals', {...data, 'id': doc.id, 'syncStatus': 'synced'});
        }
      }
    } catch (e) {}
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      if (!kIsWeb) await _local.update('goals', data, id);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && goalsRef != null) await goalsRef!.doc(id).update(data);
    } catch (e) {}
  }

  Future<void> deleteGoal(String id) async {
    try {
      if (!kIsWeb) await _local.update('goals', {'isDeleted': 1}, id);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && goalsRef != null) await goalsRef!.doc(id).delete();
    } catch (e) {}
  }
}
