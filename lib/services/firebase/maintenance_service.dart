import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_base.dart';

mixin MaintenanceService on FirebaseBase {
  /// Normalización ultra-agresiva para evitar fallos por espacios o sufijos
  String _deepNorm(String text) {
    return text.trim()
        .toLowerCase()
        .replaceAll(RegExp(r' \((uyu|usd)\)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }


  /// MANTENIMIENTO: Encuentra gastos que no tienen templateId pero coinciden en nombre
  Future<List<Map<String, dynamic>>> findTemplateReconnections() async {
    try {
      final refT = templatesRef; final refE = transactionsRef;
      if (refT == null || refE == null) return [];
      
      final tSnap = await refT.get();
      final templates = tSnap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();

      final eSnap = await refE.get();
      final List<Map<String, dynamic>> proposals = [];

      for (var doc in eSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['templateId'] != null) continue;

        final String cleanT = _deepNorm(data['title'] ?? '');
        final match = templates.where((t) => _deepNorm(t['title'] ?? '') == cleanT && t['currency'] == data['currency']).firstOrNull;
        
        if (match != null) {
          final dt = (data['date'] as Timestamp).toDate();
          proposals.add({
            'docId': doc.id,
            'title': data['title'],
            'month': "${dt.year}-${dt.month.toString().padLeft(2, '0')}",
            'templateId': match['id'],
            'templateTitle': match['title'],
            'brandLogo': match['brandLogo'],
          });
        }
      }
      return proposals;
    } catch (e) { return []; }
  }

  Future<void> applyTemplateReconnections(List<Map<String, dynamic>> selections) async {
    try {
      final refE = transactionsRef; if (refE == null) return;
      WriteBatch batch = db.batch(); int ops = 0;
      for (var sel in selections) {
        batch.update(refE.doc(sel['docId']), {
          'templateId': sel['templateId'],
          'brandLogo': sel['brandLogo'],
          'title': sel['templateTitle']
        });
        ops++;
        if (ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
      }
      if (ops > 0) await batch.commit();
    } catch (e) {}
  }

  /// SINCRONIZADOR: Propone correcciones de cuotas basándose en "votos" de otros meses
  Future<List<Map<String, dynamic>>> findSyncProposals() async {
    try {
      final refE = transactionsRef; if (refE == null) return [];
      final allSnap = await refE.get();
      final Map<String, Map<double, int>> votes = {};
      final regex = RegExp(r"^(.*) \((\d+)\/(\d+)\) - (.*)$");

      for (var doc in allSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String desc = data['description'] ?? '';
        for (var part in desc.split(', ')) {
          final m = regex.firstMatch(part.trim());
          if (m != null) {
            final String key = "${_deepNorm(m.group(1)!)}_${m.group(3)}_${data['currency']}";
            final double val = parseAmount(m.group(4)!);
            votes.putIfAbsent(key, () => {});
            votes[key]![val] = (votes[key]![val] ?? 0) + 1;
          }
        }
      }

      final Map<String, double> masters = {};
      votes.forEach((key, v) {
        double winner = 0; int maxV = 0;
        v.forEach((amt, count) { if (count > maxV || (count == maxV && amt > winner)) { winner = amt; maxV = count; } });
        masters[key] = winner;
      });

      final List<Map<String, dynamic>> proposals = [];
      for (var doc in allSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String desc = data['description'] ?? ''; if (desc.isEmpty) continue;
        
        for (var part in desc.split(', ')) {
          final m = regex.firstMatch(part.trim());
          if (m != null) {
            final double current = parseAmount(m.group(4)!);
            final double winner = masters["${_deepNorm(m.group(1)!)}_${m.group(3)}_${data['currency']}"] ?? current;
            
            if (current != winner) {
              final dt = (data['date'] as Timestamp).toDate();
              proposals.add({
                'docId': doc.id,
                'cardTitle': data['title'],
                'month': "${dt.year}-${dt.month}",
                'concept': m.group(1),
                'installment': "${m.group(2)}/${m.group(3)}",
                'currentValue': current,
                'suggestedValue': winner,
                'currency': data['currency'],
              });
            }
          }
        }
      }
      return proposals;
    } catch (e) { return []; }
  }

  Future<void> applySyncFixes(List<Map<String, dynamic>> fixes) async {
    try {
      final refE = transactionsRef; if (refE == null) return;
      final Map<String, List<Map<String, dynamic>>> byDoc = {};
      for (var f in fixes) { byDoc.putIfAbsent(f['docId'], () => []); byDoc[f['docId']]!.add(f); }

      WriteBatch batch = db.batch(); int ops = 0;
      for (var docId in byDoc.keys) {
        final docRef = refE.doc(docId);
        final snap = await docRef.get(); if (!snap.exists) continue;
        final data = snap.data() as Map<String, dynamic>;
        String desc = data['description'] ?? '';
        double total = 0; List<String> newParts = [];

        for (var part in desc.split(', ')) {
          if (part.trim().isEmpty) continue;
          final double partValue = parseAmount(part.split(' - ').last);
          bool fixed = false;
          
          for (var fix in byDoc[docId]!) {
            // Comparamos el concepto y el número de cuota para identificar la línea
            if (part.contains("${fix['concept']} (${fix['installment']})")) {
              newParts.add("${fix['concept']} (${fix['installment']}) - ${formatAmount(fix['suggestedValue'], data['currency'])}");
              total += fix['suggestedValue']; fixed = true; break;
            }
          }
          if (!fixed) { 
            total += partValue; 
            final String label = part.contains(' - ') ? part.split(' - ').first : part;
            newParts.add("$label - ${formatAmount(partValue, data['currency'])}");
          }
        }
        batch.update(docRef, {'description': newParts.join(', '), 'amount': round(total)});
        ops++; if (ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
      }
      if (ops > 0) await batch.commit();
    } catch (e) {}
  }

  /// REPARACIÓN: Encuentra duplicados dentro de la misma descripción de tarjeta
  Future<List<Map<String, dynamic>>> findDeepRepairProposals() async {
    try {
      final refE = transactionsRef; if (refE == null) return [];
      final snap = await refE.get();
      final regex = RegExp(r"^(.*) \((\d+)\/(\d+)\) - (.*)$");
      final List<Map<String, dynamic>> proposals = [];

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String desc = data['description'] ?? ''; if (desc.isEmpty) continue;
        final Map<String, int> counts = {};

        for (var part in desc.split(', ')) {
          final m = regex.firstMatch(part.trim());
          if (m != null) {
            final String key = "${m.group(1)} (${m.group(2)}/${m.group(3)})";
            counts[key] = (counts[key] ?? 0) + 1;
          }
        }

        bool hasDuplicates = counts.values.any((c) => c > 1);
        if (hasDuplicates) {
          final dt = (data['date'] as Timestamp).toDate();
          proposals.add({
            'docId': doc.id,
            'title': data['title'],
            'month': "${dt.year}-${dt.month}",
            'duplicates': counts.entries.where((e) => e.value > 1).map((e) => e.key).toList(),
          });
        }
      }
      return proposals;
    } catch (e) { return []; }
  }

  Future<void> applyDeepRepairFixes(List<Map<String, dynamic>> selections) async {
    try {
      final refE = transactionsRef; if (refE == null) return;
      WriteBatch batch = db.batch(); int ops = 0;
      final regex = RegExp(r"^(.*) \((\d+)\/(\d+)\) - (.*)$");

      for (var sel in selections) {
        final docRef = refE.doc(sel['docId']);
        final snap = await docRef.get(); if (!snap.exists) continue;
        final data = snap.data() as Map<String, dynamic>;
        String desc = data['description'] ?? '';
        final Map<String, double> unique = {};

        for (var part in desc.split(', ')) {
          final m = regex.firstMatch(part.trim());
          if (m != null) {
            final String key = "${m.group(1)} (${m.group(2)}/${m.group(3)})";
            final double val = parseAmount(m.group(4)!);
            if (!unique.containsKey(key) || val > unique[key]!) unique[key] = val;
          } else if (part.contains(' - ')) {
             final parts = part.split(' - ');
             unique[parts.first] = parseAmount(parts.last);
          }
        }

        double tot = 0; List<String> parts = [];
        unique.forEach((k, v) { tot += v; parts.add("$k - ${formatAmount(v, data['currency'])}"); });
        batch.update(docRef, {'description': parts.join(', '), 'amount': round(tot)});
        ops++; if (ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
      }
      if (ops > 0) await batch.commit();
    } catch (e) {}
  }

  /// DUPLICADOS GLOBALES: Detecta inconsistencias de nombre y duplicados en el mismo mes
  Future<List<Map<String, dynamic>>> findGlobalDuplicates() async {
    try {
      final refE = transactionsRef; if (refE == null) return [];
      final snap = await refE.get();
      final Map<String, Map<String, List<DocumentSnapshot>>> groups = {};

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['date'] == null) continue; // Protección anti-nulos
        final String gKey = "${_deepNorm(data['title'] ?? '')}_${data['currency'] ?? 'UYU'}";
        final dt = (data['date'] as Timestamp).toDate();
        final String mKey = "${dt.year}_${dt.month}";
        groups.putIfAbsent(gKey, () => {});
        groups[gKey]!.putIfAbsent(mKey, () => []);
        groups[gKey]![mKey]!.add(doc);
      }

      final List<Map<String, dynamic>> res = [];
      groups.forEach((key, months) {
        Set<String> titles = {}; bool hasD = false;
        months.forEach((m, docs) { if (docs.length > 1) hasD = true; for (var d in docs) {
          titles.add((d.data() as Map<String, dynamic>)['title'] ?? '');
        } });
        if (titles.length > 1 || hasD) {
          final p = key.split('_');
          res.add({'baseName': _capitalize(p[0]), 'currency': p[p.length - 1].toUpperCase(), 'variations': titles.toList()});
        }
      });
      return res;
    } catch (e) { print("Error Find Dupes: $e"); return []; }
  }

  Future<void> unifyGlobalTransactions(String base, String cur, List<String> vars) async {
    try {
      final refE = transactionsRef; if (refE == null) return;
      final snap = await refE.get(); final Map<String, List<DocumentSnapshot>> mGroups = {};
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (vars.contains(data['title']) && data['currency'] == cur) {
          if (data['date'] == null) continue;
          final dt = (data['date'] as Timestamp).toDate();
          mGroups.putIfAbsent("${dt.year}_${dt.month}", () => []);
          mGroups["${dt.year}_${dt.month}"]!.add(doc);
        }
      }
      WriteBatch batch = db.batch(); int ops = 0;
      for (var group in mGroups.values) {
        final surv = group.first;
        if (group.length == 1) { batch.update(surv.reference, {'title': "$base ($cur)"}); ops++; }
        else {
          double tot = 0; List<String> descs = [];
          for (var doc in group) {
            final d = doc.data() as Map<String, dynamic>; tot += (d['amount'] ?? 0.0).toDouble();
            if (d['description'] != null) descs.add(d['description']);
            if (doc.id != surv.id) { batch.delete(doc.reference); ops++; }
          }
          batch.update(surv.reference, {'title': "$base ($cur)", 'amount': round(tot), 'description': descs.join(', ')}); ops++;
        }
        if (ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
      }
      if (ops > 0) await batch.commit();
    } catch (e) {}
  }

  Future<List<Map<String, dynamic>>> findLostInstallments() async {
    try {
      final refE = transactionsRef; if (refE == null) return [];
      final all = await refE.get(); final Map<String, Map<String, dynamic>> found = {};
      final regex = RegExp(r"^(.*) \((\d+)\/(\d+)\) - (.*)$");
      for (var doc in all.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String desc = data['description'] ?? ''; if (desc.isEmpty) continue;
        for (var part in desc.split(', ')) {
          final m = regex.firstMatch(part.trim());
          if (m != null) {
            final int cur = int.parse(m.group(2)!);
            final String key = "${_deepNorm(data['title'] ?? '')}_${_deepNorm(m.group(1)!)}_${m.group(3)}_${data['currency']}";
            if (!found.containsKey(key)) {
              found[key] = {
                'cardName': data['title'] ?? '', 'concept': m.group(1), 'totalInstallments': int.parse(m.group(3)!),
                'amountPerInstallment': parseAmount(m.group(4)!), 'currency': data['currency'],
                'startDate': DateTime((data['date'] as Timestamp).toDate().year, (data['date'] as Timestamp).toDate().month - (cur - 1), 1),
                'foundInstallments': <int, bool>{}, 'brandLogo': data['brandLogo'],
              };
            }
            if (parseAmount(m.group(4)!) > found[key]!['amountPerInstallment']) {
              found[key]!['amountPerInstallment'] = parseAmount(m.group(4)!);
            }
            (found[key]!['foundInstallments'] as Map<int, bool>)[cur] = true;
          }
        }
      }
      return found.values.where((p) => (p['foundInstallments'] as Map).length < p['totalInstallments']).map((p) {
        List<int> miss = []; for (int i = 1; i <= p['totalInstallments']; i++) { if (!(p['foundInstallments'] as Map).containsKey(i)) miss.add(i); }
        return {...p, 'missingInstallments': miss};
      }).toList();
    } catch (e) { return []; }
  }

  Future<void> recoverInstallments(List<Map<String, dynamic>> recs) async {
    try {
      final refE = transactionsRef; if (refE == null) return;
      final snap = await refE.get();
      final local = snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id, 'ref': doc.reference}).toList();
      WriteBatch batch = db.batch(); int ops = 0;
      for (var r in recs) {
        for (int inst in List<int>.from(r['missingInstallments'])) {
          DateTime target = DateTime(r['startDate'].year, r['startDate'].month + (inst - 1), 1, 12, 0, 0);
          final exist = local.where((d) {
            if (d['date'] == null) return false;
            final dt = (d['date'] as Timestamp).toDate();
            return dt.month == target.month && dt.year == target.year && _deepNorm(d['title'] ?? '') == _deepNorm(r['cardName']) && d['currency'] == r['currency'];
          }).firstOrNull;
          String det = "${r['concept']} ($inst/${r['totalInstallments']}) - ${formatAmount(r['amountPerInstallment'], r['currency'])}";
          if (exist != null) {
            if (!(exist['description'] ?? '').toString().contains("${r['concept']} ($inst/")) {
              batch.update(exist['ref'], {'amount': round((exist['amount'] ?? 0.0) + r['amountPerInstallment']), 'description': (exist['description'] ?? '').toString().isEmpty ? det : "${exist['description']}, $det"});
              ops++;
            }
          } else {
            batch.set(refE.doc(), {'title': "${_capitalize(_deepNorm(r['cardName']))} (${r['currency']})", 'description': det, 'amount': round(r['amountPerInstallment']), 'date': Timestamp.fromDate(target), 'category': 'Tarjeta', 'currency': r['currency'], 'type': 'EXPENSE', 'isCompleted': false, 'brandLogo': r['brandLogo']});
            ops++;
          }
          if (ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
        }
      }
      if (ops > 0) await batch.commit();
    } catch (e) {}
  }

  /// DETECCIÓN: Encuentra montos sospechosos (posibles multiplicados por 100)
  Future<List<Map<String, dynamic>>> findBotchedDecimals() async {
    try {
      final refE = transactionsRef; if (refE == null) return [];
      final snap = await refE.get();
      final partRegex = RegExp(r"^(.*) \((\d+)\/(\d+)\) - (.*)$");
      final List<Map<String, dynamic>> detections = [];

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String desc = data['description'] ?? ''; if (desc.isEmpty) continue;
        
        for (var part in desc.split(', ')) {
          final m = partRegex.firstMatch(part.trim());
          double? val;
          String? label;

          if (m != null) {
            val = parseAmount(m.group(4)!);
            label = "${m.group(1)} (${m.group(2)}/${m.group(3)})";
          } else if (part.contains(' - ')) {
            val = parseAmount(part.split(' - ').last);
            label = part.split(' - ').first;
          }

          // Heurística de sospecha: Entero, >= 500
          if (val != null && val >= 500 && val == val.truncateToDouble()) {
            final dt = (data['date'] as Timestamp).toDate();
            detections.add({
              'docId': doc.id,
              'fullDescription': desc,
              'title': data['title'],
              'monthLabel': "${dt.year}-${dt.month.toString().padLeft(2, '0')}",
              'partLabel': label ?? 'Gasto',
              'originalValue': val,
              'suggestedValue': val / 100.0,
              'currency': data['currency'],
            });
          }
        }
      }
      return detections;
    } catch (e) { return []; }
  }

  Future<void> applyBotchedFixes(List<Map<String, dynamic>> fixes) async {
    try {
      final refE = transactionsRef; if (refE == null) return;
      WriteBatch batch = db.batch(); int ops = 0;
      
      final Map<String, List<Map<String, dynamic>>> byDoc = {};
      for (var f in fixes) {
        byDoc.putIfAbsent(f['docId'], () => []);
        byDoc[f['docId']]!.add(f);
      }

      for (var docId in byDoc.keys) {
        final docRef = refE.doc(docId);
        final docSnap = await docRef.get();
        if (!docSnap.exists) continue;
        
        final data = docSnap.data() as Map<String, dynamic>;
        String desc = data['description'] ?? '';
        final List<Map<String, dynamic>> docFixes = byDoc[docId]!;
        
        double totalAmount = 0;
        List<String> newParts = [];
        
        for (var part in desc.split(', ')) {
          if (part.trim().isEmpty) continue;
          
          // Extraemos el valor actual de esta parte específica de la descripción
          final double partValue = parseAmount(part.split(' - ').last);
          bool wasFixed = false;

          for (var fix in docFixes) {
            // Comparamos los valores numéricos con un margen de error pequeño para decimales
            if ((partValue - fix['originalValue']).abs() < 0.01) {
              final double newVal = fix['suggestedValue'];
              final String label = part.contains(' - ') ? part.split(' - ').first : part;
              // REGLA DE ORO: Escribimos el nuevo valor SIN COMAS
              newParts.add("$label - ${formatAmount(newVal, data['currency'] ?? 'UYU')}");
              totalAmount += newVal;
              wasFixed = true;
              break;
            }
          }

          if (!wasFixed) {
            // Si no se corrigió, limpiamos la parte de comas de todos modos para normalizar
            final String label = part.contains(' - ') ? part.split(' - ').first : part;
            newParts.add("$label - ${formatAmount(partValue, data['currency'] ?? 'UYU')}");
            totalAmount += partValue;
          }
        }

        batch.update(docRef, {
          'description': newParts.join(', '),
          'amount': round(totalAmount)
        });
        ops++;
        if (ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
      }
      if (ops > 0) await batch.commit();
    } catch (e) {
      print("Error applyBotchedFixes: $e");
    }
  }

  /// NORMALIZACIÓN: Elimina comas de todas las descripciones de la base de datos
  Future<int> normalizeAllDescriptions() async {
    try {
      final refE = transactionsRef; if (refE == null) return 0;
      final snap = await refE.get();
      WriteBatch batch = db.batch(); int ops = 0; int fixed = 0;

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String desc = data['description'] ?? ''; if (desc.isEmpty) continue;
        
        List<String> newParts = [];
        double totalAmount = 0;
        bool changed = false;

        for (var part in desc.split(', ')) {
          if (part.trim().isEmpty) continue;
          final double val = parseAmount(part.split(' - ').last);
          final String label = part.contains(' - ') ? part.split(' - ').first : part;
          final String cleanPart = "$label - ${formatAmount(val, data['currency'] ?? 'UYU')}";
          
          if (part.trim() != cleanPart) changed = true;
          newParts.add(cleanPart);
          totalAmount += val;
        }

        if (changed) {
          batch.update(doc.reference, {
            'description': newParts.join(', '),
            'amount': round(totalAmount)
          });
          fixed++; ops++;
        }
        if (ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
      }
      if (ops > 0) await batch.commit();
      return fixed;
    } catch (e) { return 0; }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
