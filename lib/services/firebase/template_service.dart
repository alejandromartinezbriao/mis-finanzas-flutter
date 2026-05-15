import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';
import '../../models/transaction_model.dart';

mixin TemplateService on FirebaseBase {
  // --- BUSCADOR DE GEMELAS PARA TARJETAS ---

  Future<List<Map<String, dynamic>>> findPotentialCardTwins({
    required String baseName,
    required String targetCurrency,
    String? logo,
    String? excludeId,
  }) async {
    try {
      final ref = templatesRef;
      if (ref == null) return [];

      final snapshot = await ref
          .where('type', isEqualTo: 'EXPENSE')
          .where('isCreditCard', isEqualTo: true)
          .where('currency', isEqualTo: targetCurrency)
          .get();

      final candidates = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((data) => data['id'] != excludeId)
          .toList();

      final cleanSearchName = baseName
          .replaceAll(RegExp(r'\s+(pesos|dólares|uyu|usd|dolares)$', caseSensitive: false), '')
          .trim()
          .toLowerCase();

      for (var c in candidates) {
        int score = 0;
        final cName = (c['title'] as String).toLowerCase();
        
        if (logo != null && c['brandLogo'] == logo) score += 100;
        if (cName.contains(cleanSearchName)) score += 50;
        
        final searchWords = cleanSearchName.split(' ').where((w) => w.length > 2);
        for (var word in searchWords) {
          if (cName.contains(word)) score += 10;
        }

        c['matchScore'] = score;
      }

      candidates.sort((a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int));
      return candidates;
    } catch (e) {
      print("Error findPotentialCardTwins: $e");
      return [];
    }
  }

  Future<void> upgradeTemplateToBimonetary({
    required String originalId,
    required String oldTitle,
    required Map<String, dynamic> data,
    String? existingGemelaId,
    String? oldGemelaTitle,
  }) async {
    try {
      final ref = templatesRef;
      final refE = transactionsRef;
      if (ref == null || refE == null) return;

      final batch = db.batch();
      final baseName = data['title'];
      final originalCurrency = data['currency'] ?? 'UYU';
      final newTitle = '$baseName ($originalCurrency)';

      batch.update(ref.doc(originalId), {
        ...data,
        'title': newTitle,
        'isBimonetaryPart': true,
        'baseName': baseName,
      });

      final otherCurrency = originalCurrency == 'UYU' ? 'USD' : 'UYU';
      final newGemelaTitle = '$baseName ($otherCurrency)';
      
      if (existingGemelaId != null) {
        batch.update(ref.doc(existingGemelaId), {
          'title': newGemelaTitle,
          'currency': otherCurrency,
          'isBimonetaryPart': true,
          'baseName': baseName,
          'brandLogo': data['brandLogo'],
          'isCreditCard': true,
          'type': 'EXPENSE',
        });
      } else {
        batch.set(ref.doc(), {
          ...data,
          'title': newGemelaTitle,
          'currency': otherCurrency,
          'isBimonetaryPart': true,
          'baseName': baseName,
          'defaultAmount': 0.0,
          'subscriptions': [],
        });
      }

      final expensesOriginal = await refE.where('title', isEqualTo: oldTitle).get();
      for (var doc in expensesOriginal.docs) {
        batch.update(doc.reference, {'title': newTitle});
      }

      if (existingGemelaId != null && oldGemelaTitle != null) {
        final expensesGemela = await refE.where('title', isEqualTo: oldGemelaTitle).get();
        for (var doc in expensesGemela.docs) {
          batch.update(doc.reference, {'title': newGemelaTitle});
        }
      }

      await batch.commit();
    } catch (e) {
      print("Error upgradeTemplateToBimonetary: $e");
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getTemplates({String? type}) {
    final ref = templatesRef;
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
      
      list.sort((a, b) {
        int aIdx = a['orderIndex'] ?? 999;
        int bIdx = b['orderIndex'] ?? 999;
        if (aIdx != bIdx) return aIdx.compareTo(bIdx);
        return (a['title'] as String).toLowerCase().compareTo((b['title'] as String).toLowerCase());
      });
      
      return list;
    });
  }

  Future<void> addTemplate(Map<String, dynamic> t, {bool isBimonetary = false}) async {
    try {
      final ref = templatesRef;
      if (ref == null) return;
      
      final all = await ref.get();
      int nextIndex = 0;
      for (var doc in all.docs) {
        final idx = (doc.data() as Map<String, dynamic>)['orderIndex'] ?? 0;
        if (idx >= nextIndex) nextIndex = idx + 1;
      }

      if (isBimonetary) {
        final batch = db.batch();
        final name = t['title'];

        batch.set(ref.doc(), {
          ...t,
          'title': '$name (UYU)',
          'currency': 'UYU',
          'orderIndex': nextIndex,
          'isBimonetaryPart': true,
          'baseName': name,
        });

        batch.set(ref.doc(), {
          ...t,
          'title': '$name (USD)',
          'currency': 'USD',
          'orderIndex': nextIndex + 1,
          'isBimonetaryPart': true,
          'baseName': name,
        });

        await batch.commit();
      } else {
        await ref.add({
          ...t,
          'orderIndex': nextIndex,
        });
      }
    } catch (e) {
      print("Error addTemplate: $e");
    }
  }

  Future<void> updateTemplatesOrder(List<Map<String, dynamic>> templates) async {
    try {
      final batch = db.batch();
      final ref = templatesRef;
      final expenseRef = transactionsRef;
      if (ref == null || expenseRef == null) return;

      for (int i = 0; i < templates.length; i++) {
        batch.update(ref.doc(templates[i]['id']), {'orderIndex': i});
      }

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      
      final relatedExpenses = await expenseRef
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      final Map<String, int> titleToOrder = {};
      for (int i = 0; i < templates.length; i++) {
        titleToOrder[norm(templates[i]['title'] ?? '')] = i;
      }

      for (var doc in relatedExpenses.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String title = norm(data['title'] ?? '');
        if (titleToOrder.containsKey(title)) {
          batch.update(doc.reference, {'orderIndex': titleToOrder[title]});
        }
      }

      await batch.commit();
    } catch (e) {
      print("Error updateTemplatesOrder: $e");
    }
  }

  Future<void> updateTemplate(String id, Map<String, dynamic> data) async {
    try {
      final ref = templatesRef;
      final expenseRef = transactionsRef;
      if (ref == null || expenseRef == null) return;

      final batch = db.batch();
      
      // Si es parte de un par bimonetario, debemos sincronizar los campos compartidos con su gemela
      if (data['isBimonetaryPart'] == true) {
        final String baseName = data['baseName'] ?? data['title'];
        final String currentCurrency = data['currency'] ?? 'UYU';
        
        // El título real en Firestore debe conservar el sufijo
        final String finalTitle = "$baseName ($currentCurrency)";
        final Map<String, dynamic> updatedData = {...data, 'title': finalTitle, 'baseName': baseName};
        
        batch.update(ref.doc(id), updatedData);

        // Buscar la gemela para sincronizar campos compartidos (vencimiento, logo, nombre base)
        final otherCurrency = currentCurrency == 'UYU' ? 'USD' : 'UYU';
        final twinsSnap = await ref
            .where('baseName', isEqualTo: baseName)
            .where('currency', isEqualTo: otherCurrency)
            .where('isBimonetaryPart', isEqualTo: true)
            .get();

        for (var twinDoc in twinsSnap.docs) {
          batch.update(twinDoc.reference, {
            'baseName': baseName,
            'title': "$baseName ($otherCurrency)",
            'dueDay': data['dueDay'],
            'brandLogo': data['brandLogo'],
            'category': data['category'],
            'isCreditCard': data['isCreditCard'],
          });
        }
        
        // Actualizar el logo en transacciones existentes de ambas partes
        final relatedExpenses = await expenseRef
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month - 1, 1)))
            .get();

        for (var doc in relatedExpenses.docs) {
          final docData = doc.data() as Map<String, dynamic>;
          final String docTitle = docData['title'] ?? '';
          if (docTitle == finalTitle || docTitle == "$baseName ($otherCurrency)") {
            batch.update(doc.reference, {'brandLogo': data['brandLogo']});
          }
        }
      } else {
        // Flujo normal para plantillas no bimonetarias
        batch.update(ref.doc(id), data);
        
        final String title = data['title'] ?? '';
        if (title.isNotEmpty) {
          final relatedExpenses = await expenseRef
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month - 1, 1)))
              .get();

          for (var doc in relatedExpenses.docs) {
            final docData = doc.data() as Map<String, dynamic>;
            if (norm(docData['title'] ?? '') == norm(title)) {
              batch.update(doc.reference, {'brandLogo': data['brandLogo']});
            }
          }
        }
      }

      await batch.commit();
    } catch (e) {
      print("Error updateTemplate: $e");
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      final ref = templatesRef;
      if (ref == null) return;
      await ref.doc(id).delete();
    } catch (e) {
      print("Error deleteTemplate: $e");
    }
  }

  Future<void> createTemplateFromTransaction(TransactionModel t) async {
    try {
      final ref = templatesRef;
      if (ref == null) return;
      
      await ref.add({
        'title': t.title,
        'currency': t.currency,
        'dueDay': t.dueDate?.day ?? t.date.day,
        'type': t.type,
        'category': t.category == 'Extra' ? (t.type == 'EXPENSE' ? 'Fijo' : 'Ingreso') : t.category,
        'isCreditCard': false,
        'defaultAmount': t.amount,
        'brandLogo': t.brandLogo,
      });
    } catch (e) {
      print("Error createTemplateFromTransaction: $e");
    }
  }
}
