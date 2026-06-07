import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_base.dart';
import '../../models/transaction_model.dart';
import '../local_db_service.dart';

mixin TransactionService on FirebaseBase {
  final LocalDbService _local = LocalDbService();
  static final Set<String> _generatingMonths = {};

  // --- TRANSACCIONES (PULL SYNC) ---

  Future<void> syncTransactionsFromCloud({int? month, int? year}) async {
    try {
      final ref = transactionsRef;
      if (ref == null || kIsWeb) return;

      Query query = ref;
      if (month != null && year != null) {
        DateTime start = DateTime(year, month, 1);
        DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
      }

      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        final items = snap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id).toLocalMap()).toList();
        await _local.insertBatch('transactions', items);
      }
      
      if (month != null && year != null) {
        await generateMonthlyTransactions(month, year, silent: true);
      }
    } catch (e) { print("Error syncing transactions: $e"); }
  }

  // --- TRANSACCIONES (OPERACIONES) ---

  Future<void> addTransaction(TransactionModel t, {bool silent = false}) async {
    try {
      final String id = t.id.isEmpty ? (transactionsRef?.doc().id ?? DateTime.now().millisecondsSinceEpoch.toString()) : t.id;
      final localTx = t.copyWith(id: id, syncStatus: 'synced').toLocalMap();

      if (!kIsWeb) await _local.insert('transactions', localTx, silent: silent);

      final premium = await checkPremium();
      if ((kIsWeb || premium) && !silent) {
        await transactionsRef?.doc(id).set(t.toMap());
      }
    } catch (e) { print("Error addTransaction: $e"); }
  }

  Future<void> addTransactionWithBalanceUpdate({required TransactionModel transaction, String? accountId}) async {
    try {
      final id = transactionsRef?.doc().id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final tx = transaction.copyWith(id: id, isPaid: accountId != null && accountId != 'CASH_PAYMENT', paidFromAccountId: accountId == 'CASH_PAYMENT' ? null : accountId);

      if (!kIsWeb) {
        await _local.insert('transactions', tx.copyWith(syncStatus: 'synced').toLocalMap());
        if (accountId != null && accountId != 'CASH_PAYMENT') {
          final acc = await _local.query('balances', where: 'id = ?', whereArgs: [accountId]);
          if (acc.isNotEmpty) {
            double current = (acc.first['amount'] ?? 0.0).toDouble();
            double next = tx.type == 'INCOME' ? current + tx.amount : current - tx.amount;
            await _local.update('balances', {'amount': next}, accountId);
          }
        }
      }

      final premium = await checkPremium();
      if (kIsWeb || premium) {
        final batch = db.batch();
        batch.set(transactionsRef!.doc(id), tx.toMap());
        if (accountId != null && accountId != 'CASH_PAYMENT') {
          batch.update(balancesRef!.doc(accountId), {'amount': FieldValue.increment(tx.type == 'INCOME' ? tx.amount : -tx.amount), 'updatedAt': FieldValue.serverTimestamp()});
        }
        await batch.commit();
      }
    } catch (e) { rethrow; }
  }

  Future<void> updateTransaction(TransactionModel t, {bool adjustBalance = false}) async {
    try {
      if (!kIsWeb) {
        if (adjustBalance) {
          final existing = await _local.query('transactions', where: 'id = ?', whereArgs: [t.id]);
          if (existing.isNotEmpty) {
            final old = TransactionModel.fromMap(existing.first, t.id);
            if (old.isPaid && old.paidFromAccountId != null && old.amount != t.amount) {
              final double diff = t.amount - old.amount;
              final acc = await _local.query('balances', where: 'id = ?', whereArgs: [old.paidFromAccountId]);
              if (acc.isNotEmpty) {
                double current = (acc.first['amount'] ?? 0.0).toDouble();
                double next = t.type == 'INCOME' ? current + diff : current - diff;
                await _local.update('balances', {'amount': next}, old.paidFromAccountId!);
                
                final premium = await checkPremium();
                if (kIsWeb || premium) {
                  await balancesRef?.doc(old.paidFromAccountId).update({'amount': next, 'updatedAt': FieldValue.serverTimestamp()});
                }
              }
            }
          }
        }
        await _local.update('transactions', t.toLocalMap(), t.id);
      }
      
      final premium = await checkPremium();
      if ((kIsWeb || premium) && transactionsRef != null) {
        await transactionsRef!.doc(t.id).update(t.toMap());
      }
    } catch (e) { print("Error updateTransaction: $e"); }
  }

  Future<void> deleteTransaction(String id, {bool refundBalance = false}) async {
    try {
      if (!kIsWeb) {
        if (refundBalance) {
          final existing = await _local.query('transactions', where: 'id = ?', whereArgs: [id]);
          if (existing.isNotEmpty) {
            final tx = TransactionModel.fromMap(existing.first, id);
            if (tx.isPaid && tx.paidFromAccountId != null) {
              final acc = await _local.query('balances', where: 'id = ?', whereArgs: [tx.paidFromAccountId]);
              if (acc.isNotEmpty) {
                double current = (acc.first['amount'] ?? 0.0).toDouble();
                double next = tx.type == 'EXPENSE' ? current + tx.amount : current - tx.amount;
                await _local.update('balances', {'amount': next}, tx.paidFromAccountId!);
                
                final premium = await checkPremium();
                if (kIsWeb || premium) {
                  await balancesRef?.doc(tx.paidFromAccountId).update({'amount': next, 'updatedAt': FieldValue.serverTimestamp()});
                }
              }
            }
          }
        }
        await _local.delete('transactions', id);
      }

      final premium = await checkPremium();
      if ((kIsWeb || premium) && transactionsRef != null) {
        await transactionsRef!.doc(id).delete();
      }
    } catch (e) { print("Error deleteTransaction: $e"); }
  }

  Stream<List<TransactionModel>> getTransactions({int? month, int? year}) {
    final String currentUid = auth.currentUser?.uid ?? '';

    if (kIsWeb) {
      final ref = transactionsRef; if (ref == null) return Stream.value([]);
      Query query = ref;
      if (month != null && year != null) {
        DateTime start = DateTime(year, month, 1);
        DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
      }

      final myStream = query.snapshots().map((snap) => snap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());

      return db.collection('users').doc(currentUid).snapshots().asyncExpand((userDoc) {
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final String? familyId = userData['familyId'];

        if (familyId == null) return myStream;

        Query sharedQuery = db.collectionGroup('expenses')
            .where('familyId', isEqualTo: familyId)
            .where('isDeleted', isEqualTo: false);
        
        if (month != null && year != null) {
          DateTime start = DateTime(year, month, 1);
          DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
          sharedQuery = sharedQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
        }

        return sharedQuery.snapshots().map((sharedSnap) {
          final sharedTxs = sharedSnap.docs
              .where((d) => d.reference.parent.parent?.id != currentUid)
              .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return myStream.map((myTxs) => [...myTxs, ...sharedTxs]);
        }).asyncExpand((s) => s);
      });
    }

    final controller = StreamController<List<TransactionModel>>();
    if (month == null || year == null) return Stream.value([]);
    final String monthPrefix = "$year-${month.toString().padLeft(2, '0')}%";

    void load() async {
      try {
        final list = await _local.query('transactions', where: "date LIKE ? AND isDeleted = 0", whereArgs: [monthPrefix], orderBy: 'date DESC');
        final txs = list.map((m) => TransactionModel.fromMap(m, m['id'])).toList();
        if (!controller.isClosed) controller.add(txs);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }

    load();
    final sub = _local.onTableChanged.where((t) => t == 'transactions').listen((_) => load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Stream<List<TransactionModel>> getTransactionsInRange(DateTime start, DateTime end) {
    if (kIsWeb) {
      final ref = transactionsRef; if (ref == null) return Stream.value([]);
      return ref.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots().map((snap) => snap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
    }

    final controller = StreamController<List<TransactionModel>>();
    final String startStr = start.toIso8601String();
    final String endStr = end.toIso8601String();

    void load() async {
      try {
        final list = await _local.query('transactions', where: "date >= ? AND date <= ? AND isDeleted = 0", whereArgs: [startStr, endStr], orderBy: 'date DESC');
        final txs = list.map((m) => TransactionModel.fromMap(m, m['id'])).toList();
        if (!controller.isClosed) controller.add(txs);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }

    load();
    final sub = _local.onTableChanged.where((t) => t == 'transactions').listen((_) => load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Future<void> generateMonthlyTransactions(int month, int year, {bool silent = false}) async {
    final String monthKey = "$year-$month";
    if (_generatingMonths.contains(monthKey)) return; 
    _generatingMonths.add(monthKey);

    try {
      final templates = await _local.query('templates', where: 'isDeleted = 0');
      final String monthPrefix = "$year-${month.toString().padLeft(2, '0')}%";
      final existing = await _local.query('transactions', where: "date LIKE ? AND isDeleted = 0", whereArgs: [monthPrefix]);

      for (var t in templates) {
        final String templateId = t['id']; 
        final String deterministicId = "gen_${templateId}_${year}_${month.toString().padLeft(2, '0')}";
        if (existing.any((e) => e['id'] == deterministicId || e['templateId'] == templateId)) continue;

        final tx = TransactionModel(
          id: deterministicId, title: t['title'], amount: (t['defaultAmount'] ?? 0.0).toDouble(),
          date: DateTime(year, month, 1, 12, 0, 0), category: t['category'] ?? 'Fijo',
          currency: t['currency'] ?? 'UYU', type: t['type'] ?? 'EXPENSE',
          isCompleted: false, brandLogo: t['brandLogo'], categoryColor: t['categoryColor'] is num ? t['categoryColor'] : null,
          templateId: templateId, orderIndex: t['orderIndex'] ?? 999,
          familyId: t['familyId'] 
        );
        await addTransaction(tx, silent: silent);
      }
      if (silent) _local.notify('transactions');
    } finally {
      _generatingMonths.remove(monthKey); 
    }
  }

  // --- COMPRAS CON TARJETA (ESTRUCTURADO v4.0) ---

  Future<void> addCreditCardExpense({
    required String cardName, required double totalAmount, required int installments, required String currency,
    required DateTime startDate, String? concept, String? category, String? categoryLogo, int? categoryColor,
    int initialInstallment = 1, String? familyId 
  }) async {
    try {
      final String cleanCardName = cardName.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
      final String targetTitle = "$cleanCardName ($currency)";
      final double amountPerInstallment = round(totalAmount / installments);
      
        // LLAVE MAESTRA ÚNICA PARA TODA LA SERIE DE CUOTAS
        final String purchaseId = "pid_${DateTime.now().millisecondsSinceEpoch}";
        final String purchaseDate = startDate.toIso8601String(); // GUARDAMOS FECHA ORIGINAL

        for (int i = 0; i < (installments - initialInstallment + 1); i++) {
          final int currentInst = initialInstallment + i;
          final DateTime targetDate = DateTime(startDate.year, startDate.month + i, 1, 12, 0, 0);
          final String monthPrefix = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}%";

          // Creamos el ítem estructurado en JSON
          final Map<String, dynamic> item = {
            'pid': purchaseId,
            'c': concept ?? 'Compra',
            'i': currentInst,
            't': installments,
            'a': amountPerInstallment,
            'pd': purchaseDate // NUEVO: Purchase Date
          };

        final existing = await _local.query('transactions', where: "date LIKE ? AND title = ? AND currency = ?", whereArgs: [monthPrefix, targetTitle, currency]);

        if (existing.isNotEmpty) {
          final old = TransactionModel.fromMap(existing.first, existing.first['id']);
          List<dynamic> items = [];
          try { items = jsonDecode(old.description ?? '[]'); } catch (_) { 
            // Migración: Si no es JSON, convertimos lo viejo a una entrada genérica (sin pid)
            if (old.description != null && old.description!.isNotEmpty) items = [{'c': old.description, 'a': old.amount}];
          }
          items.add(item);
          
          await updateTransaction(old.copyWith(
            amount: old.amount + amountPerInstallment, 
            description: jsonEncode(items),
            familyId: familyId 
          ));
        } else {
          final tx = TransactionModel(
            id: '', title: targetTitle, amount: amountPerInstallment, date: targetDate,
            category: 'Tarjeta', currency: currency, type: 'EXPENSE',
            isCompleted: false, description: jsonEncode([item]), brandLogo: categoryLogo ?? 'cabal.png',
            categoryColor: categoryColor, orderIndex: 11,
            familyId: familyId 
          );
          await addTransaction(tx);
        }
      }
    } catch (e) { print("Error addCreditCardExpense: $e"); }
  }

  // --- BORRADO ATÓMICO POR PURCHASE ID (pid) ---

  Future<void> removeCreditCardExpense({required String cardName, required String purchaseId, required DateTime startDate}) async {
    try {
      final String cleanCardName = cardName.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
      
      // Búsqueda GLOBAL por Purchase ID exacto (pid)
      // Buscamos en todas las transacciones de esta tarjeta que tengan JSON en la descripción
      final allResults = await _local.query('transactions', where: "title LIKE ?", whereArgs: ["$cleanCardName%"]);
      
      for (var data in allResults) {
        final tx = TransactionModel.fromMap(data, data['id']);
        List<dynamic> items = [];
        try { items = jsonDecode(tx.description ?? '[]'); } catch (_) { continue; }
        
        // Buscamos si este mes tiene un ítem con el PID buscado
        final int index = items.indexWhere((it) => it['pid'] == purchaseId);
        
        if (index != -1) {
          final double amountToRemove = (items[index]['a'] ?? 0.0).toDouble();
          items.removeAt(index);

          if (items.isEmpty) {
            await deleteTransaction(tx.id);
          } else {
            await updateTransaction(tx.copyWith(
              amount: (tx.amount - amountToRemove).clamp(0, double.infinity),
              description: jsonEncode(items)
            ));
          }
        }
      }
    } catch (e) { print("Error removeCreditCardExpenseByPID: $e"); }
  }

  Future<void> unifyTransactions(List<TransactionModel> transactions, String baseName) async {
    if (transactions.isEmpty) return;
    try {
      final double total = transactions.fold(0.0, (sum, t) => sum + t.amount);
      final List<String> descriptions = transactions.map((t) => t.description ?? '').where((s) => s.isNotEmpty).toList();
      final mainTx = transactions.first;
      
      await updateTransaction(mainTx.copyWith(
        title: baseName,
        amount: total,
        description: descriptions.join(', ')
      ));

      for (int i = 1; i < transactions.length; i++) {
        await deleteTransaction(transactions[i].id);
      }
    } catch (e) { print("Error unifyTransactions: $e"); }
  }

  Future<void> clearMonth(int month, int year) async {
    try {
      final String monthPrefix = "$year-${month.toString().padLeft(2, '0')}%";
      final txs = await _local.query('transactions', where: "date LIKE ?", whereArgs: [monthPrefix]);
      for (var t in txs) {
        await deleteTransaction(t['id']);
      }
    } catch (e) { print("Error clearMonth: $e"); }
  }

  Future<void> completeTransactionWithBalanceUpdate({required TransactionModel transaction, required String accountId, required bool isUndoing}) async {
    try {
      final tx = transaction.copyWith(isCompleted: !isUndoing, isPaid: !isUndoing, paidFromAccountId: isUndoing ? null : accountId);
      await updateTransaction(tx);
      if (accountId != 'CASH_PAYMENT') {
        final acc = await _local.query('balances', where: 'id = ?', whereArgs: [accountId]);
        if (acc.isNotEmpty) {
          double current = (acc.first['amount'] ?? 0.0).toDouble();
          double diff = transaction.amount;
          double next = transaction.type == 'INCOME' ? (isUndoing ? current - diff : current + diff) : (isUndoing ? current + diff : current - diff);
          await _local.update('balances', {'amount': next}, accountId);
        }
      }
    } catch (e) {}
  }
}
