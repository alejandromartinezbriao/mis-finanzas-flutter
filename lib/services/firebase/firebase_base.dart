import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseBase {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  
  // Campo para administración remota
  String? _overrideUid;
  void setOverrideUid(String? uid) => _overrideUid = uid;

  String get currentUid => _overrideUid ?? auth.currentUser?.uid ?? '';

  CollectionReference? get transactionsRef {
    if (currentUid.isEmpty) return null;
    return db.collection('users').doc(currentUid).collection('expenses');
  }

  CollectionReference? get templatesRef {
    if (currentUid.isEmpty) return null;
    return db.collection('users').doc(currentUid).collection('templates');
  }

  CollectionReference? get balancesRef {
    if (currentUid.isEmpty) return null;
    return db.collection('users').doc(currentUid).collection('balances');
  }

  CollectionReference? get categoriesRef {
    if (currentUid.isEmpty) return null;
    return db.collection('users').doc(currentUid).collection('categories');
  }

  CollectionReference? get budgetsRef {
    if (currentUid.isEmpty) return null;
    return db.collection('users').doc(currentUid).collection('budgets');
  }

  CollectionReference? get goalsRef {
    if (currentUid.isEmpty) return null;
    return db.collection('users').doc(currentUid).collection('goals');
  }

  CollectionReference? get subscriptionsRef {
    if (currentUid.isEmpty) return null;
    return db.collection('users').doc(currentUid).collection('subscriptions');
  }

  Future<bool> checkPremium() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await db.collection('users').doc(uid).get();
    return doc.data()?['isPremium'] ?? false;
  }

  // MÉTODO MAESTRO: ¿Es el dueño de la App?
  Future<bool> isAleAdmin() async {
    final user = auth.currentUser;
    if (user == null) return false;
    // Verificamos por UID exacto (M8DdrH5YCtS8lVzaUh93Fx1DoF63) o por campo isAdmin en Firestore
    if (user.uid == 'M8DdrH5YCtS8lVzaUh93Fx1DoF63') return true;
    
    final doc = await db.collection('users').doc(user.uid).get();
    return doc.data()?['role'] == 'admin' || doc.data()?['isAdmin'] == true;
  }

  String norm(String text) => text.trim().toLowerCase();
  double round(double val) => double.parse(val.toStringAsFixed(2));

  String formatAmount(double amount, String currency) {
    final symbol = currency == 'UYU' ? r'$' : r'U$S';
    return "$symbol${amount.toStringAsFixed(2)}";
  }

  double parseAmount(String text) {
    String clean = text.replaceAll(r'$', '').replaceAll(r'U$S', '').replaceAll(' ', '').trim();
    if (clean.isEmpty) return 0.0;
    if (clean.contains(',') && clean.contains('.')) {
      int commaIdx = clean.lastIndexOf(',');
      int dotIdx = clean.lastIndexOf('.');
      if (commaIdx > dotIdx) {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }
    return double.tryParse(clean) ?? 0.0;
  }
}
