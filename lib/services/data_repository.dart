import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import 'firebase_service.dart';
import 'local_db_service.dart';

class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final FirebaseService _firebase = FirebaseService();
  final LocalDbService _local = LocalDbService();

  /// Verifica si el usuario actual tiene privilegios de sincronización en la nube
  Future<bool> isUserPremium() async {
    final profile = await _firebase.getUserProfile().first;
    return profile?['isPremium'] ?? false;
  }

  // --- GESTIÓN DE TRANSACCIONES ---

  /// Guarda un movimiento (Gasto/Ingreso) aplicando la lógica híbrida
  Future<void> addTransaction(TransactionModel tx) async {
    // 1. Siempre guardamos en Local (Móvil) para velocidad y soporte Offline
    if (!kIsWeb) {
      await _local.insert('transactions', {
        ...tx.toMap(),
        'date': tx.date.toIso8601String(), // SQFlite prefiere strings ISO
        'isCompleted': tx.isCompleted ? 1 : 0,
        'includedInCard': tx.includedInCard ? 1 : 0,
      });
    }

    // 2. Si es Premium o estamos en Web, sincronizamos con Firebase
    if (kIsWeb || await isUserPremium()) {
      await _firebase.addTransaction(tx);
    }
  }

  /// Obtiene los movimientos del mes (Preferiblemente de la nube si es Premium)
  Stream<List<TransactionModel>> getTransactions({required int month, required int year}) {
    // Por ahora, seguimos escuchando de Firebase para no romper la reactividad
    // En el futuro, este Stream combinará ambos mundos.
    return _firebase.getTransactions(month: month, year: year);
  }

  // --- GESTIÓN DE CATEGORÍAS ---

  Future<void> addCategory(Map<String, dynamic> cat) async {
    if (!kIsWeb) {
      await _local.insert('categories', {
        ...cat,
        'id': cat['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      });
    }
    if (kIsWeb || await isUserPremium()) {
      await _firebase.addCategory(cat);
    }
  }
}
