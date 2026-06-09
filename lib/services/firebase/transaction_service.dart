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

  // --- TRANSACCIONES (SMARTER PULL v4.1.2) ---

  Future<void> syncTransactionsFromCloud({int? month, int? year}) async {
    try {
      if (kIsWeb) return;
      final String uid = currentUid;
      if (uid.isEmpty) return;

      List<TransactionModel> cloudItems = [];
      
      // 1. Descargar mis transacciones personales
      Query? myQuery = transactionsRef;
      if (myQuery != null && month != null && year != null) {
        DateTime start = DateTime(year, month, 1);
        DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
        myQuery = myQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
        final mySnap = await myQuery.get();
        cloudItems.addAll(mySnap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      // 2. Descargar transacciones compartidas (si existen)
      final String? fid = await getMyFamilyId();
      if (fid != null && fid != uid && month != null && year != null) {
        DateTime start = DateTime(year, month, 1);
        DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
        final famSnap = await db.collection('users').doc(fid).collection('expenses')
            .where('familyId', isEqualTo: fid)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();
        cloudItems.addAll(famSnap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      // 3. INTEGRIDAD: No pisar datos locales más nuevos o pendientes
      for (var cloud in cloudItems) {
        final localData = await _local.query('transactions', where: 'id = ?', whereArgs: [cloud.id]);
        if (localData.isNotEmpty) {
          final local = TransactionModel.fromMap(localData.first, cloud.id);
          if (local.syncStatus == 'pending') continue;
          if (local.updatedAt.isAfter(cloud.updatedAt)) continue;
        }
        await _local.insert('transactions', cloud.toLocalMap(), silent: true);
      }
      
      if (month != null && year != null) {
        await generateMonthlyTransactions(month, year, silent: true);
      }
      _local.notify('transactions');
    } catch (e) { print("Error syncing transactions: $e"); }
  }

  // --- TRANSACCIONES (OPERACIONES UNIFICADAS) ---

  Future<void> addTransaction(TransactionModel t, {bool silent = false}) async {
    try {
      final String id = t.id.isEmpty ? (transactionsRef?.doc().id ?? DateTime.now().millisecondsSinceEpoch.toString()) : t.id;
      final DateTime now = DateTime.now();
      
      if (!kIsWeb) await _local.insert('transactions', t.copyWith(id: id, syncStatus: 'pending', updatedAt: now).toLocalMap(), silent: silent);

      if (await checkPremium()) {
        final ref = getDocRef('expenses', id, familyId: t.familyId);
        await ref?.set({...t.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
        if (!kIsWeb) await _local.update('transactions', {'syncStatus': 'synced'}, id, silent: true);
      }
    } catch (e) { print("Error addTransaction: $e"); }
  }

  Future<void> addTransactionWithBalanceUpdate({required TransactionModel transaction, String? accountId}) async {
    try {
      final id = transactionsRef?.doc().id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final DateTime now = DateTime.now();
      final tx = transaction.copyWith(id: id, isPaid: accountId != null && accountId != 'CASH_PAYMENT', paidFromAccountId: accountId == 'CASH_PAYMENT' ? null : accountId, updatedAt: now, syncStatus: 'pending');

      if (!kIsWeb) {
        await _local.insert('transactions', tx.toLocalMap());
        if (accountId != null && accountId != 'CASH_PAYMENT') {
          final acc = await _local.query('balances', where: 'id = ?', whereArgs: [accountId]);
          if (acc.isNotEmpty) {
            double next = tx.type == 'INCOME' ? (acc.first['amount'] ?? 0.0) + tx.amount : (acc.first['amount'] ?? 0.0) - tx.amount;
            await _local.update('balances', {'amount': next, 'updatedAt': now.toIso8601String(), 'syncStatus': 'pending'}, accountId);
          }
        }
      }

      if (await checkPremium()) {
        final batch = db.batch();
        final txRef = getDocRef('expenses', id, familyId: tx.familyId);
        if (txRef != null) batch.set(txRef, {...tx.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
        
        if (accountId != null && accountId != 'CASH_PAYMENT') {
          String? accFamilyId;
          if (!kIsWeb) {
            final accData = await _local.query('balances', where: 'id = ?', whereArgs: [accountId]);
            if (accData.isNotEmpty) accFamilyId = accData.first['familyId'];
          }
          final balRef = getDocRef('balances', accountId, familyId: accFamilyId);
          if (balRef != null) {
            batch.update(balRef, {'amount': FieldValue.increment(tx.type == 'INCOME' ? tx.amount : -tx.amount), 'updatedAt': FieldValue.serverTimestamp()});
          }
        }
        await batch.commit();
        if (!kIsWeb) {
          await _local.update('transactions', {'syncStatus': 'synced'}, id, silent: true);
          if (accountId != null && accountId != 'CASH_PAYMENT') await _local.update('balances', {'syncStatus': 'synced'}, accountId, silent: true);
        }
      }
    } catch (e) { rethrow; }
  }

  Future<void> updateTransaction(TransactionModel t, {bool adjustBalance = false}) async {
    try {
      final DateTime now = DateTime.now();
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
                await _local.update('balances', {'amount': next, 'updatedAt': now.toIso8601String(), 'syncStatus': 'pending'}, old.paidFromAccountId!);
                if (await checkPremium()) {
                  final balRef = getDocRef('balances', old.paidFromAccountId!, familyId: acc.first['familyId']);
                  await balRef?.update({'amount': next, 'updatedAt': FieldValue.serverTimestamp()});
                  await _local.update('balances', {'syncStatus': 'synced'}, old.paidFromAccountId!, silent: true);
                }
              }
            }
          }
        }
        await _local.update('transactions', {...t.toLocalMap(), 'updatedAt': now.toIso8601String(), 'syncStatus': 'pending'}, t.id);
      }
      
      if (await checkPremium()) {
        final txRef = getDocRef('expenses', t.id, familyId: t.familyId);
        await txRef?.update({...t.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
        if (!kIsWeb) await _local.update('transactions', {'syncStatus': 'synced'}, t.id, silent: true);
      }
    } catch (e) { print("Error updateTransaction: $e"); }
  }

  Future<void> deleteTransaction(String id, {bool refundBalance = false}) async {
    try {
      String? familyId;
      if (!kIsWeb) {
        final existing = await _local.query('transactions', where: 'id = ?', whereArgs: [id]);
        if (existing.isNotEmpty) {
          final tx = TransactionModel.fromMap(existing.first, id);
          familyId = tx.familyId;
          if (refundBalance && tx.isPaid && tx.paidFromAccountId != null) {
            final acc = await _local.query('balances', where: 'id = ?', whereArgs: [tx.paidFromAccountId]);
            if (acc.isNotEmpty) {
              double current = (acc.first['amount'] ?? 0.0).toDouble();
              double next = tx.type == 'EXPENSE' ? current + tx.amount : current - tx.amount;
              await _local.update('balances', {'amount': next, 'updatedAt': DateTime.now().toIso8601String(), 'syncStatus': 'pending'}, tx.paidFromAccountId!);
              if (await checkPremium()) {
                final balRef = getDocRef('balances', tx.paidFromAccountId!, familyId: acc.first['familyId']);
                await balRef?.update({'amount': next, 'updatedAt': FieldValue.serverTimestamp()});
                await _local.update('balances', {'syncStatus': 'synced'}, tx.paidFromAccountId!, silent: true);
              }
            }
          }
        }
        await _local.delete('transactions', id);
      }
      if (await checkPremium()) {
        await getDocRef('expenses', id, familyId: familyId)?.delete();
      }
    } catch (e) { print("Error deleteTransaction: $e"); }
  }

  Stream<List<TransactionModel>> getTransactions({int? month, int? year}) {
    final String uid = currentUid;
    if (kIsWeb) {
      final ref = transactionsRef; if (ref == null) return Stream.value([]);
      Query query = ref;
      if (month != null && year != null) {
        DateTime start = DateTime(year, month, 1);
        DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
      }
      final myStream = query.snapshots().map((snap) => snap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
      return db.collection('users').doc(uid).snapshots().asyncExpand((userDoc) {
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final String? familyId = userData['familyId'];
        if (familyId == null) return myStream;
        Query sharedQuery = db.collectionGroup('expenses').where('familyId', isEqualTo: familyId);
        if (month != null && year != null) {
          DateTime start = DateTime(year, month, 1);
          DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
          sharedQuery = sharedQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
        }
        return sharedQuery.snapshots().map((sharedSnap) {
          final sharedTxs = sharedSnap.docs.where((d) => d.reference.parent.parent?.id != uid).map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
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
      return ref.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
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
        final tx = TransactionModel(id: deterministicId, title: t['title'], amount: (t['defaultAmount'] ?? 0.0).toDouble(), date: DateTime(year, month, 1, 12, 0, 0), category: t['category'] ?? 'Fijo', currency: t['currency'] ?? 'UYU', type: t['type'] ?? 'EXPENSE', isCompleted: false, brandLogo: t['brandLogo'], categoryColor: t['categoryColor'] is num ? t['categoryColor'] : null, templateId: templateId, orderIndex: t['orderIndex'] ?? 999, familyId: t['familyId']);
        await addTransaction(tx, silent: silent);
      }
      if (silent) _local.notify('transactions');
    } finally { _generatingMonths.remove(monthKey); }
  }

  Future<void> addCreditCardExpense({required String cardName, required double totalAmount, required int installments, required String currency, required DateTime startDate, String? concept, String? category, String? categoryLogo, int? categoryColor, int initialInstallment = 1, String? familyId}) async {
    try {
      final String cleanCardName = cardName.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
      final String targetTitle = "$cleanCardName ($currency)";
      final double amountPerInstallment = round(totalAmount / installments);
      final String purchaseId = "pid_${DateTime.now().millisecondsSinceEpoch}";
      final String purchaseDate = startDate.toIso8601String();
      for (int i = 0; i < (installments - initialInstallment + 1); i++) {
        final int currentInst = initialInstallment + i;
        final DateTime targetDate = DateTime(startDate.year, startDate.month + i, 1, 12, 0, 0);
        final String monthPrefix = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}%";
        final Map<String, dynamic> item = {'pid': purchaseId, 'c': concept ?? 'Compra', 'i': currentInst, 't': installments, 'a': amountPerInstallment, 'pd': purchaseDate};
        final existing = await _local.query('transactions', where: "date LIKE ? AND title = ? AND currency = ?", whereArgs: [monthPrefix, targetTitle, currency]);
        if (existing.isNotEmpty) {
          final old = TransactionModel.fromMap(existing.first, existing.first['id']);
          List<dynamic> items = [];
          try { items = jsonDecode(old.description ?? '[]'); } catch (_) { if (old.description != null && old.description!.isNotEmpty) items = [{'c': old.description, 'a': old.amount}]; }
          items.add(item);
          await updateTransaction(old.copyWith(amount: old.amount + amountPerInstallment, description: jsonEncode(items), familyId: familyId));
        } else {
          final tx = TransactionModel(id: '', title: targetTitle, amount: amountPerInstallment, date: targetDate, category: 'Tarjeta', currency: currency, type: 'EXPENSE', isCompleted: false, description: jsonEncode([item]), brandLogo: categoryLogo ?? 'cabal.png', categoryColor: categoryColor, orderIndex: 11, familyId: familyId);
          await addTransaction(tx);
        }
      }
    } catch (e) { print("Error addCreditCardExpense: $e"); }
  }

  Future<void> removeCreditCardExpense({required String cardName, required String purchaseId, required DateTime startDate}) async {
    try {
      final String cleanCardName = cardName.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
      final allResults = await _local.query('transactions', where: "title LIKE ?", whereArgs: ["$cleanCardName%"]);
      for (var data in allResults) {
        final tx = TransactionModel.fromMap(data, data['id']);
        List<dynamic> items = [];
        try { items = jsonDecode(tx.description ?? '[]'); } catch (_) { continue; }
        final int index = items.indexWhere((it) => it['pid'] == purchaseId);
        if (index != -1) {
          final double amountToRemove = (items[index]['a'] ?? 0.0).toDouble();
          items.removeAt(index);
          if (items.isEmpty) { await deleteTransaction(tx.id); } 
          else { await updateTransaction(tx.copyWith(amount: (tx.amount - amountToRemove).clamp(0, double.infinity), description: jsonEncode(items))); }
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
      await updateTransaction(mainTx.copyWith(title: baseName, amount: total, description: descriptions.join(', ')));
      for (int i = 1; i < transactions.length; i++) { await deleteTransaction(transactions[i].id); }
    } catch (e) { print("Error unifyTransactions: $e"); }
  }

  Future<void> clearMonth(int month, int year) async {
    try {
      final String monthPrefix = "$year-${month.toString().padLeft(2, '0')}%";
      final txs = await _local.query('transactions', where: "date LIKE ?", whereArgs: [monthPrefix]);
      for (var t in txs) { await deleteTransaction(t['id']); }
    } catch (e) { print("Error clearMonth: $e"); }
  }

  Future<void> completeTransactionWithBalanceUpdate({required TransactionModel transaction, required String accountId, required bool isUndoing}) async {
    try {
      final DateTime now = DateTime.now();
      final tx = transaction.copyWith(isCompleted: !isUndoing, isPaid: !isUndoing, paidFromAccountId: isUndoing ? null : accountId, updatedAt: now, syncStatus: 'pending');
      await updateTransaction(tx);
      if (accountId != 'CASH_PAYMENT') {
        final acc = await _local.query('balances', where: 'id = ?', whereArgs: [accountId]);
        if (acc.isNotEmpty) {
          double current = (acc.first['amount'] ?? 0.0).toDouble();
          double diff = transaction.amount;
          double next = transaction.type == 'INCOME' ? (isUndoing ? current - diff : current + diff) : (isUndoing ? current + diff : current - diff);
          await _local.update('balances', {'amount': next, 'updatedAt': now.toIso8601String(), 'syncStatus': 'pending'}, accountId);
          if (await checkPremium()) {
            final balRef = getDocRef('balances', accountId, familyId: acc.first['familyId']);
            await balRef?.update({'amount': next, 'updatedAt': FieldValue.serverTimestamp()});
            if (!kIsWeb) await _local.update('balances', {'syncStatus': 'synced'}, accountId, silent: true);
          }
        }
      }
    } catch (e) {}
  }
}
