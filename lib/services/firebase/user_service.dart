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
          'displayName': user.displayName ?? '', // Intenta obtener el nombre de Google/Auth
          'isPremium': true,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print("Error createUserProfileIfNotExist: $e");
    }
  }

  Future<void> updateUserName(String name) async {
    try {
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      await db.collection('users').doc(uid).update({'displayName': name});
    } catch (e) {
      print("Error updateUserName: $e");
    }
  }
}
