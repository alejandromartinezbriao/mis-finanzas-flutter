import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference? get _transactionsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('expenses');
  }

  CollectionReference? get _templatesRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('templates');
  }

  CollectionReference? get _balancesRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('balances');
  }

  CollectionReference? get _categoriesRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('categories');
  }

  CollectionReference? get _budgetsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('budgets');
  }

  CollectionReference? get _goalsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('goals');
  }

  String _norm(String text) => text.trim().toLowerCase();

  // --- PRESUPUESTOS ---

  Stream<List<Map<String, dynamic>>> getBudgets(int month, int year) {
    final ref = _budgetsRef;
    if (ref == null) return Stream.value([]);
    return ref.where('month', isEqualTo: month).where('year', isEqualTo: year).snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  Future<void> setBudget(String categoryName, double amount, int month, int year, String currency) async {
    try {
      final ref = _budgetsRef;
      if (ref == null) return;
      
      final existing = await ref
          .where('categoryName', isEqualTo: categoryName)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      if (existing.docs.isNotEmpty) {
        await ref.doc(existing.docs.first.id).update({'amount': amount, 'currency': currency});
      } else {
        await ref.add({
          'categoryName': categoryName,
          'amount': amount,
          'month': month,
          'year': year,
          'currency': currency,
        });
      }
    } catch (e) {
      print("Error setBudget: $e");
    }
  }

  // --- CATEGORÍAS ---

  Stream<List<Map<String, dynamic>>> getCategories({String? type}) {
    final ref = _categoriesRef;
    if (ref == null) return Stream.value([]);
    
    Query query = ref;
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    
    return query.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Ordenar en memoria para evitar requerir índices compuestos en Firestore
      list.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
      return list;
    });
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      final ref = _categoriesRef;
      if (ref == null) return;
      await ref.add(data);
    } catch (e) {
      print("Error addCategory: $e");
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final ref = _categoriesRef;
      if (ref == null) return;
      await ref.doc(id).update(data);
    } catch (e) {
      print("Error updateCategory: $e");
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final ref = _categoriesRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteCategory: $e");
    }
  }

  // --- BALANCES REALES (ARQUEO) ---

  Stream<List<Map<String, dynamic>>> getBalances() {
    final ref = _balancesRef;
    if (ref == null) return Stream.value([]);
    return ref.orderBy('accountName').snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  Future<void> updateBalance(String id, double amount) async {
    try {
      final ref = _balancesRef;
      if (ref == null) return;
      await ref.doc(id).update({
        'amount': amount,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error updateBalance: $e");
    }
  }

  Future<void> updateBalanceAccountDetails(String id, Map<String, dynamic> data) async {
    try {
      final ref = _balancesRef;
      if (ref == null) return;
      await ref.doc(id).update(data);
    } catch (e) {
      print("Error updateBalanceAccountDetails: $e");
    }
  }

  Future<void> addBalanceAccount(String name, String currency, {String? logo}) async {
    try {
      final ref = _balancesRef;
      if (ref == null) return;
      await ref.add({
        'accountName': name,
        'amount': 0.0,
        'currency': currency,
        'updatedAt': Timestamp.now(),
        'brandLogo': logo,
      });
    } catch (e) {
      print("Error addBalanceAccount: $e");
    }
  }

  Future<void> deleteBalanceAccount(String id) async {
    try {
      final ref = _balancesRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteBalanceAccount: $e");
    }
  }

  // --- TRANSACCIONES ---

  Future<void> addTransaction(TransactionModel t) async {
    try {
      final ref = _transactionsRef;
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
      final batch = _db.batch();
      final transRef = _transactionsRef!.doc(); // Generar ID automático
      
      // 1. Guardar la transacción
      batch.set(transRef, {
        ...transaction.toMap(),
        if (accountId != null) 'paidFromAccountId': accountId,
      });

      // 2. Si hay cuenta asociada, actualizar su saldo
      if (accountId != null) {
        final accountRef = _balancesRef!.doc(accountId);
        final accountDoc = await accountRef.get();
        
        if (accountDoc.exists) {
          double currentBalance = (accountDoc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
          // Si es ingreso sumamos, si es gasto restamos (aunque por ahora solo lo usaremos para ingresos)
          double newBalance = transaction.type == 'INCOME' 
              ? currentBalance + transaction.amount 
              : currentBalance - transaction.amount;
          
          batch.update(accountRef, {
            'amount': newBalance,
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
      final ref = _transactionsRef;
      if (ref == null) return;
      await ref.doc(t.id).update(t.toMap());
    } catch (e) {
      print("Error updateTransaction: $e");
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final ref = _transactionsRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteTransaction: $e");
    }
  }

  Stream<List<TransactionModel>> getTransactions({int? month, int? year}) {
    final ref = _transactionsRef;
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
    final ref = _transactionsRef;
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
      final ref = _transactionsRef;
      if (ref == null) return;
      DateTime start = DateTime(year, month, 1);
      DateTime end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
      final docs = await ref.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end)).get();
      final batch = _db.batch();
      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Error clearMonth: $e");
    }
  }

  // --- PLANTILLAS ---

  Stream<List<Map<String, dynamic>>> getTemplates({String? type}) {
    final ref = _templatesRef;
    if (ref == null) return Stream.value([]);
    Query query = ref;
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots().map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  Future<void> addTemplate(Map<String, dynamic> t) async {
    try {
      final ref = _templatesRef;
      if (ref == null) return;
      await ref.add(t);
    } catch (e) {
      print("Error addTemplate: $e");
    }
  }

  Future<void> updateTemplate(String id, Map<String, dynamic> data) async {
    try {
      final ref = _templatesRef;
      if (ref == null) return;
      await ref.doc(id).update(data);
    } catch (e) {
      print("Error updateTemplate: $e");
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      final ref = _templatesRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteTemplate: $e");
    }
  }

  // --- LÓGICA DE NEGOCIO ---

  Future<void> completeTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    required String accountId,
    required bool isUndoing, // True si estamos pasando de Completado a Pendiente
  }) async {
    try {
      final batch = _db.batch();
      final transRef = _transactionsRef!.doc(transaction.id);
      final accountRef = _balancesRef!.doc(accountId);

      // 1. Actualizar estado de la transacción
      batch.update(transRef, {
        'isCompleted': !isUndoing, 
        'isPaid': !isUndoing,
        'paidFromAccountId': isUndoing ? null : accountId,
      });

      // 2. Actualizar el saldo de la cuenta
      final accountDoc = await accountRef.get();
      if (!accountDoc.exists) return;
      
      double currentBalance = (accountDoc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
      double transactionAmount = transaction.amount;
      
      double newBalance;
      if (transaction.type == 'EXPENSE') {
        // Si es gasto y lo pagamos: restamos. Si deshacemos el pago: sumamos.
        newBalance = isUndoing ? currentBalance + transactionAmount : currentBalance - transactionAmount;
      } else {
        // Si es ingreso y se completa: sumamos. Si deshacemos: restamos.
        newBalance = isUndoing ? currentBalance - transactionAmount : currentBalance + transactionAmount;
      }

      batch.update(accountRef, {
        'amount': newBalance,
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
      final refT = _templatesRef;
      final refE = _transactionsRef;
      if (refT == null || refE == null) return;
      final templatesDocs = await refT.get();
      final startQuery = DateTime(year, month, 1).subtract(const Duration(days: 2));
      final endQuery = DateTime(year, month + 1, 1).add(const Duration(days: 2));
      final existingDocs = await refE.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startQuery)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(endQuery)).get();
      final Set<String> existingTitles = existingDocs.docs.map((doc) => doc.data() as Map<String, dynamic>).where((data) {
        final DateTime d = (data['date'] as Timestamp).toDate();
        return d.month == month && d.year == year;
      }).map((data) => _norm(data['title'] ?? '')).toSet();
      final batch = _db.batch();
      bool addedAny = false;
      for (var doc in templatesDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String title = data['title'] ?? 'Sin título';
        if (!existingTitles.contains(_norm(title))) {
          final newRef = refE.doc();
          
          double initialAmount = (data['defaultAmount'] ?? 0.0).toDouble();
          String initialDesc = data['defaultDescription'] ?? '';
          
          // Lógica para suscripciones de tarjeta
          if (data['isCreditCard'] == true && data['subscriptions'] != null) {
            final List subs = data['subscriptions'] as List;
            for (var sub in subs) {
              final subName = sub['name'] ?? 'Sub';
              final subAmt = (sub['amount'] ?? 0.0).toDouble();
              initialAmount += subAmt;
              // Usamos el formato "Concepto (Detalle) - Monto" para consistencia con cuotas
              final subDetail = "$subName (Fijo) - ${_formatAmount(subAmt, data['currency'] ?? 'UYU')}";
              initialDesc = initialDesc.isEmpty ? subDetail : "$initialDesc, $subDetail";
            }
          }

          batch.set(newRef, {
            'title': title,
            'amount': initialAmount,
            'date': Timestamp.fromDate(DateTime(year, month, 1, 12, 0, 0)),
            'dueDate': data['dueDay'] != null ? Timestamp.fromDate(DateTime(year, month, data['dueDay'])) : null,
            'category': data['category'] ?? (data['type'] == 'INCOME' ? 'Ingreso' : 'Fijo'),
            'currency': data['currency'] ?? 'UYU',
            'isCompleted': false,
            'type': data['type'] ?? 'EXPENSE',
            'description': initialDesc,
            'brandLogo': data['brandLogo'], // Sincronizar el logo manual
            'includedInCard': data['includedInCard'] ?? false,
          });
          addedAny = true;
          existingTitles.add(_norm(title));
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
  }) async {
    try {
      final ref = _transactionsRef;
      final tRef = _templatesRef;
      if (ref == null || tRef == null) return;

      // 1. Intentar obtener datos de la plantilla de esta tarjeta
      int? dueDay;
      String? cardLogo;
      final templates = await tRef.get();
      final cardTemplate = templates.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _norm(data['title'] ?? '') == _norm(cardName);
      }).firstOrNull;
      
      if (cardTemplate != null) {
        final cardData = cardTemplate.data() as Map<String, dynamic>;
        dueDay = cardData['dueDay'];
        cardLogo = cardData['brandLogo'];
      }

      double amountPerMonth = totalAmount / installments;
      for (int i = 0; i < installments; i++) {
        DateTime targetDate = DateTime(startDate.year, startDate.month + 1 + i, 1, 12, 0, 0);
        int targetM = targetDate.month;
        int targetY = targetDate.year;
        
        final startQuery = DateTime(targetY, targetM, 1).subtract(const Duration(days: 2));
        final endQuery = DateTime(targetY, targetM + 1, 1).add(const Duration(days: 2));
        
        final existing = await ref.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startQuery)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(endQuery)).get();
        
        final existingCardDoc = existing.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final DateTime d = (data['date'] as Timestamp).toDate();
          return d.month == targetM && d.year == targetY && _norm(data['title'] ?? '') == _norm(cardName);
        }).firstOrNull;

        String detail = concept != null ? "$concept (${i + 1}/$installments) - ${_formatAmount(amountPerMonth, currency)}" : "Cuota ${i + 1}/$installments - ${_formatAmount(amountPerMonth, currency)}";
        
        // Fecha de vencimiento para este mes específico
        Timestamp? dueDateTs = dueDay != null ? Timestamp.fromDate(DateTime(targetY, targetM, dueDay)) : null;

        if (existingCardDoc != null) {
          final data = existingCardDoc.data() as Map<String, dynamic>;
          double currentAmount = (data['amount'] ?? 0.0).toDouble();
          String? existingDesc = data['description'];
          String newDesc = (existingDesc == null || existingDesc.isEmpty) ? detail : "$existingDesc, $detail";
          
          await ref.doc(existingCardDoc.id).update({
            'amount': currentAmount + amountPerMonth, 
            'description': newDesc, 
            'isCompleted': false,
            'dueDate': dueDateTs,
            'brandLogo': cardLogo
          });
        } else {
          await ref.add({
            'title': cardName, 
            'description': detail, 
            'amount': amountPerMonth, 
            'date': Timestamp.fromDate(targetDate), 
            'category': category ?? 'Tarjeta', 
            'currency': currency, 
            'type': 'EXPENSE', 
            'isCompleted': false,
            'dueDate': dueDateTs,
            'brandLogo': cardLogo
          });
        }
      }
    } catch (e) {
      print("Error addCreditCardExpense: $e");
    }
  }

  Future<void> removeCreditCardExpense({required String cardName, required String fullItemText, required DateTime startDate}) async {
    try {
      final ref = _transactionsRef;
      if (ref == null) return;

      // 1. Descomponer el texto para obtener el concepto y el monto a restar
      // Formato esperado: "Concepto (Cuota X/Y) - $1.234,56"
      final parts = fullItemText.split(' - ');
      if (parts.length < 2) return;
      
      final conceptWithInstallment = parts[0]; // "Concepto (Cuota X/Y)"
      
      // Limpiar el monto: quitar símbolos de moneda y puntos de miles, convertir coma a punto
      String amountClean = parts[1]
          .replaceAll(r'$', '')
          .replaceAll(r'U$S', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      
      final double amountToSubtract = double.tryParse(amountClean) ?? 0;
      if (amountToSubtract <= 0) return;

      // Extraer el concepto base (lo que está antes del paréntesis)
      final conceptBase = conceptWithInstallment.contains(' (') 
          ? conceptWithInstallment.substring(0, conceptWithInstallment.lastIndexOf(' (')) 
          : conceptWithInstallment;

      // 2. Buscar en los próximos 36 meses (cubriendo cualquier plan de cuotas largo)
      for (int i = 0; i < 36; i++) {
        DateTime targetDate = DateTime(startDate.year, startDate.month + i, 1, 12, 0, 0);
        int targetM = targetDate.month;
        int targetY = targetDate.year;

        final startQuery = DateTime(targetY, targetM, 1).subtract(const Duration(days: 2));
        final endQuery = DateTime(targetY, targetM + 1, 1).add(const Duration(days: 2));
        
        final snapshot = await ref
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startQuery))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endQuery))
            .get();

        final cardDoc = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final DateTime d = (data['date'] as Timestamp).toDate();
          return d.month == targetM && d.year == targetY && _norm(data['title'] ?? '') == _norm(cardName);
        }).firstOrNull;

        if (cardDoc != null) {
          final data = cardDoc.data() as Map<String, dynamic>;
          String desc = data['description'] ?? '';
          double currentTotal = (data['amount'] ?? 0.0).toDouble();
          
          List<String> items = desc.split(', ').where((s) => s.isNotEmpty).toList();
          
          bool foundInThisMonth = false;
          final newItems = items.where((item) {
            // Buscamos si el ítem de este mes empieza con el concepto base
            if (item.startsWith('$conceptBase (')) {
              foundInThisMonth = true;
              return false; // Lo eliminamos de la lista
            }
            return true;
          }).toList();

          if (foundInThisMonth) {
            await ref.doc(cardDoc.id).update({
              'description': newItems.join(', '),
              'amount': (currentTotal - amountToSubtract).clamp(0.0, double.infinity)
            });
          }
        }
      }
    } catch (e) {
      print("Error removeCreditCardExpense: $e");
    }
  }

  String _formatAmount(double amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: 'es_UY',
      symbol: currency == 'UYU' ? r'$' : r'U$S',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Future<void> createTemplateFromTransaction(TransactionModel t) async {
    try {
      final ref = _templatesRef;
      if (ref == null) return;
      
      await ref.add({
        'title': t.title,
        'currency': t.currency,
        'dueDay': t.dueDate?.day ?? t.date.day,
        'type': t.type,
        'category': t.category == 'Extra' ? (t.type == 'EXPENSE' ? 'Fijo' : 'Ingreso') : t.category,
        'isCreditCard': false,
        'defaultAmount': t.amount, // Guardamos un monto por defecto
        'brandLogo': t.brandLogo, // Sincronizamos también el logo si existe
      });
    } catch (e) {
      print("Error createTemplateFromTransaction: $e");
    }
  }

  // --- METAS / GOALS ---

  Stream<List<Map<String, dynamic>>> getGoals() {
    final ref = _goalsRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) => snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList());
  }

  Future<void> addGoal(Map<String, dynamic> data) async {
    try {
      final ref = _goalsRef;
      if (ref == null) return;
      await ref.add({
        ...data,
        'currentAmount': data['currentAmount'] ?? 0.0,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error addGoal: $e");
    }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      final ref = _goalsRef;
      if (ref == null) return;
      await ref.doc(id).update(data);
    } catch (e) {
      print("Error updateGoal: $e");
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      final ref = _goalsRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteGoal: $e");
    }
  }

  // --- TRANSFERENCIAS ---

  Future<void> transferFunds({
    required String fromAccountId,
    required double amount,
    String? toAccountId,
    String? toGoalId,
  }) async {
    try {
      final batch = _db.batch();
      final fromRef = _balancesRef!.doc(fromAccountId);
      
      // 1. Restar de la cuenta origen
      final fromDoc = await fromRef.get();
      final double fromCurrent = (fromDoc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
      batch.update(fromRef, {'amount': fromCurrent - amount, 'updatedAt': Timestamp.now()});

      // 2. Sumar al destino (Cuenta o Meta)
      if (toAccountId != null) {
        final toRef = _balancesRef!.doc(toAccountId);
        final toDoc = await toRef.get();
        final double toCurrent = (toDoc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
        batch.update(toRef, {'amount': toCurrent + amount, 'updatedAt': Timestamp.now()});
      } else if (toGoalId != null) {
        final goalRef = _goalsRef!.doc(toGoalId);
        final goalDoc = await goalRef.get();
        final double goalCurrent = (goalDoc.data() as Map<String, dynamic>)['currentAmount'] ?? 0.0;
        batch.update(goalRef, {'currentAmount': goalCurrent + amount});
      }

      await batch.commit();
    } catch (e) {
      print("Error transferFunds: $e");
      rethrow;
    }
  }

}
