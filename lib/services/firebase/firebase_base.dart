import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseBase {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  
  String? _overrideUid;
  void setOverrideUid(String? uid) => _overrideUid = uid;

  String get currentUid => _overrideUid ?? auth.currentUser?.uid ?? '';

  // --- REFERENCIAS DE COLECCIÓN ---

  CollectionReference? get transactionsRef => _ref('expenses');
  CollectionReference? get templatesRef => _ref('templates');
  CollectionReference? get balancesRef => _ref('balances');
  CollectionReference? get categoriesRef => _ref('categories');
  CollectionReference? get budgetsRef => _ref('budgets');
  CollectionReference? get goalsRef => _ref('goals');
  CollectionReference? get subscriptionsRef => _ref('subscriptions');

  CollectionReference? _ref(String collection) {
    if (currentUid.isEmpty) return null;
    return db.collection('users').doc(currentUid).collection(collection);
  }

  // --- LÓGICA DE VISIBILIDAD FAMILIAR (Contextual) ---

  Future<String?> getMyFamilyId() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    
    final doc = await db.collection('users').doc(uid).get();
    final data = doc.data();
    
    // 1. Si soy miembro (tengo un familyId de otro), lo devuelvo.
    if (data?['familyId'] != null) return data!['familyId'];

    // 2. Si soy Admin, solo muestro el switch si tengo invitaciones o miembros activos.
    // Esto evita que un usuario Premium solo vea el switch sin tener a nadie con quien compartir.
    if (data?['isPremium'] == true) {
      // Ver si tengo invitaciones enviadas
      final invSnap = await db.collection('invitations').where('fromUid', isEqualTo: uid).limit(1).get();
      if (invSnap.docs.isNotEmpty) return uid;

      // Ver si tengo miembros que ya aceptaron
      final memSnap = await db.collection('users').where('familyId', isEqualTo: uid).limit(1).get();
      if (memSnap.docs.isNotEmpty) return uid;
    }

    return null;
  }

  // --- UTILIDADES ---

  Future<bool> checkPremium() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await db.collection('users').doc(uid).get();
    return doc.data()?['isPremium'] ?? false;
  }

  Future<bool> isAleAdmin() async {
    final user = auth.currentUser;
    if (user == null) return false;
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
