import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../local_db_service.dart';
import 'firebase_base.dart';

mixin GoalService on FirebaseBase {
  final LocalDbService _local = LocalDbService();

  // --- METAS / GOALS ---

  Stream<List<Map<String, dynamic>>> getGoals() {
    final ref = goalsRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Sync local cache
        if (!kIsWeb) {
          _local.insert('goals', {
            'id': data['id'],
            'title': data['title'],
            'targetAmount': data['targetAmount'],
            'currentAmount': data['currentAmount'],
            'currency': data['currency'],
            'deadline': data['deadline'] != null ? (data['deadline'] as Timestamp).toDate().toIso8601String() : null,
            'linkedAccountId': data['linkedAccountId'],
            'color': data['color'],
            'icon': data['icon'],
          });
        }
        
        return data;
      }).toList();
    });
  }

  Future<void> addGoal(Map<String, dynamic> data) async {
    try {
      final ref = goalsRef;
      if (ref == null) return;

      final Map<String, dynamic> cloudData = {
        ...data,
        'currentAmount': round(data['currentAmount'] ?? 0.0),
        'createdAt': Timestamp.now(),
      };

      // 1. Nube
      final docRef = await ref.add(cloudData);

      // 2. Local
      if (!kIsWeb) {
        await _local.insert('goals', {
          ...cloudData,
          'id': docRef.id,
          'deadline': cloudData['deadline'] != null ? (cloudData['deadline'] as DateTime).toIso8601String() : null,
          'createdAt': null, // No lo persistimos en local por ahora
        });
      }
    } catch (e) {
      print("Error addGoal Híbrido: $e");
    }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      if (goalsRef != null) await goalsRef!.doc(id).update(data);
      if (!kIsWeb) {
        // Adaptar tipos de fecha si es necesario antes de guardar en SQLite
        final Map<String, dynamic> localData = Map.from(data);
        if (localData['deadline'] != null && localData['deadline'] is DateTime) {
          localData['deadline'] = (localData['deadline'] as DateTime).toIso8601String();
        }
        await _local.update('goals', localData, id);
      }
    } catch (e) {
      print("Error updateGoal Híbrido: $e");
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      if (goalsRef != null) await goalsRef!.doc(id).delete();
      if (!kIsWeb) await _local.delete('goals', id);
    } catch (e) {
      print("Error deleteGoal Híbrido: $e");
    }
  }
}
