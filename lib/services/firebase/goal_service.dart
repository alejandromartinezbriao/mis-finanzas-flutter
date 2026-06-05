import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';
import '../../models/goal_model.dart';

mixin GoalService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- METAS (PULL SYNC) ---

  Future<void> syncGoalsFromCloud() async {
    try {
      final ref = goalsRef;
      if (ref == null || kIsWeb) return;

      final snap = await ref.get();
      if (snap.docs.isNotEmpty) {
        final List<Map<String, dynamic>> items = snap.docs.map((doc) => 
          GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id).toLocalMap()
        ).toList();
        await _local.insertBatch('goals', items);
      }
    } catch (e) { print("Error syncing goals: $e"); }
  }

  // --- METAS (OPERACIONES) ---

  Stream<List<Map<String, dynamic>>> getGoals() {
    final String currentUid = auth.currentUser?.uid ?? '';

    if (kIsWeb) {
      final ref = goalsRef; if (ref == null) return Stream.value([]);
      final myStream = ref.snapshots().map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());

      return db.collection('users').doc(currentUid).snapshots().asyncExpand((userDoc) {
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final String? familyId = userData['familyId'];

        if (familyId == null) return myStream;

        Query sharedQuery = db.collectionGroup('goals')
            .where('familyId', isEqualTo: familyId)
            .where('isDeleted', isEqualTo: false);
        
        return sharedQuery.snapshots().map((sharedSnap) {
          final sharedItems = sharedSnap.docs
              .where((d) => d.reference.parent.parent?.id != currentUid)
              .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
              .toList();

          return myStream.map((myItems) => [...myItems, ...sharedItems]);
        }).asyncExpand((s) => s);
      });
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    void load() async {
      try {
        final list = await _local.query('goals', where: 'isDeleted = 0', orderBy: 'title ASC');
        if (!controller.isClosed) controller.add(list);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }
    load();
    final sub = _local.onTableChanged.where((t) => t == 'goals').listen((_) => load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Future<void> addGoal(Map<String, dynamic> data) async {
    try {
      final String tid = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final goal = GoalModel.fromMap({
        ...data, 
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, tid);
      
      if (!kIsWeb) await _local.insert('goals', goal.toLocalMap());
      
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        final doc = await goalsRef?.add({
          ...data, 
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!kIsWeb && doc != null) {
          await _local.delete('goals', tid);
          final updatedGoal = GoalModel.fromMap({
            ...data,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }, doc.id);
          await _local.insert('goals', updatedGoal.toLocalMap());
        }
      }
    } catch (e) { print("Error adding goal: $e"); }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      final String sid = id.toString();
      final updateData = {
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (!kIsWeb) await _local.update('goals', updateData, sid);
      
      final premium = await checkPremium();
      if ((kIsWeb || premium) && goalsRef != null) {
        await goalsRef!.doc(sid).update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) { print("Error updating goal: $e"); }
  }

  Future<void> deleteGoal(String id) async {
    try {
      final String sid = id.toString();
      if (!kIsWeb) await _local.update('goals', {'isDeleted': 1}, sid);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && goalsRef != null) await goalsRef!.doc(sid).delete();
    } catch (e) { print("Error deleting goal: $e"); }
  }
}
