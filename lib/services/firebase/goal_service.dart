import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';

mixin GoalService on FirebaseBase {
  // --- METAS / GOALS ---

  Stream<List<Map<String, dynamic>>> getGoals() {
    final ref = goalsRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  Future<void> addGoal(Map<String, dynamic> data) async {
    try {
      final ref = goalsRef;
      if (ref == null) return;
      await ref.add({
        ...data,
        'currentAmount': round(data['currentAmount'] ?? 0.0),
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error addGoal: $e");
    }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      final ref = goalsRef;
      if (ref == null) return;
      await ref.doc(id).update(data);
    } catch (e) {
      print("Error updateGoal: $e");
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      final ref = goalsRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteGoal: $e");
    }
  }
}
