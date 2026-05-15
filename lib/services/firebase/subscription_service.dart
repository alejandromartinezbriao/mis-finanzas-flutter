import 'firebase_base.dart';

mixin SubscriptionService on FirebaseBase {
  // --- SUSCRIPCIONES ---

  Stream<List<Map<String, dynamic>>> getSubscriptions() {
    final ref = subscriptionsRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  Future<void> addSubscription(Map<String, dynamic> data) async {
    try {
      final ref = subscriptionsRef;
      if (ref == null) return;
      await ref.add(data);
    } catch (e) {
      print("Error addSubscription: $e");
    }
  }

  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    try {
      final ref = subscriptionsRef;
      if (ref == null) return;
      await ref.doc(id).update(data);
    } catch (e) {
      print("Error updateSubscription: $e");
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      final ref = subscriptionsRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteSubscription: $e");
    }
  }
}
