import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';

mixin SubscriptionService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- SUSCRIPCIONES (PULL SYNC) ---

  Future<void> syncSubscriptionsFromCloud() async {
    try {
      final ref = subscriptionsRef;
      if (ref == null || kIsWeb) return;

      final snap = await ref.get();
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
          'syncStatus': 'synced'
        }).toList();
        await _local.insertBatch('subscriptions', items);
      }
    } catch (e) { print("Error syncing subscriptions: $e"); }
  }

  // --- SUSCRIPCIONES (OPERACIONES) ---

  Stream<List<Map<String, dynamic>>> getSubscriptions() {
    if (kIsWeb) {
      final ref = subscriptionsRef; if (ref == null) return Stream.value([]);
      return ref.snapshots().map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    void _load() async {
      try {
        final list = await _local.query('subscriptions', where: 'isDeleted = 0');
        if (!controller.isClosed) controller.add(list);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }
    _load();
    final sub = _local.onTableChanged.where((t) => t == 'subscriptions').listen((_) => _load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Future<void> addSubscription(Map<String, dynamic> data) async {
    try {
      final String tid = DateTime.now().millisecondsSinceEpoch.toString();
      if (!kIsWeb) await _local.insert('subscriptions', {...data, 'id': tid, 'syncStatus': 'synced'});
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        final doc = await subscriptionsRef?.add(data);
        if (!kIsWeb && doc != null) {
          await _local.delete('subscriptions', tid);
          await _local.insert('subscriptions', {...data, 'id': doc.id, 'syncStatus': 'synced'});
        }
      }
    } catch (e) {}
  }

  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    try {
      if (!kIsWeb) await _local.update('subscriptions', data, id);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && subscriptionsRef != null) await subscriptionsRef!.doc(id).update(data);
    } catch (e) {}
  }

  Future<void> deleteSubscription(String id) async {
    try {
      if (!kIsWeb) await _local.update('subscriptions', {'isDeleted': 1}, id);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && subscriptionsRef != null) await subscriptionsRef!.doc(id).delete();
    } catch (e) {}
  }
}
