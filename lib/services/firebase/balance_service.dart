import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';
import '../../models/balance_model.dart';

mixin BalanceService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- BALANCES (SMARTER PULL v4.1.1) ---

  Future<void> syncBalancesFromCloud() async {
    try {
      if (kIsWeb) return;
      final String uid = currentUid;
      if (uid.isEmpty) return;

      List<BalanceModel> cloudItems = [];
      
      // 1. Descargar de la nube
      final myRef = balancesRef;
      if (myRef != null) {
        final mySnap = await myRef.get();
        cloudItems.addAll(mySnap.docs.map((doc) => BalanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      final String? fid = await getMyFamilyId();
      if (fid != null && fid != uid) {
        final famRef = db.collection('users').doc(fid).collection('balances');
        final famSnap = await famRef.where('familyId', isEqualTo: fid).get();
        cloudItems.addAll(famSnap.docs.map((doc) => BalanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      // 2. COMPARACIÓN INTELIGENTE (No pisar si el local es más nuevo)
      for (var cloud in cloudItems) {
        final localData = await _local.query('balances', where: 'id = ?', whereArgs: [cloud.id]);
        
        if (localData.isNotEmpty) {
          final local = BalanceModel.fromMap(localData.first, cloud.id);
          
          // BLINDAJE: Si el dato local está pendiente de sincronizar o es más nuevo, NO lo tocamos
          if (local.syncStatus == 'pending') continue;
          if (local.updatedAt.isAfter(cloud.updatedAt)) continue;
        }
        
        // Solo insertamos si pasó los filtros de seguridad
        await _local.insert('balances', cloud.toLocalMap(), silent: true);
      }
      _local.notify('balances');
    } catch (e) { print("Error syncing balances: $e"); }
  }

  // --- BALANCES (OPERACIONES) ---

  Stream<List<Map<String, dynamic>>> getBalances() {
    final String uid = currentUid;
    if (kIsWeb) {
      final ref = balancesRef; if (ref == null) return Stream.value([]);
      final myStream = ref.orderBy('orderIndex').snapshots().map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
      return db.collection('users').doc(uid).snapshots().asyncExpand((userDoc) {
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final String? familyId = userData['familyId'];
        if (familyId == null) return myStream;
        Query sharedQuery = db.collectionGroup('balances').where('familyId', isEqualTo: familyId);
        return sharedQuery.snapshots().map((sharedSnap) {
          final sharedItems = sharedSnap.docs.where((d) => d.reference.parent.parent?.id != uid).map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
          return myStream.map((myItems) => [...myItems, ...sharedItems]);
        }).asyncExpand((s) => s);
      });
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
      final double roundedAmount = round(amount);
      final DateTime now = DateTime.now();
      String? familyId;

      if (!kIsWeb) {
        final localData = await _local.query('balances', where: 'id = ?', whereArgs: [sid]);
        if (localData.isNotEmpty) familyId = localData.first['familyId'];
        
        // Marcamos como 'pending' hasta que la nube confirme
        await _local.update('balances', {
          'amount': roundedAmount, 
          'updatedAt': now.toIso8601String(),
          'syncStatus': 'pending'
        }, sid);
      }

      final premium = await checkPremium();
      if (kIsWeb || premium) {
        final ref = getDocRef('balances', sid, familyId: familyId);
        await ref?.update({
          'amount': roundedAmount, 
          'updatedAt': FieldValue.serverTimestamp()
        });
        
        // Si llegamos aquí, la nube aceptó el cambio
        if (!kIsWeb) await _local.update('balances', {'syncStatus': 'synced'}, sid);
      }
    } catch (e) { print("Error updating balance: $e"); }
  }

  Future<void> addBalanceAccount(String name, String currency, {String? logo, String type = 'BANK', bool isBimonetary = false, bool includeInCoverage = true, String? familyId}) async {
    try {
      final ref = balancesRef; if (ref == null) return;
      int nextIndex = 0;
      final all = await _local.query('balances');
      for (var b in all) { if ((b['orderIndex'] ?? 0) >= nextIndex) nextIndex = (b['orderIndex'] ?? 0) + 1; }

      Future<void> create(Map<String, dynamic> data) async {
        final String tid = DateTime.now().millisecondsSinceEpoch.toString();
        if (!kIsWeb) await _local.insert('balances', {...data, 'id': tid, 'syncStatus': 'pending', 'updatedAt': DateTime.now().toIso8601String()});
        final premium = await checkPremium();
        if (kIsWeb || premium) {
          final doc = await ref.add({...data, 'updatedAt': FieldValue.serverTimestamp()});
          if (!kIsWeb) {
            await _local.delete('balances', tid);
            await _local.insert('balances', {...data, 'id': doc.id, 'syncStatus': 'synced', 'updatedAt': DateTime.now().toIso8601String()});
          }
        }
      }
      final Map<String, dynamic> baseData = {'accountType': type, 'brandLogo': logo, 'includeInCoverage': includeInCoverage ? 1 : 0, 'familyId': familyId};
      if (isBimonetary) {
        await create({...baseData, 'accountName': '$name (UYU)', 'amount': 0.0, 'currency': 'UYU', 'orderIndex': nextIndex, 'isBimonetaryPart': 1, 'baseName': name});
        await create({...baseData, 'accountName': '$name (USD)', 'amount': 0.0, 'currency': 'USD', 'orderIndex': nextIndex + 1, 'isBimonetaryPart': 1, 'baseName': name});
      } else {
        await create({...baseData, 'accountName': name, 'amount': 0.0, 'currency': currency, 'orderIndex': nextIndex});
      }
    } catch (e) {}
  }

  Future<void> deleteBalanceAccount(String id) async {
    try {
      final String sid = id.toString();
      String? familyId;
      if (!kIsWeb) {
        final localData = await _local.query('balances', where: 'id = ?', whereArgs: [sid]);
        if (localData.isNotEmpty) familyId = localData.first['familyId'];
        await _local.delete('balances', sid);
      }
      final premium = await checkPremium();
      if (kIsWeb || premium) await getDocRef('balances', sid, familyId: familyId)?.delete();
    } catch (e) {}
  }

  Future<void> updateBalancesOrder(List<Map<String, dynamic>> balances) async {
    try {
      final premium = await checkPremium();
      final batch = (kIsWeb || premium) ? db.batch() : null;
      for (int i = 0; i < balances.length; i++) {
        final String id = balances[i]['id'].toString();
        final String? fId = balances[i]['familyId'];
        if (!kIsWeb) await _local.update('balances', {'orderIndex': i}, id, silent: true);
        if (batch != null) {
          final ref = getDocRef('balances', id, familyId: fId);
          if (ref != null) batch.update(ref, {'orderIndex': i});
        }
      }
      if (batch != null) await batch.commit();
      if (!kIsWeb) _local.notify('balances');
    } catch (e) { print("Error updateBalancesOrder: $e"); }
  }
  
  Future<void> updateBalanceAccountDetails(String id, Map<String, dynamic> data) async {
    try {
      final String sid = id.toString();
      final String? fId = data['familyId'];
      if (!kIsWeb) await _local.update('balances', data, sid);
      final premium = await checkPremium();
      if (kIsWeb || premium) await getDocRef('balances', sid, familyId: fId)?.update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {}
  }
}
