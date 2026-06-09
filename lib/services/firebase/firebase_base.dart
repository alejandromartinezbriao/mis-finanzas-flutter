import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';

abstract class FirebaseBase {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService(); // Acceso al cache
  
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

  // EL GPS MAESTRO: Unificado para uso individual y familiar
  DocumentReference? getDocRef(String collection, String docId, {String? familyId}) {
    // Si el dato tiene un ID familiar (está compartido), apunta a la carpeta del Admin
    if (familyId != null && familyId.isNotEmpty) {
      return db.collection('users').doc(familyId).collection(collection).doc(docId);
    }
    // Si no, apunta a la carpeta privada del usuario
    return _ref(collection)?.doc(docId);
  }

  // --- IDENTIDAD (ZERO LATENCY) ---

  // Obtiene el ID de familia si existe, de lo contrario devuelve null (Uso individual)
  Future<String?> getMyFamilyId() async {
    return _authService.familyId;
  }

  // REPARACIÓN CRÍTICA: checkPremium ahora es instantáneo gracias al cache
  Future<bool> checkPremium() async {
    // Si el usuario es premium propio o pertenece a un círculo premium, habilitamos la nube
    if (_authService.isPremium) return true;
    
    // Cascada de seguridad: si no hay cache, intentamos una lectura rápida (fallback)
    final uid = currentUid;
    if (uid.isEmpty) return false;
    final doc = await db.collection('users').doc(uid).get(const GetOptions(source: Source.cache));
    return doc.data()?['isPremium'] == true;
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
