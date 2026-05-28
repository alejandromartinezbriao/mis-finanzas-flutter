import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';

mixin BalanceService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- BALANCES REALES (ARQUEO) ---

  Stream<List<Map<String, dynamic>>> getBalances() {
    final ref = balancesRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Sync local cache
        if (!kIsWeb) {
          _local.insert('balances', data);
        }
        
        return data;
      }).toList();
      
      list.sort((a, b) {
        int aIdx = a['orderIndex'] ?? 999;
        int bIdx = b['orderIndex'] ?? 999;
        if (aIdx != bIdx) return aIdx.compareTo(bIdx);
        return (a['accountName'] as String).toLowerCase().compareTo((b['accountName'] as String).toLowerCase());
      });
      
      return list;
    });
  }

  Future<void> updateBalance(String id, double amount) async {
    try {
      final ref = balancesRef;
      if (ref == null) return;
      
      final data = {
        'amount': round(amount),
        'updatedAt': Timestamp.now(),
      };

      await ref.doc(id).update(data);
      
      if (!kIsWeb) {
        await _local.update('balances', {
          'amount': data['amount'],
          'updatedAt': (data['updatedAt'] as Timestamp).toDate().toIso8601String(),
        }, id);
      }
    } catch (e) {
      print("Error updateBalance Híbrido: $e");
    }
  }

  Future<void> updateBalanceAccountDetails(String id, Map<String, dynamic> data) async {
    try {
      if (balancesRef != null) await balancesRef!.doc(id).update(data);
      if (!kIsWeb) await _local.update('balances', data, id);
    } catch (e) {
      print("Error updateBalanceAccountDetails Híbrido: $e");
    }
  }

  Future<void> addBalanceAccount(String name, String currency, {String? logo, String type = 'BANK', bool isBimonetary = false, bool includeInCoverage = true}) async {
    try {
      final ref = balancesRef;
      if (ref == null) return;

      final all = await ref.get();
      int nextIndex = 0;
      for (var doc in all.docs) {
        final idx = (doc.data() as Map<String, dynamic>)['orderIndex'] ?? 0;
        if (idx >= nextIndex) nextIndex = idx + 1;
      }

      if (isBimonetary) {
        final batch = db.batch();
        
        final docUYU = ref.doc();
        final dataUYU = {
          'accountName': '$name (UYU)',
          'amount': 0.0,
          'currency': 'UYU',
          'accountType': type,
          'updatedAt': Timestamp.now(),
          'brandLogo': logo,
          'orderIndex': nextIndex,
          'isBimonetaryPart': true,
          'baseName': name,
          'includeInCoverage': includeInCoverage,
        };
        batch.set(docUYU, dataUYU);

        final docUSD = ref.doc();
        final dataUSD = {
          'accountName': '$name (USD)',
          'amount': 0.0,
          'currency': 'USD',
          'accountType': type,
          'updatedAt': Timestamp.now(),
          'brandLogo': logo,
          'orderIndex': nextIndex + 1,
          'isBimonetaryPart': true,
          'baseName': name,
          'includeInCoverage': includeInCoverage,
        };
        batch.set(docUSD, dataUSD);

        await batch.commit();

        if (!kIsWeb) {
          await _local.insert('balances', {...dataUYU, 'id': docUYU.id, 'updatedAt': dataUYU['updatedAt'].toString()});
          await _local.insert('balances', {...dataUSD, 'id': docUSD.id, 'updatedAt': dataUSD['updatedAt'].toString()});
        }
      } else {
        final docRef = await ref.add({
          'accountName': name,
          'amount': 0.0,
          'currency': currency,
          'accountType': type,
          'updatedAt': Timestamp.now(),
          'brandLogo': logo,
          'orderIndex': nextIndex,
          'includeInCoverage': includeInCoverage,
        });

        if (!kIsWeb) {
          final doc = await docRef.get();
          await _local.insert('balances', {...doc.data() as Map<String, dynamic>, 'id': docRef.id});
        }
      }
    } catch (e) {
      print("Error addBalanceAccount Híbrido: $e");
    }
  }

  Future<void> deleteBalanceAccount(String id) async {
    try {
      if (balancesRef != null) await balancesRef!.doc(id).delete();
      if (!kIsWeb) await _local.delete('balances', id);
    } catch (e) {
      print("Error deleteBalanceAccount Híbrido: $e");
    }
  }

  Future<void> upgradeAccountToBimonetary({
    required String originalId,
    required String baseName,
    required String type,
    required String? logo,
    required double currentAmount,
    required String originalCurrency,
    String? existingGemelaId,
    bool includeInCoverage = true,
  }) async {
    try {
      final ref = balancesRef;
      if (ref == null) return;

      final batch = db.batch();
      final cleanBaseName = baseName.replaceAll(RegExp(r'\s+(pesos|dólares|uyu|usd|dolares)$', caseSensitive: false), '').trim();

      final dataOrig = {
        'accountName': '$cleanBaseName ($originalCurrency)',
        'currency': originalCurrency,
        'isBimonetaryPart': true,
        'baseName': cleanBaseName,
        'accountType': type,
        'brandLogo': logo,
        'amount': currentAmount,
        'includeInCoverage': includeInCoverage,
      };
      batch.update(ref.doc(originalId), dataOrig);

      final otherCurrency = originalCurrency == 'UYU' ? 'USD' : 'UYU';
      String? gemelaId = existingGemelaId;

      if (gemelaId != null) {
        final dataGemela = {
          'accountName': '$cleanBaseName ($otherCurrency)',
          'currency': otherCurrency,
          'isBimonetaryPart': true,
          'baseName': cleanBaseName,
          'accountType': type,
          'brandLogo': logo,
          'includeInCoverage': includeInCoverage,
        };
        batch.update(ref.doc(gemelaId), dataGemela);
      } else {
        final newDoc = ref.doc();
        gemelaId = newDoc.id;
        batch.set(newDoc, {
          'accountName': '$cleanBaseName ($otherCurrency)',
          'amount': 0.0,
          'currency': otherCurrency,
          'accountType': type,
          'updatedAt': Timestamp.now(),
          'brandLogo': logo,
          'orderIndex': 999,
          'isBimonetaryPart': true,
          'baseName': cleanBaseName,
          'includeInCoverage': includeInCoverage,
        });
      }

      await batch.commit();

      if (!kIsWeb) {
        await _local.update('balances', dataOrig, originalId);
        final gemDoc = await ref.doc(gemelaId).get();
        await _local.insert('balances', {...gemDoc.data() as Map<String, dynamic>, 'id': gemelaId});
      }
    } catch (e) {
      print("Error upgradeAccountToBimonetary Híbrido: $e");
      rethrow;
    }
  }

  Future<void> updateBalancesOrder(List<Map<String, dynamic>> balances) async {
    try {
      final batch = db.batch();
      final ref = balancesRef;
      if (ref == null) return;

      for (int i = 0; i < balances.length; i++) {
        final String balanceId = balances[i]['id'];
        batch.update(ref.doc(balanceId), {'orderIndex': i});
        if (!kIsWeb) {
          await _local.update('balances', {'orderIndex': i}, balanceId);
        }
      }
      await batch.commit();
    } catch (e) {
      print("Error updateBalancesOrder Híbrido: $e");
    }
  }
}
