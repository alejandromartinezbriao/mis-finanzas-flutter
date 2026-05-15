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
          'isPremium': true, // Durante desarrollo, nuevos usuarios son Premium por defecto
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print("Error createUserProfileIfNotExist: $e");
    }
  }
}
