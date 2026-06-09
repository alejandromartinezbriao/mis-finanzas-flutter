import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';

mixin SubscriptionService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- SUSCRIPCIONES (SMARTER PULL v4.1.1) ---

  Future<void> syncSubscriptionsFromCloud() async {
    try {
      if (kIsWeb) return;
      final String uid = currentUid;
      if (uid.isEmpty) return;

      List<Map<String, dynamic>> cloudItems = [];
      final myRef = subscriptionsRef;
      if (myRef != null) {
        final mySnap = await myRef.get();
        cloudItems.addAll(mySnap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id, 'syncStatus': 'synced'}));
      }
      final String? fid = await getMyFamilyId();
      if (fid != null && fid != uid) {
        final famRef = db.collection('users').doc(fid).collection('subscriptions');
        final famSnap = await famRef.where('familyId', isEqualTo: fid).get();
        cloudItems.addAll(famSnap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id, 'syncStatus': 'synced'}));
      }

      for (var cloud in cloudItems) {
        final localData = await _local.query('subscriptions', where: 'id = ?', whereArgs: [cloud['id']]);
        if (localData.isNotEmpty) {
          final String localStatus = localData.first['syncStatus'] ?? 'synced';
          final DateTime localUpd = DateTime.tryParse(localData.first['updatedAt'] ?? '') ?? DateTime(2000);
          final dynamic cloudUpdRaw = cloud['updatedAt'];
          final DateTime cloudUpd = cloudUpdRaw is Timestamp ? cloudUpdRaw.toDate() : (DateTime.tryParse(cloudUpdRaw?.toString() ?? '') ?? DateTime(2000));
          if (localStatus == 'pending') continue;
          if (localUpd.isAfter(cloudUpd)) continue;
        }
        await _local.insert('subscriptions', cloud, silent: true);
      }
      _local.notify('subscriptions');
    } catch (e) { print("Error syncing subscriptions: $e"); }
  }

  // --- SUSCRIPCIONES (OPERACIONES) ---

  Stream<List<Map<String, dynamic>>> getSubscriptions() {
    final String uid = currentUid;
    if (kIsWeb) {
      final ref = subscriptionsRef; if (ref == null) return Stream.value([]);
      final myStream = ref.snapshots().map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
      return db.collection('users').doc(uid).snapshots().asyncExpand((userDoc) {
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final String? familyId = userData['familyId'];
        if (familyId == null) return myStream;
        Query sharedQuery = db.collectionGroup('subscriptions').where('familyId', isEqualTo: familyId).where('isDeleted', isEqualTo: false);
        return sharedQuery.snapshots().map((sharedSnap) {
          final sharedItems = sharedSnap.docs.where((d) => d.reference.parent.parent?.id != uid).map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
          return myStream.map((myItems) => [...myItems, ...sharedItems]);
        }).asyncExpand((s) => s);
      });
    }
    final controller = StreamController<List<Map<String, dynamic>>>();
    void load() async {
      try {
        final list = await _local.query('subscriptions', where: 'isDeleted = 0');
        if (!controller.isClosed) controller.add(list);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }
    load();
    final sub = _local.onTableChanged.where((t) => t == 'subscriptions').listen((_) => load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Future<void> addSubscription(Map<String, dynamic> data) async {
    try {
      final String tid = DateTime.now().millisecondsSinceEpoch.toString();
      final DateTime now = DateTime.now();
      final String? fId = data['familyId'];
      if (!kIsWeb) await _local.insert('subscriptions', {...data, 'id': tid, 'syncStatus': 'pending', 'updatedAt': now.toIso8601String()});
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        final targetRef = (fId != null && fId.isNotEmpty) ? db.collection('users').doc(fId).collection('subscriptions') : subscriptionsRef;
        final doc = await targetRef?.add({...data, 'updatedAt': FieldValue.serverTimestamp()});
        if (!kIsWeb && doc != null) {
          await _local.delete('subscriptions', tid);
          await _local.insert('subscriptions', {...data, 'id': doc.id, 'syncStatus': 'synced', 'updatedAt': now.toIso8601String()});
        }
      }
    } catch (e) {}
  }

  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    try {
      final String sid = id.toString();
      final DateTime now = DateTime.now();
      String? fId = data['familyId'];
      if (!kIsWeb) {
        final localData = await _local.query('subscriptions', where: 'id = ?', whereArgs: [sid]);
        if (localData.isNotEmpty) fId = localData.first['familyId'];
        await _local.update('subscriptions', {...data, 'updatedAt': now.toIso8601String(), 'syncStatus': 'pending'}, sid);
      }
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        await getDocRef('subscriptions', sid, familyId: fId)?.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
        if (!kIsWeb) await _local.update('subscriptions', {'syncStatus': 'synced'}, sid, silent: true);
      }
    } catch (e) {}
  }

  Future<void> deleteSubscription(String id) async {
    try {
      final String sid = id.toString();
      String? fId;
      if (!kIsWeb) {
        final localData = await _local.query('subscriptions', where: 'id = ?', whereArgs: [sid]);
        if (localData.isNotEmpty) fId = localData.first['familyId'];
        await _local.update('subscriptions', {'isDeleted': 1}, sid);
      }
      final premium = await checkPremium();
      if (kIsWeb || premium) await getDocRef('subscriptions', sid, familyId: fId)?.delete();
    } catch (e) {}
  }
}
