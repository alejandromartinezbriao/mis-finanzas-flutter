import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';
import '../../models/transaction_model.dart';

mixin TransactionService on FirebaseBase {
  // --- TRANSACCIONES ---

  Future<void> addTransaction(TransactionModel t) async {
    try {
      final ref = transactionsRef;
      if (ref == null) return;
      await ref.add(t.toMap());
    } catch (e) {
      print("Error addTransaction: $e");
    }
  }

  Future<void> addTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    String? accountId,
  }) async {
    try {
      final batch = db.batch();
      final transRef = transactionsRef!.doc();
      
      batch.set(transRef, {
        ...transaction.toMap(),
        'paidFromAccountId': accountId,
      });

      if (accountId != null) {
        final accountRef = balancesRef!.doc(accountId);
        final accountDoc = await accountRef.get();
        
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
        }
      }

      await batch.commit();
    } catch (e) {
      print("Error addTransactionWithBalanceUpdate: $e");
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel t) async {
    try {
      final ref = transactionsRef;
      if (ref == null) return;
      await ref.doc(t.id).update(t.toMap());
    } catch (e) {
      print("Error updateTransaction: $e");
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final ref = transactionsRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteTransaction: $e");
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
      return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
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

        // Solo borramos si es de plantilla Y NO es una tarjeta (para no perder cuotas)
        // O si es un gasto genérico sin categoría ni cuotas.
        if ((isFromTemplate && !isCard) || (!isInstallment && data['category'] != 'Otros' && !isCard)) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }
      
      if (deletedCount > 0) await batch.commit();
    } catch (e) {
      print("Error clearMonth: $e");
    }
  }

  // --- LÓGICA DE NEGOCIO ---

  Future<void> completeTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    required String accountId,
    required bool isUndoing,
  }) async {
    try {
      final batch = db.batch();
      final transRef = transactionsRef!.doc(transaction.id);
      final accountRef = balancesRef!.doc(accountId);

      batch.update(transRef, {
        'isCompleted': !isUndoing, 
        'isPaid': !isUndoing,
        'paidFromAccountId': isUndoing ? null : accountId,
      });

      final accountDoc = await accountRef.get();
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
        
        // --- FILTRO ANTIFANTASMAS ---
        // Solo procesamos plantillas que tengan Tipo y Título.
        if (dataT['type'] == null || dataT['title'] == null || dataT['title'].toString().isEmpty) {
          continue; 
        }

        final String templateId = docT.id;
        final String titleT = dataT['title'];
        final String currencyT = dataT['currency'] ?? 'UYU';
        final String uniqueKey = "${norm(titleT)}_$currencyT";
        final int oIndex = dataT['orderIndex'] ?? 999;
        
        if (processedKeysInThisRun.contains(uniqueKey)) continue;

        // Nombre base sin sufijos de moneda para comparaciones inteligentes
        final String cleanTitleT = titleT.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
        
        final existingBase = existingInMonth.where((e) {
          bool matchId = e['templateId'] == templateId;
          
          final String eTitle = (e['title'] ?? '').toString();
          final String cleanETitle = eTitle.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
          
          bool matchName = norm(cleanETitle) == norm(cleanTitleT) && e['currency'] == currencyT;
          return matchId || matchName;
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

          final existingSub = existingInMonth.where((e) => e['subscriptionId'] == docS.id).firstOrNull;
          if (existingSub == null) {
            batch.set(refE.doc(), {
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
            });
            addedAny = true;
          }
        }

        if (existingBase == null) {
          final newRef = refE.doc();
          double initialAmount = (dataT['defaultAmount'] ?? 0.0).toDouble();
          
          batch.set(newRef, {
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
          });
          addedAny = true;
        } else {
          // Si ya existe la tarjeta (ej: por cuotas), le sumamos las suscripciones si no estaban
          final dataE = existingBase;
          double currentAmount = (dataE['amount'] ?? 0.0).toDouble();
          String currentDesc = dataE['description'] ?? '';
          
          // Solo actualizamos si hay suscripciones nuevas para esta tarjeta
          if (totalSubsForThisCard > 0 && !currentDesc.contains('Suscripciones:')) {
            batch.update(dataE['ref'], {
              'templateId': templateId,
              'title': titleT,
              'amount': round(currentAmount + totalSubsForThisCard),
              'description': currentDesc.isEmpty 
                  ? "Suscripciones: ${subDetails.join(', ')}" 
                  : "$currentDesc, Suscripciones: ${subDetails.join(', ')}",
              'orderIndex': oIndex,
              'brandLogo': dataT['brandLogo'],
            });
          } else {
            batch.update(dataE['ref'], {
              'templateId': templateId,
              'title': titleT,
              'orderIndex': oIndex,
              'brandLogo': dataT['brandLogo'],
            });
          }
          addedAny = true;
        }
      }

      for (var docS in subsDocs.docs) {
        final dataS = docS.data() as Map<String, dynamic>;
        if (dataS['linkType'] != 'ACCOUNT' && dataS['linkId'] != null) continue;
        final String name = dataS['name'] ?? 'Suscripción';
        final String currencyS = dataS['currency'] ?? 'UYU';
        final String uniqueKey = "${norm(name)}_$currencyS";
        final existingDirect = existingInMonth.where((e) => e['subscriptionId'] == docS.id).firstOrNull;
        if (existingDirect == null) {
          batch.set(refE.doc(), {
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
          });
          addedAny = true;
          processedKeysInThisRun.add(uniqueKey);
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
      int? cardColor; // Nuevo
      int? cardOrder;
      int? dueDay;
      String? templateId;
      if (cardT != null) {
        final d = cardT.data() as Map<String, dynamic>;
        cardLogo = d['brandLogo'];
        cardColor = d['categoryColor']; // Si el template tiene color
        cardOrder = d['orderIndex'];
        dueDay = d['dueDay'];
        templateId = cardT.id;
      }

      final batch = db.batch();
      double amountPerMonth = round(totalAmount / installments);
      double totalAllocated = 0;

      // Calculamos cuánto ya se habría "pagado" si no empezamos en la cuota 1
      if (initialInstallment > 1) {
        totalAllocated = round(amountPerMonth * (initialInstallment - 1));
      }

      for (int i = initialInstallment; i <= installments; i++) {
        // En la última cuota, ajustamos por el residuo del redondeo
        double currentInstallmentAmount = amountPerMonth;
        if (i == installments) {
          currentInstallmentAmount = round(totalAmount - totalAllocated);
        }
        totalAllocated += currentInstallmentAmount;

        // La fecha de inicio corresponde a la cuota seleccionada
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
          batch.update(existing.reference, {
            'amount': round(currentAmount + currentInstallmentAmount), 
            'description': oldDesc.isEmpty ? detail : "$oldDesc, $detail",
            'brandLogo': cardLogo ?? categoryLogo,
            'categoryColor': cardColor ?? categoryColor, // Nuevo
            'orderIndex': cardOrder ?? 999,
          });
        } else {
          batch.set(ref.doc(), {
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
            'categoryColor': cardColor ?? categoryColor, // Nuevo
            'orderIndex': cardOrder ?? 999,
            'templateId': templateId,
          });
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
            
            bool shouldRemove = (itemIdentifier == fullIdentifier) || 
                               (conceptBase.isNotEmpty && itemIdentifier.startsWith("$conceptBase ("));
            
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
            
            // Protección: Si por algún motivo el total queda insignificante, lo limpiamos a 0
            if (newTotal < 0.01) newTotal = 0;

            batch.update(cardDoc.reference, {
              'description': newItems.join(', '), 
              'amount': round(newTotal)
            });
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
      
      // La primera será la "sobreviviente"
      final survivor = transactions.first;
      final String finalTitle = "$baseName (${survivor.currency})";
      
      double totalAmount = 0;
      List<String> descriptions = [];
      String? bestBrandLogo = survivor.brandLogo;
      String? bestTemplateId = survivor.templateId;
      int bestOrderIndex = survivor.orderIndex;

      for (var t in transactions) {
        totalAmount += t.amount;
        if (t.description != null && t.description!.isNotEmpty) {
          descriptions.add(t.description!);
        }
        if (bestBrandLogo == null && t.brandLogo != null) bestBrandLogo = t.brandLogo;
        if (bestTemplateId == null && t.templateId != null) bestTemplateId = t.templateId;
        if (t.orderIndex < bestOrderIndex) bestOrderIndex = t.orderIndex;

        // Marcamos para borrar todas menos la primera
        if (t.id != survivor.id) {
          batch.delete(ref.doc(t.id));
        }
      }

      // Actualizamos la sobreviviente
      batch.update(ref.doc(survivor.id), {
        'title': finalTitle,
        'amount': round(totalAmount),
        'description': descriptions.isNotEmpty ? descriptions.join(', ') : null,
        'brandLogo': bestBrandLogo,
        'templateId': bestTemplateId,
        'orderIndex': bestOrderIndex,
      });

      await batch.commit();
    } catch (e) {
      print("Error unifyTransactions: $e");
      rethrow;
    }
  }
}
