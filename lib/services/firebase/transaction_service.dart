import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_base.dart';
import '../../models/transaction_model.dart';
import '../local_db_service.dart';

mixin TransactionService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- AYUDANTE HÍBRIDO (TRADUCTOR SQLITE) ---

  Future<void> _saveTransactionLocally(TransactionModel t, {String? docId}) async {
    if (kIsWeb) return;
    try {
      final String idToUse = docId ?? (t.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : t.id);
      
      final Map<String, dynamic> localData = {
        'id': idToUse,
        'title': t.title,
        'description': t.description,
        'amount': t.amount,
        'currency': t.currency,
        'date': t.date.toIso8601String(),
        'category': t.category,
        'type': t.type,
        'isCompleted': t.isCompleted ? 1 : 0,
        'brandLogo': t.brandLogo,
        'categoryColor': t.categoryColor,
        'includedInCard': t.includedInCard ? 1 : 0,
        'templateId': t.templateId,
        'paidFromAccountId': t.paidFromAccountId,
      };

      await _local.insert('transactions', localData);
    } catch (e) {
      print("Error silenciado en _saveTransactionLocally: $e");
    }
  }

  // --- TRANSACCIONES ---

  Future<void> addTransaction(TransactionModel t) async {
    try {
      final String docId = transactionsRef?.doc().id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // 1. LOCAL PRIMERO (Instantáneo)
      await _saveTransactionLocally(t, docId: docId);

      // 2. NUBE EN SEGUNDO PLANO (Sin 'await' para no bloquear la UI)
      isPremium.then((premium) {
        if (kIsWeb || premium) {
          transactionsRef?.doc(docId).set(t.toMap());
        }
      });
    } catch (e) {
      print("Error addTransaction Híbrido: $e");
    }
  }

  Future<void> addTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    String? accountId,
  }) async {
    try {
      final String docId = transactionsRef?.doc().id ?? DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Local primero
      await _saveTransactionLocally(transaction, docId: docId);

      // 2. Ejecutar balance y nube (aquí sí esperamos porque el balance es crítico)
      final bool premium = await isPremium;
      if (kIsWeb || premium) {
        final batch = db.batch();
        final transRef = transactionsRef!.doc(docId);
        
        batch.set(transRef, {
          ...transaction.toMap(),
          'paidFromAccountId': accountId,
        });

        if (accountId != null) {
          final accountRef = balancesRef!.doc(accountId);
          final accountDoc = await accountRef.get(GetOptions(source: Source.serverAndCache));
          
          if (accountDoc.exists) {
            final accData = accountDoc.data() as Map<String, dynamic>;
            double currentBalance = (accData['amount'] ?? 0.0).toDouble();
            double newBalance = transaction.type == 'INCOME' 
                ? currentBalance + transaction.amount 
                : currentBalance - transaction.amount;
            
            batch.update(accountRef, {
              'amount': round(newBalance),
              'updatedAt': Timestamp.now(),
            });
            
            // Actualizar balance local también
            if (!kIsWeb) await _local.update('balances', {'amount': round(newBalance)}, accountId);
          }
        }
        await batch.commit();
      }
    } catch (e) {
      print("Error addTransactionWithBalanceUpdate Híbrido: $e");
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel t) async {
    try {
      if (!kIsWeb) {
        await _local.update('transactions', {
          'title': t.title,
          'amount': t.amount,
          'category': t.category,
          'isCompleted': t.isCompleted ? 1 : 0,
        }, t.id);
      }

      isPremium.then((premium) {
        if ((kIsWeb || premium) && transactionsRef != null) {
          transactionsRef!.doc(t.id).update(t.toMap());
        }
      });
    } catch (e) {
      print("Error updateTransaction Híbrido: $e");
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      if (!kIsWeb) await _local.delete('transactions', id);
      isPremium.then((premium) {
        if ((kIsWeb || premium) && transactionsRef != null) {
          transactionsRef!.doc(id).delete();
        }
      });
    } catch (e) {
      print("Error deleteTransaction Híbrido: $e");
    }
  }

  Stream<List<TransactionModel>> getTransactions({int? month, int? year}) {
    final ref = transactionsRef;
    if (ref == null) return Stream.value([]);

    Query query = ref;
    if (month != null && year != null) {
      DateTime start = DateTime(year, month, 1);
      DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    return query.snapshots().map((snapshot) {
      final txs = snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      if (!kIsWeb) {
        for (var tx in txs) { _saveTransactionLocally(tx); }
      }
      return txs;
    });
  }

  Stream<List<TransactionModel>> getTransactionsInRange(DateTime start, DateTime end) {
    final ref = transactionsRef;
    if (ref == null) return Stream.value([]);

    return ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Future<void> clearMonth(int month, int year) async {
    try {
      final ref = transactionsRef;
      if (ref == null) return;
      DateTime start = DateTime(year, month, 1);
      DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
      
      final snapshot = await ref
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final batch = db.batch();
      int deletedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        bool isFromTemplate = data['generatedBy'] == 'template';
        String desc = (data['description'] ?? '').toString().toLowerCase();
        bool isInstallment = desc.contains('cuota') || desc.contains('/');
        bool isCard = data['category'] == 'Tarjeta';

        if ((isFromTemplate && !isCard) || (!isInstallment && data['category'] != 'Otros' && !isCard)) {
          batch.delete(doc.reference);
          if (!kIsWeb) await _local.delete('transactions', doc.id);
          deletedCount++;
        }
      }
      
      if (deletedCount > 0) await batch.commit();
    } catch (e) {
      print("Error clearMonth: $e");
    }
  }

  Future<void> completeTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    required String accountId,
    required bool isUndoing,
  }) async {
    try {
      final batch = db.batch();
      final transRef = transactionsRef!.doc(transaction.id);
      final accountRef = balancesRef!.doc(accountId);

      final updateData = {
        'isCompleted': !isUndoing, 
        'isPaid': !isUndoing,
        'paidFromAccountId': isUndoing ? null : accountId,
      };

      batch.update(transRef, updateData);

      final accountDoc = await accountRef.get(GetOptions(source: Source.serverAndCache));
      if (!accountDoc.exists) return;
      
      final accData = accountDoc.data() as Map<String, dynamic>;
      double currentBalance = (accData['amount'] ?? 0.0).toDouble();
      double transactionAmount = transaction.amount;
      
      double newBalance = transaction.type == 'EXPENSE'
          ? (isUndoing ? currentBalance + transactionAmount : currentBalance - transactionAmount)
          : (isUndoing ? currentBalance - transactionAmount : currentBalance + transactionAmount);

      batch.update(accountRef, {
        'amount': round(newBalance),
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
      
      if (!kIsWeb) {
        await _local.update('transactions', {
          'isCompleted': isUndoing ? 0 : 1,
          'paidFromAccountId': isUndoing ? null : accountId,
        }, transaction.id);
        await _local.update('balances', {'amount': round(newBalance)}, accountId);
      }
    } catch (e) {
      print("Error completeTransactionWithBalanceUpdate: $e");
      rethrow;
    }
  }

  Future<void> generateMonthlyTransactions(int month, int year) async {
    try {
      final refT = templatesRef;
      final refE = transactionsRef;
      final refS = subscriptionsRef;
      if (refT == null || refE == null || refS == null) return;

      final templatesDocs = await refT.get();
      final subsDocs = await refS.get();

      final startQuery = DateTime(year, month, 1).subtract(const Duration(days: 2));
      final endQuery = DateTime(year, month + 1, 1).add(const Duration(days: 2));
      
      final existingDocsSnap = await refE
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startQuery))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endQuery))
          .get();

      final List<Map<String, dynamic>> existingInMonth = existingDocsSnap.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id, 'ref': doc.reference})
          .where((d) {
            final DateTime dt = (d['date'] as Timestamp).toDate();
            return dt.month == month && dt.year == year;
          }).toList();
      
      final Set<String> processedKeysInThisRun = {};
      final batch = db.batch();
      bool addedAny = false;

      for (var docT in templatesDocs.docs) {
        final dataT = docT.data() as Map<String, dynamic>;
        if (dataT['type'] == null || dataT['title'] == null || dataT['title'].toString().isEmpty) continue; 

        final String templateId = docT.id;
        final String titleT = dataT['title'];
        final String currencyT = dataT['currency'] ?? 'UYU';
        final String uniqueKey = "${norm(titleT)}_$currencyT";
        final int oIndex = dataT['orderIndex'] ?? 999;
        
        if (processedKeysInThisRun.contains(uniqueKey)) continue;

        final String cleanTitleT = titleT.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
        
        final existingBase = existingInMonth.where((e) {
          bool matchId = e['templateId'] == templateId;
          final String eTitle = (e['title'] ?? '').toString();
          final String cleanETitle = eTitle.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
          return matchId || (norm(cleanETitle) == norm(cleanTitleT) && e['currency'] == currencyT);
        }).firstOrNull;

        final cardSubs = subsDocs.docs.where((s) => (s.data() as Map<String, dynamic>)['linkId'] == templateId);
        double totalSubsForThisCard = 0;
        List<String> subDetails = [];

        for (var docS in cardSubs) {
          final dataS = docS.data() as Map<String, dynamic>;
          if (dataS['currency'] != currencyT) continue;
          final double subAmount = (dataS['amount'] ?? 0.0).toDouble();
          totalSubsForThisCard += subAmount;
          subDetails.add("${dataS['name'] ?? 'Sub'} (${formatAmount(subAmount, currencyT)})");

          if (existingInMonth.where((e) => e['subscriptionId'] == docS.id).isEmpty) {
            final newId = refE.doc().id;
            final dataMap = {
              'subscriptionId': docS.id,
              'templateId': templateId,
              'title': dataS['name'] ?? 'Sub',
              'amount': round(subAmount),
              'date': Timestamp.fromDate(DateTime(year, month, 1, 12, 0, 5)),
              'category': 'Suscripción',
              'currency': currencyT,
              'isCompleted': false,
              'type': 'EXPENSE',
              'includedInCard': true,
              'generatedBy': 'template',
              'brandLogo': dataT['brandLogo'],
              'orderIndex': oIndex,
            };
            batch.set(refE.doc(newId), dataMap);
            if (!kIsWeb) await _local.insert('transactions', {...dataMap, 'id': newId, 'date': (dataMap['date'] as Timestamp).toDate().toIso8601String(), 'isCompleted': 0, 'includedInCard': 1});
            addedAny = true;
          }
        }

        if (existingBase == null) {
          final newId = refE.doc().id;
          double initialAmount = (dataT['defaultAmount'] ?? 0.0).toDouble();
          final dataMap = {
            'templateId': templateId,
            'title': titleT,
            'amount': round(initialAmount + totalSubsForThisCard),
            'description': subDetails.isNotEmpty ? "Suscripciones: ${subDetails.join(', ')}" : null,
            'date': Timestamp.fromDate(DateTime(year, month, 1, 12, 0, 0)),
            'dueDate': dataT['dueDay'] != null ? Timestamp.fromDate(DateTime(year, month, dataT['dueDay'])) : null,
            'category': dataT['category'] ?? (dataT['type'] == 'INCOME' ? 'Ingreso' : 'Fijo'),
            'currency': currencyT,
            'isCompleted': false,
            'type': dataT['type'] ?? 'EXPENSE',
            'brandLogo': dataT['brandLogo'],
            'generatedBy': 'template',
            'orderIndex': oIndex,
          };
          batch.set(refE.doc(newId), dataMap);
          if (!kIsWeb) await _local.insert('transactions', {...dataMap, 'id': newId, 'date': (dataMap['date'] as Timestamp).toDate().toIso8601String(), 'isCompleted': 0, 'includedInCard': 0});
          addedAny = true;
        } else {
          final dataE = existingBase;
          double currentAmount = (dataE['amount'] ?? 0.0).toDouble();
          String currentDesc = dataE['description'] ?? '';
          
          if (totalSubsForThisCard > 0 && !currentDesc.contains('Suscripciones:')) {
            final updateData = {
              'templateId': templateId,
              'title': titleT,
              'amount': round(currentAmount + totalSubsForThisCard),
              'description': currentDesc.isEmpty 
                  ? "Suscripciones: ${subDetails.join(', ')}" 
                  : "$currentDesc, Suscripciones: ${subDetails.join(', ')}",
              'orderIndex': oIndex,
              'brandLogo': dataT['brandLogo'],
            };
            batch.update(dataE['ref'], updateData);
            if (!kIsWeb) await _local.update('transactions', updateData, dataE['id']);
          } else {
            final updateData = {
              'templateId': templateId,
              'title': titleT,
              'orderIndex': oIndex,
              'brandLogo': dataT['brandLogo'],
            };
            batch.update(dataE['ref'], updateData);
            if (!kIsWeb) await _local.update('transactions', updateData, dataE['id']);
          }
          addedAny = true;
        }
      }

      for (var docS in subsDocs.docs) {
        final dataS = docS.data() as Map<String, dynamic>;
        if (dataS['linkType'] != 'ACCOUNT' && dataS['linkId'] != null) continue;
        final String name = dataS['name'] ?? 'Suscripción';
        final String currencyS = dataS['currency'] ?? 'UYU';
        if (existingInMonth.where((e) => e['subscriptionId'] == docS.id).isEmpty) {
          final newId = refE.doc().id;
          final dataMap = {
            'subscriptionId': docS.id,
            'title': name,
            'amount': round((dataS['amount'] ?? 0.0).toDouble()),
            'date': Timestamp.fromDate(DateTime(year, month, 1, 12, 0, 0)),
            'category': dataS['category'] ?? 'Suscripción',
            'currency': currencyS,
            'isCompleted': false,
            'type': 'EXPENSE',
            'generatedBy': 'template',
            'orderIndex': 998,
          };
          batch.set(refE.doc(newId), dataMap);
          if (!kIsWeb) await _local.insert('transactions', {...dataMap, 'id': newId, 'date': (dataMap['date'] as Timestamp).toDate().toIso8601String(), 'isCompleted': 0, 'includedInCard': 0});
          addedAny = true;
        }
      }

      if (addedAny) await batch.commit();
    } catch (e) {
      print("Error generateMonthlyTransactions: $e");
    }
  }

  Future<void> addCreditCardExpense({
    required String cardName,
    required double totalAmount,
    required int installments,
    required String currency,
    required DateTime startDate,
    String? concept,
    String? category,
    String? categoryLogo,
    int? categoryColor,
    int initialInstallment = 1,
  }) async {
    try {
      final ref = transactionsRef;
      final tRef = templatesRef;
      if (ref == null || tRef == null) return;

      final templates = await tRef.get();
      final cardT = templates.docs.where((doc) => norm((doc.data() as Map<String, dynamic>)['title'] ?? '') == norm(cardName)).firstOrNull;
      
      String? cardLogo;
      int? cardColor;
      int? cardOrder;
      int? dueDay;
      String? templateId;
      if (cardT != null) {
        final d = cardT.data() as Map<String, dynamic>;
        cardLogo = d['brandLogo'];
        cardColor = d['categoryColor'];
        cardOrder = d['orderIndex'];
        dueDay = d['dueDay'];
        templateId = cardT.id;
      }

      final batch = db.batch();
      double amountPerMonth = round(totalAmount / installments);
      double totalAllocated = 0;

      if (initialInstallment > 1) {
        totalAllocated = round(amountPerMonth * (initialInstallment - 1));
      }

      for (int i = initialInstallment; i <= installments; i++) {
        double currentInstallmentAmount = amountPerMonth;
        if (i == installments) {
          currentInstallmentAmount = round(totalAmount - totalAllocated);
        }
        totalAllocated += currentInstallmentAmount;

        int monthOffset = i - initialInstallment;
        DateTime targetDate = DateTime(startDate.year, startDate.month + monthOffset, 1, 12, 0, 0);
        
        final snapshot = await ref.where('date', isEqualTo: Timestamp.fromDate(targetDate)).get();
        final existing = snapshot.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return norm(d['title'] ?? '') == norm(cardName) && d['currency'] == currency;
        }).firstOrNull;

        String detail = concept != null ? "$concept ($i/$installments) - ${formatAmount(currentInstallmentAmount, currency)}" : "Cuota $i/$installments - ${formatAmount(currentInstallmentAmount, currency)}";
        Timestamp? dueDateTs = dueDay != null ? Timestamp.fromDate(DateTime(targetDate.year, targetDate.month, dueDay)) : null;

        if (existing != null) {
          final d = existing.data() as Map<String, dynamic>;
          double currentAmount = (d['amount'] ?? 0.0).toDouble();
          String oldDesc = d['description'] ?? '';
          final updateData = {
            'amount': round(currentAmount + currentInstallmentAmount), 
            'description': oldDesc.isEmpty ? detail : "$oldDesc, $detail",
            'brandLogo': cardLogo ?? categoryLogo,
            'categoryColor': cardColor ?? categoryColor,
            'orderIndex': cardOrder ?? 999,
          };
          batch.update(existing.reference, updateData);
          if (!kIsWeb) await _local.update('transactions', updateData, existing.id);
        } else {
          final newId = ref.doc().id;
          final dataMap = {
            'title': cardName,
            'description': detail,
            'amount': round(currentInstallmentAmount),
            'date': Timestamp.fromDate(targetDate),
            'dueDate': dueDateTs,
            'category': category ?? 'Tarjeta',
            'currency': currency,
            'type': 'EXPENSE',
            'isCompleted': false,
            'brandLogo': cardLogo ?? categoryLogo,
            'categoryColor': cardColor ?? categoryColor,
            'orderIndex': cardOrder ?? 999,
            'templateId': templateId,
          };
          batch.set(ref.doc(newId), dataMap);
          if (!kIsWeb) await _local.insert('transactions', {...dataMap, 'id': newId, 'date': targetDate.toIso8601String(), 'isCompleted': 0, 'includedInCard': 0});
        }
      }
      await batch.commit();
    } catch (e) {
      print("Error addCreditCardExpense: $e");
    }
  }

  Future<void> removeCreditCardExpense({required String cardName, required String fullItemText, required DateTime startDate}) async {
    try {
      final ref = transactionsRef;
      if (ref == null) return;
      final parts = fullItemText.split(' - ');
      if (parts.length < 2) return;
      final fullIdentifier = parts[0]; 
      String conceptBase = '';
      if (fullIdentifier.contains(' (')) {
        conceptBase = fullIdentifier.substring(0, fullIdentifier.lastIndexOf(' ('));
      } else if (fullIdentifier.startsWith('Cuota ')) {
        conceptBase = ''; 
      } else {
        conceptBase = fullIdentifier;
      }

      final batch = db.batch();
      bool changedAny = false;

      for (int i = 0; i < 36; i++) {
        DateTime targetDate = DateTime(startDate.year, startDate.month + i, 1, 12, 0, 0);
        final snapshot = await ref.where('date', isEqualTo: Timestamp.fromDate(targetDate)).get();
        final cardDoc = snapshot.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return norm(d['title'] ?? '') == norm(cardName);
        }).firstOrNull;

        if (cardDoc != null) {
          final data = cardDoc.data() as Map<String, dynamic>;
          String desc = data['description'] ?? '';
          List<String> items = desc.split(', ').where((s) => s.isNotEmpty).toList();
          bool itemsChanged = false;
          double removedSum = 0;
          final newItems = items.where((item) {
            final itemParts = item.split(' - ');
            if (itemParts.length < 2) return true;
            final itemIdentifier = itemParts[0];
            final double itemValue = parseAmount(itemParts[1]);
            bool shouldRemove = (itemIdentifier == fullIdentifier) || (conceptBase.isNotEmpty && itemIdentifier.startsWith("$conceptBase ("));
            if (shouldRemove) {
              itemsChanged = true;
              removedSum += itemValue;
              return false;
            }
            return true;
          }).toList();

          if (itemsChanged) {
            double currentTotal = (data['amount'] ?? 0.0).toDouble();
            double newTotal = currentTotal - removedSum;
            if (newTotal < 0.01) newTotal = 0;

            final updateData = {
              'description': newItems.join(', '), 
              'amount': round(newTotal)
            };
            batch.update(cardDoc.reference, updateData);
            if (!kIsWeb) await _local.update('transactions', updateData, cardDoc.id);
            changedAny = true;
          }
        }
      }
      if (changedAny) await batch.commit();
    } catch (e) {
      print("Error removeCreditCardExpense: $e");
    }
  }

  Future<void> unifyTransactions(List<TransactionModel> transactions, String baseName) async {
    try {
      if (transactions.length < 2) return;
      final ref = transactionsRef;
      if (ref == null) return;
      final batch = db.batch();
      final survivor = transactions.first;
      final String finalTitle = "$baseName (${survivor.currency})";
      double totalAmount = 0;
      List<String> descriptions = [];
      String? bestBrandLogo = survivor.brandLogo;
      String? bestTemplateId = survivor.templateId;
      int bestOrderIndex = survivor.orderIndex;

      for (var t in transactions) {
        totalAmount += t.amount;
        if (t.description != null && t.description!.isNotEmpty) descriptions.add(t.description!);
        if (bestBrandLogo == null && t.brandLogo != null) bestBrandLogo = t.brandLogo;
        if (bestTemplateId == null && t.templateId != null) bestTemplateId = t.templateId;
        if (t.orderIndex < bestOrderIndex) bestOrderIndex = t.orderIndex;
        if (t.id != survivor.id) {
          batch.delete(ref.doc(t.id));
          if (!kIsWeb) await _local.delete('transactions', t.id);
        }
      }

      final updateData = {
        'title': finalTitle,
        'amount': round(totalAmount),
        'description': descriptions.isNotEmpty ? descriptions.join(', ') : null,
        'brandLogo': bestBrandLogo,
        'templateId': bestTemplateId,
        'orderIndex': bestOrderIndex,
      };
      batch.update(ref.doc(survivor.id), updateData);
      if (!kIsWeb) await _local.update('transactions', updateData, survivor.id);
      await batch.commit();
    } catch (e) {
      print("Error unifyTransactions: $e");
      rethrow;
    }
  }
}
