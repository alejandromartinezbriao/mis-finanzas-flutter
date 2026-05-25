import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';

mixin CategoryService on FirebaseBase {
  // --- PRESUPUESTOS (Ahora integrados en Categorías) ---

  Stream<List<Map<String, dynamic>>> getBudgets(int month, int year) {
    // Redirigimos a las categorías, ya que ahora el presupuesto es una propiedad de la categoría
    return getCategories(type: 'EXPENSE');
  }

  Future<void> setBudget(String categoryName, double amount, int month, int year, String currency) async {
    // Buscamos la categoría por nombre y actualizamos su presupuesto
    try {
      final ref = categoriesRef;
      if (ref == null) return;
      
      final snap = await ref.where('name', isEqualTo: categoryName).limit(1).get();
      if (snap.docs.isNotEmpty) {
        await ref.doc(snap.docs.first.id).update({
          'budgetAmount': round(amount),
          'budgetCurrency': currency,
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
