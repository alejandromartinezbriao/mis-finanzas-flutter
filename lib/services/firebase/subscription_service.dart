import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';

mixin SubscriptionService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- SUSCRIPCIONES ---

  Stream<List<Map<String, dynamic>>> getSubscriptions() {
    final ref = subscriptionsRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Sync local cache
        if (!kIsWeb) {
          _local.insert('subscriptions', data);
        }

        return data;
      }).toList();
    });
  }

  Future<void> addSubscription(Map<String, dynamic> data) async {
    try {
      final ref = subscriptionsRef;
      if (ref == null) return;

      // 1. Nube
      final docRef = await ref.add(data);

      // 2. Local
      if (!kIsWeb) {
        await _local.insert('subscriptions', {...data, 'id': docRef.id});
      }
    } catch (e) {
      print("Error addSubscription Híbrido: $e");
    }
  }

  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    try {
      if (subscriptionsRef != null) await subscriptionsRef!.doc(id).update(data);
      if (!kIsWeb) await _local.update('subscriptions', data, id);
    } catch (e) {
      print("Error updateSubscription Híbrido: $e");
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      if (subscriptionsRef != null) await subscriptionsRef!.doc(id).delete();
      if (!kIsWeb) await _local.delete('subscriptions', id);
    } catch (e) {
      print("Error deleteSubscription Híbrido: $e");
    }
  }
}
