import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';
import '../../models/category_model.dart';

mixin CategoryService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- CATEGORÍAS (PULL SYNC) ---

  Future<void> syncCategoriesFromCloud() async {
    try {
      final ref = categoriesRef;
      if (ref == null || kIsWeb) return;

      final snap = await ref.get();
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id).toLocalMap()).toList();
        await _local.insertBatch('categories', items);
      }
    } catch (e) { print("Error syncing categories: $e"); }
  }

  // --- CATEGORÍAS (OPERACIONES) ---

  Stream<List<Map<String, dynamic>>> getCategories({String? type}) {
    if (kIsWeb) {
      final ref = categoriesRef; if (ref == null) return Stream.value([]);
      Query query = ref.where('isDeleted', isEqualTo: false);
      if (type != null) query = query.where('type', isEqualTo: type);
      return query.snapshots().map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    void _load() async {
      try {
        final list = await _local.query('categories', where: type != null ? 'type = ? AND isDeleted = 0' : 'isDeleted = 0', whereArgs: type != null ? [type] : null, orderBy: 'name ASC');
        if (!controller.isClosed) controller.add(list);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }
    _load();
    final sub = _local.onTableChanged.where((t) => t == 'categories').listen((_) => _load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      final String tid = DateTime.now().millisecondsSinceEpoch.toString();
      if (!kIsWeb) await _local.insert('categories', {...data, 'id': tid, 'syncStatus': 'synced'});
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        final doc = await categoriesRef?.add(data);
        if (!kIsWeb && doc != null) {
          await _local.delete('categories', tid);
          await _local.insert('categories', {...data, 'id': doc.id, 'syncStatus': 'synced'});
        }
      }
    } catch (e) {}
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      if (!kIsWeb) await _local.update('categories', data, id);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && categoriesRef != null) await categoriesRef!.doc(id).update(data);
    } catch (e) {}
  }

  Future<void> deleteCategory(String id) async {
    try {
      if (!kIsWeb) await _local.update('categories', {'isDeleted': 1}, id);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && categoriesRef != null) await categoriesRef!.doc(id).delete();
    } catch (e) {}
  }

  Stream<List<Map<String, dynamic>>> getBudgets(int month, int year) => getCategories(type: 'EXPENSE');
  Future<void> setBudget(String categoryName, double amount, int month, int year, String currency) async {}
}
