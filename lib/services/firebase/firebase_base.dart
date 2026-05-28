import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseBase {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  CollectionReference? get transactionsRef {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return db.collection('users').doc(uid).collection('expenses');
  }

  CollectionReference? get templatesRef {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return db.collection('users').doc(uid).collection('templates');
  }

  CollectionReference? get balancesRef {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return db.collection('users').doc(uid).collection('balances');
  }

  CollectionReference? get categoriesRef {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return db.collection('users').doc(uid).collection('categories');
  }

  CollectionReference? get budgetsRef {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return db.collection('users').doc(uid).collection('budgets');
  }

  CollectionReference? get goalsRef {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return db.collection('users').doc(uid).collection('goals');
  }

  CollectionReference? get subscriptionsRef {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return db.collection('users').doc(uid).collection('subscriptions');
  }

  Future<bool> get isPremium async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await db.collection('users').doc(uid).get();
    return doc.data()?['isPremium'] ?? false;
  }

  String norm(String text) => text.trim().toLowerCase();

  double round(double val) => double.parse(val.toStringAsFixed(2));

  String formatAmount(double amount, String currency) {
    final symbol = currency == 'UYU' ? r'$' : r'U$S';
    return "$symbol${amount.toStringAsFixed(2)}";
  }

  double parseAmount(String text) {
    // REGLA DE ORO: Puntos para decimales. Los miles NO se separan.
    // Si el usuario usa coma, la tratamos como decimal (notación uruguaya legacy).
    // Si usa ambos, el de más a la derecha gana como decimal.
    String clean = text.replaceAll(r'$', '').replaceAll(r'U$S', '').replaceAll(' ', '').trim();
    if (clean.isEmpty) return 0.0;

    if (clean.contains(',') && clean.contains('.')) {
      int commaIdx = clean.lastIndexOf(',');
      int dotIdx = clean.lastIndexOf('.');
      if (commaIdx > dotIdx) {
        // Caso 1.234,56 -> la coma es el decimal.
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Caso 1,234.56 -> el punto es el decimal.
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains(',')) {
      // Caso 1234,56 -> solo hay coma, es el decimal.
      clean = clean.replaceAll(',', '.');
    }

    return double.tryParse(clean) ?? 0.0;
  }
}
