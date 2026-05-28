import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';

mixin CategoryService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- PRESUPUESTOS (Integrados en Categorías) ---

  Stream<List<Map<String, dynamic>>> getBudgets(int month, int year) {
    return getCategories(type: 'EXPENSE');
  }

  Future<void> setBudget(String categoryName, double amount, int month, int year, String currency) async {
    try {
      final ref = categoriesRef;
      if (ref == null) return;
      
      final snap = await ref.where('name', isEqualTo: categoryName).limit(1).get();
      if (snap.docs.isNotEmpty) {
        final String docId = snap.docs.first.id;
        final data = {
          'budgetAmount': round(amount),
          'budgetCurrency': currency,
        };

        // 1. Siempre Nube (Configuración Universal)
        await ref.doc(docId).update(data);

        // 2. Siempre Local (Caché Offline)
        if (!kIsWeb) {
          await _local.update('categories', data, docId);
        }
      }
    } catch (e) {
      print("Error setBudget Híbrido: $e");
    }
  }

  // --- CATEGORÍAS ---

  Stream<List<Map<String, dynamic>>> getCategories({String? type}) {
    // Escuchamos de Firebase para mantener la sincronización en tiempo real
    final ref = categoriesRef;
    if (ref == null) return Stream.value([]);
    
    Query query = ref;
    if (type != null) query = query.where('type', isEqualTo: type);
    
    return query.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Aprovechamos este flujo para actualizar el caché local silenciosamente
        if (!kIsWeb) {
          _local.insert('categories', data);
        }
        
        return data;
      }).toList();
      
      list.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
      return list;
    });
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      final ref = categoriesRef;
      if (ref == null) return;

      // 1. Guardar en Nube primero para obtener el ID real
      final docRef = await ref.add(data);

      // 2. Guardar en Local con ese mismo ID
      if (!kIsWeb) {
        await _local.insert('categories', {...data, 'id': docRef.id});
      }
    } catch (e) {
      print("Error addCategory Híbrido: $e");
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      // Actualizamos en ambos mundos
      if (categoriesRef != null) await categoriesRef!.doc(id).update(data);
      if (!kIsWeb) await _local.update('categories', data, id);
    } catch (e) {
      print("Error updateCategory Híbrido: $e");
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      if (categoriesRef != null) await categoriesRef!.doc(id).delete();
      if (!kIsWeb) await _local.delete('categories', id);
    } catch (e) {
      print("Error deleteCategory Híbrido: $e");
    }
  }
}
