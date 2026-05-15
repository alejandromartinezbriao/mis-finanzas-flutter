import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';

mixin TransferService on FirebaseBase {
  // --- TRANSFERENCIAS ---

  Future<void> transferFunds({
    required String fromAccountId,
    required double amount,
    String? toAccountId,
    String? toGoalId,
  }) async {
    try {
      final batch = db.batch();
      final fromRef = balancesRef!.doc(fromAccountId);
      
      // 1. Restar de la cuenta origen
      final fromDoc = await fromRef.get();
      final double fromCurrent = (fromDoc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
      batch.update(fromRef, {'amount': round(fromCurrent - amount), 'updatedAt': Timestamp.now()});

      // 2. Sumar al destino (Cuenta o Meta)
      if (toAccountId != null) {
        final toRef = balancesRef!.doc(toAccountId);
        final toDoc = await toRef.get();
        final double toCurrent = (toDoc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
        batch.update(toRef, {'amount': round(toCurrent + amount), 'updatedAt': Timestamp.now()});
      } else if (toGoalId != null) {
        final goalRef = goalsRef!.doc(toGoalId);
        final goalDoc = await goalRef.get();
        final double goalCurrent = (goalDoc.data() as Map<String, dynamic>)['currentAmount'] ?? 0.0;
        batch.update(goalRef, {'currentAmount': round(goalCurrent + amount)});
      }

      await batch.commit();
    } catch (e) {
      print("Error transferFunds: $e");
      rethrow;
    }
  }
}
