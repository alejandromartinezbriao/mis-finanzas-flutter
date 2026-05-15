import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';

mixin CategoryService on FirebaseBase {
  // --- PRESUPUESTOS ---

  Stream<List<Map<String, dynamic>>> getBudgets(int month, int year) {
    final ref = budgetsRef;
    if (ref == null) return Stream.value([]);
    return ref.where('month', isEqualTo: month).where('year', isEqualTo: year).snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  Future<void> setBudget(String categoryName, double amount, int month, int year, String currency) async {
    try {
      final ref = budgetsRef;
      if (ref == null) return;
      
      final existing = await ref
          .where('categoryName', isEqualTo: categoryName)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      if (existing.docs.isNotEmpty) {
        await ref.doc(existing.docs.first.id).update({'amount': round(amount), 'currency': currency});
      } else {
        await ref.add({
          'categoryName': categoryName,
          'amount': round(amount),
          'month': month,
          'year': year,
          'currency': currency,
        });
      }
    } catch (e) {
      print("Error setBudget: $e");
    }
  }

  // --- CATEGORÍAS ---

  Stream<List<Map<String, dynamic>>> getCategories({String? type}) {
    final ref = categoriesRef;
    if (ref == null) return Stream.value([]);
    
    Query query = ref;
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    
    return query.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Ordenar en memoria para evitar requerir índices compuestos en Firestore
      list.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
      return list;
    });
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      final ref = categoriesRef;
      if (ref == null) return;
      await ref.add(data);
    } catch (e) {
      print("Error addCategory: $e");
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final ref = categoriesRef;
      if (ref == null) return;
      await ref.doc(id).update(data);
    } catch (e) {
      print("Error updateCategory: $e");
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final ref = categoriesRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteCategory: $e");
    }
  }
}
