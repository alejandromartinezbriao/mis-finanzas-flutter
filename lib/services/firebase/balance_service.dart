import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';

mixin BalanceService on FirebaseBase {
  // --- BALANCES REALES (ARQUEO) ---

  Stream<List<Map<String, dynamic>>> getBalances() {
    final ref = balancesRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Ordenar en memoria por orderIndex para evitar requerir índices compuestos en Firestore
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
      await ref.doc(id).update({
        'amount': round(amount),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error updateBalance: $e");
    }
  }

  Future<void> updateBalanceAccountDetails(String id, Map<String, dynamic> data) async {
    try {
      final ref = balancesRef;
      if (ref == null) return;
      await ref.doc(id).update(data);
    } catch (e) {
      print("Error updateBalanceAccountDetails: $e");
    }
  }

  Future<void> addBalanceAccount(String name, String currency, {String? logo, String type = 'BANK', bool isBimonetary = false, bool includeInCoverage = true}) async {
    try {
      final ref = balancesRef;
      if (ref == null) return;

      // Obtener el último índice (En memoria para evitar problemas de índices en Web)
      final all = await ref.get();
      int nextIndex = 0;
      for (var doc in all.docs) {
        final idx = (doc.data() as Map<String, dynamic>)['orderIndex'] ?? 0;
        if (idx >= nextIndex) nextIndex = idx + 1;
      }

      if (isBimonetary) {
        final batch = db.batch();
        
        // Registro UYU
        batch.set(ref.doc(), {
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
        });

        // Registro USD
        batch.set(ref.doc(), {
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
        });

        await batch.commit();
      } else {
        await ref.add({
          'accountName': name,
          'amount': 0.0,
          'currency': currency,
          'accountType': type,
          'updatedAt': Timestamp.now(),
          'brandLogo': logo,
          'orderIndex': nextIndex,
          'includeInCoverage': includeInCoverage,
        });
      }
    } catch (e) {
      print("Error addBalanceAccount: $e");
    }
  }

  Future<void> deleteBalanceAccount(String id) async {
    try {
      final ref = balancesRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteBalanceAccount: $e");
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
      
      // Limpiar el nombre base de sufijos redundantes (pesos, dólares, etc)
      final cleanBaseName = baseName
          .replaceAll(RegExp(r'\s+(pesos|dólares|uyu|usd|dolares)$', caseSensitive: false), '')
          .trim();

      // 1. Actualizar la cuenta original
      // Forzamos que la cuenta original se asigne a su moneda correcta dentro del par
      batch.update(ref.doc(originalId), {
        'accountName': '$cleanBaseName ($originalCurrency)',
        'currency': originalCurrency,
        'isBimonetaryPart': true,
        'baseName': cleanBaseName,
        'accountType': type,
        'brandLogo': logo,
        'amount': currentAmount, // PRESERVAR SALDO ORIGINAL
        'includeInCoverage': includeInCoverage,
      });

      // 2. Manejar la cuenta gemela
      final otherCurrency = originalCurrency == 'UYU' ? 'USD' : 'UYU';

      if (existingGemelaId != null) {
        // VINCULAR EXISTENTE
        batch.update(ref.doc(existingGemelaId), {
          'accountName': '$cleanBaseName ($otherCurrency)',
          'currency': otherCurrency,
          'isBimonetaryPart': true,
          'baseName': cleanBaseName,
          'accountType': type,
          'brandLogo': logo,
          'includeInCoverage': includeInCoverage,
          // No tocamos su amount porque ya tiene el suyo propio
        });
      } else {
        // CREAR NUEVA
        batch.set(ref.doc(), {
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
    } catch (e) {
      print("Error upgradeAccountToBimonetary: $e");
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
      }

      await batch.commit();
    } catch (e) {
      print("Error updateBalancesOrder: $e");
    }
  }
}
