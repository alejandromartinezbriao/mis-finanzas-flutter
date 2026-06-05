import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';
import '../../models/transaction_model.dart';
import '../../models/recurring_model.dart';

mixin TemplateService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- PLANTILLAS (PULL SYNC) ---

  Future<void> syncTemplatesFromCloud() async {
    try {
      final ref = templatesRef;
      if (ref == null || kIsWeb) return;

      final snap = await ref.orderBy('orderIndex').get();
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((doc) => RecurringModel.fromMap(doc.data() as Map<String, dynamic>, doc.id).toLocalMap()).toList();
        await _local.insertBatch('templates', items);
      }
    } catch (e) { print("Error syncing templates: $e"); }
  }

  // --- PLANTILLAS (OPERACIONES) ---

  Future<List<Map<String, dynamic>>> findPotentialCardTwins({
    required String baseName, required String targetCurrency, String? logo, String? excludeId,
  }) async {
    try {
      final ref = templatesRef; if (ref == null) return [];
      final snapshot = await ref.where('type', isEqualTo: 'EXPENSE').where('isCreditCard', isEqualTo: true).where('currency', isEqualTo: targetCurrency).get();
      final candidates = snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).where((data) => data['id'] != excludeId).toList();
      final cleanSearchName = baseName.replaceAll(RegExp(r'\s+(pesos|dólares|uyu|usd|dolares)$', caseSensitive: false), '').trim().toLowerCase();
      for (var c in candidates) {
        int score = 0; final cName = (c['title'] as String).toLowerCase();
        if (logo != null && c['brandLogo'] == logo) score += 100;
        if (cName.contains(cleanSearchName)) score += 50;
        c['matchScore'] = score;
      }
      candidates.sort((a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int));
      return candidates;
    } catch (e) { return []; }
  }

  Stream<List<Map<String, dynamic>>> getTemplates({String? type}) {
    if (kIsWeb) {
      final ref = templatesRef; if (ref == null) return Stream.value([]);
      // REPARACIÓN WEB: Pedimos todo ordenado y filtramos en Dart para evitar la necesidad de índices compuestos
      return ref.orderBy('orderIndex').snapshots().map((snap) {
        final all = snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
        if (type == null) return all;
        return all.where((t) => t['type'] == type).toList();
      });
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    void load() async {
      try {
        final list = await _local.query('templates', where: type != null ? 'type = ? AND isDeleted = 0' : 'isDeleted = 0', whereArgs: type != null ? [type] : null, orderBy: 'orderIndex ASC, title ASC');
        if (!controller.isClosed) controller.add(list);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }
    load();
    final sub = _local.onTableChanged.where((t) => t == 'templates').listen((_) => load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Future<void> addTemplate(Map<String, dynamic> t, {bool isBimonetary = false}) async {
    try {
      final ref = templatesRef; if (ref == null) return;
      int nextIndex = 0;
      final all = await _local.query('templates');
      for (var doc in all) { if ((doc['orderIndex'] ?? 0) >= nextIndex) nextIndex = (doc['orderIndex'] ?? 0) + 1; }

      Future<void> create(Map<String, dynamic> data) async {
        final String tid = DateTime.now().millisecondsSinceEpoch.toString();
        if (!kIsWeb) await _local.insert('templates', {...data, 'id': tid, 'syncStatus': 'synced'});
        final premium = await checkPremium();
        if (kIsWeb || premium) {
          final docRef = await templatesRef?.add(data);
          if (!kIsWeb && docRef != null) {
            await _local.delete('templates', tid);
            await _local.insert('templates', {...data, 'id': docRef.id, 'syncStatus': 'synced'});
          }
        }
      }
      if (isBimonetary) {
        final name = t['title'];
        await create({...t, 'title': '$name (UYU)', 'currency': 'UYU', 'orderIndex': nextIndex, 'isBimonetaryPart': 1, 'baseName': name});
        await create({...t, 'title': '$name (USD)', 'currency': 'USD', 'orderIndex': nextIndex + 1, 'isBimonetaryPart': 1, 'baseName': name});
      } else {
        await create({...t, 'orderIndex': nextIndex});
      }
    } catch (e) {}
  }

  Future<void> updateTemplatesOrder(List<Map<String, dynamic>> templates) async {
    try {
      final premium = await checkPremium();
      final batch = (kIsWeb || premium) ? db.batch() : null;

      for (int i = 0; i < templates.length; i++) {
        final String id = templates[i]['id'].toString();
        if (!kIsWeb) await _local.update('templates', {'orderIndex': i}, id, silent: true);
        if (batch != null && templatesRef != null) {
          batch.update(templatesRef!.doc(id), {'orderIndex': i});
        }
      }
      
      if (batch != null) await batch.commit();
      if (!kIsWeb) _local.notify('templates');
    } catch (e) { print("Error updateTemplatesOrder: $e"); }
  }

  Future<void> updateTemplate(String id, Map<String, dynamic> data) async {
    try {
      final String sid = id.toString();
      if (!kIsWeb) await _local.update('templates', data, sid);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && templatesRef != null) await templatesRef!.doc(sid).update(data);
    } catch (e) {}
  }

  Future<void> deleteTemplate(String id) async {
    try {
      final String sid = id.toString();
      if (!kIsWeb) await _local.update('templates', {'isDeleted': 1}, sid);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && templatesRef != null) await templatesRef!.doc(sid).delete();
    } catch (e) {}
  }

  Future<void> createTemplateFromTransaction(TransactionModel t) async {
    try {
      final data = {'title': t.title, 'currency': t.currency, 'dueDay': t.dueDate?.day ?? t.date.day, 'type': t.type, 'category': t.category == 'Extra' ? (t.type == 'EXPENSE' ? 'Fijo' : 'Ingreso') : t.category, 'isCreditCard': 0, 'defaultAmount': t.amount, 'brandLogo': t.brandLogo};
      await addTemplate(data);
    } catch (e) {}
  }

  Future<void> upgradeTemplateToBimonetary({required String originalId, required String oldTitle, required Map<String, dynamic> data, String? existingGemelaId, String? oldGemelaTitle}) async {}
}
