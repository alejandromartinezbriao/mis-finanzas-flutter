import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  String _norm(String text) => text.trim().toLowerCase();

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
    
    if (month != null && year != null) {
      final startQuery = DateTime(year, month, 1).subtract(const Duration(days: 2));
      final endQuery = DateTime(year, month + 1, 1).add(const Duration(days: 2));
      
      return ref
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startQuery))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endQuery))
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).where((t) => t.date.month == month && t.date.year == year).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
          });
    }

    return ref.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> clearMonth(int month, int year) async {
    try {
      final ref = _transactionsRef;
      if (ref == null) return;
      final start = DateTime(year, month, 1).subtract(const Duration(days: 2));
      final end = DateTime(year, month + 1, 1).add(const Duration(days: 2));
      final snapshot = await ref.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(end)).get();
      final batch = _db.batch();
      bool deletedAny = false;
      for (var doc in snapshot.docs) {
        final d = (doc.data() as Map<String, dynamic>)['date'] as Timestamp;
        final date = d.toDate();
        if (date.month == month && date.year == year) {
          batch.delete(doc.reference);
          deletedAny = true;
        }
      }
      if (deletedAny) await batch.commit();
    } catch (e) {
      print("Error clearMonth: $e");
    }
  }

  // --- PLANTILLAS ---

  Stream<List<Map<String, dynamic>>> getTemplates({String? type}) {
    final ref = _templatesRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      if (type != null) list = list.where((t) => t['type'] == type).toList();
      return list;
    });
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

  Future<void> addCreditCardExpense({required String cardName, required double totalAmount, required int installments, required String currency, required DateTime startDate, String? concept}) async {
    try {
      final ref = _transactionsRef;
      final tRef = _templatesRef;
      if (ref == null || tRef == null) return;

      // 1. Intentar obtener el día de vencimiento de la plantilla de esta tarjeta
      int? dueDay;
      final templates = await tRef.get();
      final cardTemplate = templates.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _norm(data['title'] ?? '') == _norm(cardName);
      }).firstOrNull;
      
      if (cardTemplate != null) {
        dueDay = (cardTemplate.data() as Map<String, dynamic>)['dueDay'];
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
            'dueDate': dueDateTs // Aseguramos que tenga fecha de vencimiento al actualizar
          });
        } else {
          await ref.add({
            'title': cardName, 
            'description': detail, 
            'amount': amountPerMonth, 
            'date': Timestamp.fromDate(targetDate), 
            'category': 'Tarjeta', 
            'currency': currency, 
            'type': 'EXPENSE', 
            'isCompleted': false,
            'dueDate': dueDateTs // Ponemos la fecha de vencimiento al crear
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
      final parts = fullItemText.split(' - ');
      if (parts.length < 2) return;
      final conceptWithInstallment = parts[0];
      final amountStr = parts[1].replaceAll('\$', '').replaceAll('U\$S', '').replaceAll(',', '');
      final double amountToSubtract = double.tryParse(amountStr) ?? 0;
      final conceptBase = conceptWithInstallment.contains(' (') ? conceptWithInstallment.substring(0, conceptWithInstallment.lastIndexOf(' (')) : conceptWithInstallment;
      for (int i = 0; i < 24; i++) {
        DateTime targetDate = DateTime(startDate.year, startDate.month + i, 1, 12, 0, 0);
        final startQuery = DateTime(targetDate.year, targetDate.month, 1).subtract(const Duration(days: 2));
        final endQuery = DateTime(targetDate.year, targetDate.month + 1, 1).add(const Duration(days: 2));
        final snapshot = await ref.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startQuery)).where('date', isLessThanOrEqualTo: Timestamp.fromDate(endQuery)).get();
        final cardDoc = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final DateTime d = (data['date'] as Timestamp).toDate();
          return d.month == targetDate.month && d.year == targetDate.year && _norm(data['title'] ?? '') == _norm(cardName);
        }).firstOrNull;
        if (cardDoc != null) {
          final data = cardDoc.data() as Map<String, dynamic>;
          String desc = data['description'] ?? '';
          double currentTotal = (data['amount'] ?? 0.0).toDouble();
          List<String> items = desc.split(', ').where((s) => s.isNotEmpty).toList();
          bool foundAny = false;
          final newItems = items.where((item) {
            if (item.startsWith(conceptBase + ' (')) {
              foundAny = true;
              return false;
            }
            return true;
          }).toList();
          if (foundAny) {
            await ref.doc(cardDoc.id).update({'description': newItems.join(', '), 'amount': (currentTotal - amountToSubtract).clamp(0.0, double.infinity)});
          }
        }
      }
    } catch (e) {
      print("Error removeCreditCardExpense: $e");
    }
  }

  String _formatAmount(double amount, String currency) {
    if (currency == 'UYU') return "\$${amount.toStringAsFixed(0)}";
    return "U\$S${amount.toStringAsFixed(2)}";
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
      });
    } catch (e) {
      print("Error createTemplateFromTransaction: $e");
    }
  }
}
