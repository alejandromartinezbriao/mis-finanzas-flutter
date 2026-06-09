import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';
import '../../models/goal_model.dart';

mixin GoalService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- METAS (SMARTER PULL v4.1.1) ---

  Future<void> syncGoalsFromCloud() async {
    try {
      if (kIsWeb) return;
      final String uid = currentUid;
      if (uid.isEmpty) return;

      List<GoalModel> cloudItems = [];
      
      // 1. Descargar de la nube
      final myRef = goalsRef;
      if (myRef != null) {
        final mySnap = await myRef.get();
        cloudItems.addAll(mySnap.docs.map((doc) => GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      final String? fid = await getMyFamilyId();
      if (fid != null && fid != uid) {
        final famRef = db.collection('users').doc(fid).collection('goals');
        final famSnap = await famRef.where('familyId', isEqualTo: fid).get();
        cloudItems.addAll(famSnap.docs.map((doc) => GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      // 2. COMPARACIÓN INTELIGENTE (Timestamps)
      for (var cloud in cloudItems) {
        final localData = await _local.query('goals', where: 'id = ?', whereArgs: [cloud.id]);
        if (localData.isNotEmpty) {
          final local = GoalModel.fromMap(localData.first, cloud.id);
          // SI EL LOCAL ES PENDIENTE O MÁS NUEVO QUE LA NUBE, NO LO PISAMOS
          if (local.syncStatus == 'pending') continue;
          if (local.updatedAt.isAfter(cloud.updatedAt)) continue;
        }
        await _local.insert('goals', cloud.toLocalMap(), silent: true);
      }
      _local.notify('goals');
    } catch (e) { print("Error syncing goals: $e"); }
  }

  // --- METAS (OPERACIONES) ---

  Stream<List<Map<String, dynamic>>> getGoals() {
    final String uid = currentUid;
    if (kIsWeb) {
      final ref = goalsRef; if (ref == null) return Stream.value([]);
      final myStream = ref.snapshots().map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
      return db.collection('users').doc(uid).snapshots().asyncExpand((userDoc) {
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final String? familyId = userData['familyId'];
        if (familyId == null) return myStream;
        Query sharedQuery = db.collectionGroup('goals').where('familyId', isEqualTo: familyId).where('isDeleted', isEqualTo: false);
        return sharedQuery.snapshots().map((sharedSnap) {
          final sharedItems = sharedSnap.docs.where((d) => d.reference.parent.parent?.id != uid).map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
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
      final DateTime now = DateTime.now();
      final String? fId = data['familyId'];
      
      final goal = GoalModel.fromMap({...data, 'createdAt': now, 'updatedAt': now, 'syncStatus': 'pending'}, tid);
      if (!kIsWeb) await _local.insert('goals', goal.toLocalMap());
      
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        final targetRef = (fId != null && fId.isNotEmpty) ? db.collection('users').doc(fId).collection('goals') : goalsRef;
        final doc = await targetRef?.add({...data, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
        if (!kIsWeb && doc != null) {
          await _local.delete('goals', tid);
          await _local.insert('goals', GoalModel.fromMap({...data, 'createdAt': now, 'updatedAt': now, 'syncStatus': 'synced'}, doc.id).toLocalMap());
        }
      }
    } catch (e) { print("Error adding goal: $e"); }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      final String sid = id.toString();
      final DateTime now = DateTime.now();
      String? fId = data['familyId'];
      if (!kIsWeb) {
        final localData = await _local.query('goals', where: 'id = ?', whereArgs: [sid]);
        if (localData.isNotEmpty) fId = localData.first['familyId'];
        await _local.update('goals', {...data, 'updatedAt': now.toIso8601String(), 'syncStatus': 'pending'}, sid);
      }
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        await getDocRef('goals', sid, familyId: fId)?.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
        if (!kIsWeb) await _local.update('goals', {'syncStatus': 'synced'}, sid, silent: true);
      }
    } catch (e) { print("Error updating goal: $e"); }
  }

  Future<void> deleteGoal(String id) async {
    try {
      final String sid = id.toString();
      String? fId;
      if (!kIsWeb) {
        final localData = await _local.query('goals', where: 'id = ?', whereArgs: [sid]);
        if (localData.isNotEmpty) fId = localData.first['familyId'];
        await _local.update('goals', {'isDeleted': 1}, sid);
      }
      final premium = await checkPremium();
      if (kIsWeb || premium) await getDocRef('goals', sid, familyId: fId)?.delete();
    } catch (e) { print("Error deleting goal: $e"); }
  }
}
