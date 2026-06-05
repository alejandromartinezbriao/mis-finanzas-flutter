import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';
import '../../models/balance_model.dart';

mixin BalanceService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- BALANCES (PULL SYNC) ---

  Future<void> syncBalancesFromCloud() async {
    try {
      final ref = balancesRef;
      if (ref == null || kIsWeb) return;

      final snap = await ref.orderBy('orderIndex').get();
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((doc) => BalanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id).toLocalMap()).toList();
        await _local.insertBatch('balances', items);
      }
    } catch (e) { print("Error syncing balances: $e"); }
  }

  // --- BALANCES (OPERACIONES) ---

  Stream<List<Map<String, dynamic>>> getBalances() {
    if (kIsWeb) {
      final ref = balancesRef; if (ref == null) return Stream.value([]);
      // REPARACIÓN ORDEN WEB: Forzamos el orden por índice
      return ref.orderBy('orderIndex').snapshots().map((snap) => 
        snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList()
      );
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    void load() async {
      try {
        final list = await _local.query('balances', orderBy: 'orderIndex ASC, accountName ASC');
        if (!controller.isClosed) controller.add(list);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }
    load();
    final sub = _local.onTableChanged.where((t) => t == 'balances').listen((_) => load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Future<void> updateBalance(String id, double amount) async {
    try {
      final String sid = id.toString();
      if (!kIsWeb) await _local.update('balances', {'amount': round(amount), 'updatedAt': DateTime.now().toIso8601String()}, sid);
      final premium = await checkPremium();
      if (kIsWeb || premium) {
        await balancesRef?.doc(sid).update({'amount': round(amount), 'updatedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {}
  }

  Future<void> addBalanceAccount(String name, String currency, {String? logo, String type = 'BANK', bool isBimonetary = false, bool includeInCoverage = true}) async {
    try {
      final ref = balancesRef; if (ref == null) return;
      int nextIndex = 0;
      final all = await _local.query('balances');
      for (var b in all) { if ((b['orderIndex'] ?? 0) >= nextIndex) nextIndex = (b['orderIndex'] ?? 0) + 1; }

      Future<void> create(Map<String, dynamic> data) async {
        final String tid = DateTime.now().millisecondsSinceEpoch.toString();
        if (!kIsWeb) await _local.insert('balances', {...data, 'id': tid, 'syncStatus': 'synced'});
        final premium = await checkPremium();
        if (kIsWeb || premium) {
          final doc = await ref.add(data);
          if (!kIsWeb) {
            await _local.delete('balances', tid);
            await _local.insert('balances', {...data, 'id': doc.id, 'syncStatus': 'synced'});
          }
        }
      }

      if (isBimonetary) {
        await create({'accountName': '$name (UYU)', 'amount': 0.0, 'currency': 'UYU', 'accountType': type, 'brandLogo': logo, 'orderIndex': nextIndex, 'isBimonetaryPart': 1, 'baseName': name, 'includeInCoverage': includeInCoverage ? 1 : 0});
        await create({'accountName': '$name (USD)', 'amount': 0.0, 'currency': 'USD', 'accountType': type, 'brandLogo': logo, 'orderIndex': nextIndex + 1, 'isBimonetaryPart': 1, 'baseName': name, 'includeInCoverage': includeInCoverage ? 1 : 0});
      } else {
        await create({'accountName': name, 'amount': 0.0, 'currency': currency, 'accountType': type, 'brandLogo': logo, 'orderIndex': nextIndex, 'includeInCoverage': includeInCoverage ? 1 : 0});
      }
    } catch (e) {}
  }

  Future<void> deleteBalanceAccount(String id) async {
    try {
      final String sid = id.toString();
      if (!kIsWeb) await _local.delete('balances', sid);
      final premium = await checkPremium();
      if (kIsWeb || premium) await balancesRef?.doc(sid).delete();
    } catch (e) {}
  }

  Future<void> updateBalancesOrder(List<Map<String, dynamic>> balances) async {
    try {
      final premium = await checkPremium();
      final batch = (kIsWeb || premium) ? db.batch() : null;

      for (int i = 0; i < balances.length; i++) {
        final String id = balances[i]['id'].toString();
        if (!kIsWeb) await _local.update('balances', {'orderIndex': i}, id, silent: true);
        if (batch != null && balancesRef != null) {
          batch.update(balancesRef!.doc(id), {'orderIndex': i});
        }
      }
      
      if (batch != null) await batch.commit();
      if (!kIsWeb) _local.notify('balances');
    } catch (e) { print("Error updateBalancesOrder: $e"); }
  }
  
  Future<void> updateBalanceAccountDetails(String id, Map<String, dynamic> data) async {
    try {
      final String sid = id.toString();
      if (!kIsWeb) await _local.update('balances', data, sid);
      final premium = await checkPremium();
      if (kIsWeb || premium) await balancesRef?.doc(sid).update(data);
    } catch (e) {}
  }

  Future<void> upgradeAccountToBimonetary({required String originalId, required String baseName, required String type, required String? logo, required double currentAmount, required String originalCurrency, String? existingGemelaId, bool includeInCoverage = true}) async {}
}
