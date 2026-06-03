import 'dart:async';
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
      final tx = transaction.copyWith(id: id);

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
        batch.set(transactionsRef!.doc(id), {...tx.toMap(), 'paidFromAccountId': accountId});
        if (accountId != null && accountId != 'CASH_PAYMENT') {
          batch.update(balancesRef!.doc(accountId), {'amount': FieldValue.increment(tx.type == 'INCOME' ? tx.amount : -tx.amount), 'updatedAt': FieldValue.serverTimestamp()});
        }
        await batch.commit();
      }
    } catch (e) { rethrow; }
  }

  Future<void> updateTransaction(TransactionModel t) async {
    try {
      if (!kIsWeb) await _local.update('transactions', t.toLocalMap(), t.id);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && transactionsRef != null) {
        await transactionsRef!.doc(t.id).update(t.toMap());
      }
    } catch (e) {}
  }

  Future<void> deleteTransaction(String id) async {
    try {
      if (!kIsWeb) await _local.delete('transactions', id);
      final premium = await checkPremium();
      if ((kIsWeb || premium) && transactionsRef != null) {
        await transactionsRef!.doc(id).delete();
      }
    } catch (e) {}
  }

  Stream<List<TransactionModel>> getTransactions({int? month, int? year}) {
    if (kIsWeb) {
      final ref = transactionsRef; if (ref == null) return Stream.value([]);
      Query query = ref.where('isDeleted', isEqualTo: false);
      if (month != null && year != null) {
        DateTime start = DateTime(year, month, 1);
        DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
      }
      return query.snapshots().map((snap) => snap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
    }

    final controller = StreamController<List<TransactionModel>>();
    if (month == null || year == null) return Stream.value([]);
    final String monthPrefix = "$year-${month.toString().padLeft(2, '0')}%";

    void _load() async {
      try {
        final list = await _local.query('transactions', where: "date LIKE ? AND isDeleted = 0", whereArgs: [monthPrefix], orderBy: 'date DESC');
        final txs = list.map((m) => TransactionModel.fromMap(m, m['id'])).toList();
        if (!controller.isClosed) controller.add(txs);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }

    _load();
    final sub = _local.onTableChanged.where((t) => t == 'transactions').listen((_) => _load());
    controller.onCancel = () { sub.cancel(); controller.close(); };
    return controller.stream;
  }

  Stream<List<TransactionModel>> getTransactionsInRange(DateTime start, DateTime end) {
    if (kIsWeb) {
      final ref = transactionsRef; if (ref == null) return Stream.value([]);
      return ref.where('isDeleted', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots().map((snap) => snap.docs.map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
    }

    final controller = StreamController<List<TransactionModel>>();
    final String startStr = start.toIso8601String();
    final String endStr = end.toIso8601String();

    void _load() async {
      try {
        final list = await _local.query('transactions', where: "date >= ? AND date <= ? AND isDeleted = 0", whereArgs: [startStr, endStr], orderBy: 'date DESC');
        final txs = list.map((m) => TransactionModel.fromMap(m, m['id'])).toList();
        if (!controller.isClosed) controller.add(txs);
      } catch (e) { if (!controller.isClosed) controller.add([]); }
    }

    _load();
    final sub = _local.onTableChanged.where((t) => t == 'transactions').listen((_) => _load());
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
          templateId: templateId, orderIndex: t['orderIndex'] ?? 999
        );
        await addTransaction(tx, silent: silent);
      }
      if (silent) _local.notify('transactions');
    } catch (e) {
    } finally {
      _generatingMonths.remove(monthKey); 
    }
  }

  // --- COMPRAS CON TARJETA (GROUPING BLINDADO) ---

  Future<void> addCreditCardExpense({
    required String cardName, required double totalAmount, required int installments, required String currency,
    required DateTime startDate, String? concept, String? category, String? categoryLogo, int? categoryColor,
    int initialInstallment = 1
  }) async {
    try {
      // 1. Limpiar el nombre de la tarjeta para evitar el error "(UYU) (UYU)"
      final String cleanCardName = cardName.replaceAll(RegExp(r' \((UYU|USD)\)$', caseSensitive: false), '').trim();
      final String targetTitle = "$cleanCardName ($currency)";
      
      final double amountPerInstallment = round(totalAmount / installments);

      for (int i = 0; i < (installments - initialInstallment + 1); i++) {
        final int currentInst = initialInstallment + i;
        final DateTime targetDate = DateTime(startDate.year, startDate.month + i, 1, 12, 0, 0);
        final String desc = "${concept ?? 'Compra'} ($currentInst/$installments) - ${formatAmount(amountPerInstallment, currency)}";
        final String monthPrefix = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}%";

        // Buscar el registro exacto de la tarjeta en el mes objetivo
        final existing = await _local.query('transactions', where: "date LIKE ? AND title = ? AND currency = ?", whereArgs: [monthPrefix, targetTitle, currency]);

        if (existing.isNotEmpty) {
          // UNIR AL GASTO DE TARJETA EXISTENTE
          final old = TransactionModel.fromMap(existing.first, existing.first['id']);
          await updateTransaction(old.copyWith(
            amount: old.amount + amountPerInstallment, 
            description: (old.description?.isEmpty ?? true) ? desc : "${old.description}, $desc"
          ));
        } else {
          // CREAR NUEVO REGISTRO DE TARJETA
          final tx = TransactionModel(
            id: '', title: targetTitle, amount: amountPerInstallment, date: targetDate,
            category: 'Tarjeta', currency: currency, type: 'EXPENSE',
            isCompleted: false, description: desc, brandLogo: categoryLogo ?? 'cabal.png',
            categoryColor: categoryColor, orderIndex: 11
          );
          await addTransaction(tx);
        }
      }
    } catch (e) { print("Error addCreditCardExpense: $e"); }
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

  Future<void> removeCreditCardExpense({required String cardName, required String fullItemText, required DateTime startDate}) async {}
  Future<void> unifyTransactions(List<TransactionModel> transactions, String baseName) async {}
  Future<void> clearMonth(int month, int year) async {}
}
