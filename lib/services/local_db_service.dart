import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;
  final _changeController = StreamController<String>.broadcast();
  Stream<String> get onTableChanged => _changeController.stream;

  // Esquema Maestro v21 - ADN Nativo ARGB (integers)
  final Map<String, String> _tables = {
    'transactions': 'id TEXT PRIMARY KEY, templateId TEXT, subscriptionId TEXT, title TEXT, amount REAL, minimumAmount REAL, description TEXT, date TEXT, dueDate TEXT, category TEXT, currency TEXT, isCompleted INTEGER DEFAULT 0, isPaid INTEGER DEFAULT 0, type TEXT, brandLogo TEXT, generatedBy TEXT, orderIndex INTEGER DEFAULT 999, paidFromAccountId TEXT, includedInCard INTEGER DEFAULT 0, categoryColor INTEGER, updatedAt TEXT, isDeleted INTEGER DEFAULT 0, syncStatus TEXT DEFAULT "synced"',
    'categories': 'id TEXT PRIMARY KEY, name TEXT, type TEXT, color INTEGER, icon TEXT, budgetAmount REAL, budgetCurrency TEXT, updatedAt TEXT, isDeleted INTEGER DEFAULT 0, syncStatus TEXT DEFAULT "synced"',
    'balances': 'id TEXT PRIMARY KEY, accountName TEXT, amount REAL, currency TEXT, accountType TEXT, brandLogo TEXT, isBimonetaryPart INTEGER DEFAULT 0, baseName TEXT, includeInCoverage INTEGER DEFAULT 1, orderIndex INTEGER DEFAULT 0, updatedAt TEXT, isDeleted INTEGER DEFAULT 0, syncStatus TEXT DEFAULT "synced"',
    'goals': 'id TEXT PRIMARY KEY, title TEXT, targetAmount REAL, currentAmount REAL, currency TEXT, icon TEXT, linkedAccountId TEXT, createdAt TEXT, updatedAt TEXT, isDeleted INTEGER DEFAULT 0, syncStatus TEXT DEFAULT "synced"',
    'subscriptions': 'id TEXT PRIMARY KEY, name TEXT, amount REAL, currency TEXT, category TEXT, linkType TEXT, linkId TEXT, dueDay INTEGER, updatedAt TEXT, isDeleted INTEGER DEFAULT 0, syncStatus TEXT DEFAULT "synced"',
    'templates': 'id TEXT PRIMARY KEY, title TEXT, currency TEXT, dueDay INTEGER, defaultAmount REAL, type TEXT, category TEXT, isCreditCard INTEGER DEFAULT 0, includedInCard INTEGER DEFAULT 0, brandLogo TEXT, subscriptions TEXT, isBimonetaryPart INTEGER DEFAULT 0, baseName TEXT, orderIndex INTEGER DEFAULT 999, categoryColor INTEGER, updatedAt TEXT, isDeleted INTEGER DEFAULT 0, syncStatus TEXT DEFAULT "synced"',
    'settings': 'id TEXT PRIMARY KEY, value TEXT',
  };

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database;
    _database = await _initDb();
    return _database;
  }

  Future<Database> _initDb() async {
    final String path = join(await getDatabasesPath(), 'misfinanzas_v21.db'); 
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      for (var entry in _tables.entries) {
        await db.execute('CREATE TABLE ${entry.key} (${entry.value})');
      }
    });
  }

  void notify(String table) {
    if (!_changeController.isClosed) _changeController.add(table);
  }

  Map<String, dynamic> _sanitize(String table, Map<String, dynamic> data) {
    if (!_tables.containsKey(table)) return data;
    final sql = _tables[table]!;
    final allowed = sql.split(',').map((c) => c.trim().split(' ').first).toList();
    final Map<String, dynamic> clean = {};

    data.forEach((key, value) {
      if (allowed.contains(key)) {
        if (value is bool) {
          clean[key] = value ? 1 : 0;
        } else if (value is Timestamp) {
          clean[key] = value.toDate().toIso8601String();
        } else if (value is DateTime) {
          clean[key] = value.toIso8601String();
        } else if (value is Map || value is List) {
          clean[key] = jsonEncode(value);
        } else if (key.toLowerCase().contains('color') || key.toLowerCase().contains('index') || key.toLowerCase().contains('day')) {
          clean[key] = (value is num) ? value.toInt() : int.tryParse(value.toString()) ?? 0;
        } else if (key.toLowerCase().contains('amount')) {
          clean[key] = (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
        } else {
          clean[key] = value;
        }
      }
    });
    return clean;
  }

  Future<void> insert(String table, Map<String, dynamic> data, {bool silent = false}) async {
    try {
      final db = await database; if (db == null) return;
      await db.insert(table, _sanitize(table, data), conflictAlgorithm: ConflictAlgorithm.replace);
      if (!silent) notify(table);
    } catch (e) { print("❌ SQLITE INSERT ERROR (\$table): \$e"); }
  }

  Future<void> insertBatch(String table, List<Map<String, dynamic>> items) async {
    final db = await database; if (db == null || items.isEmpty) return;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var item in items) {
        batch.insert(table, _sanitize(table, item), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
    notify(table);
  }

  Future<void> update(String table, Map<String, dynamic> data, String id, {bool silent = false}) async {
    try {
      final db = await database; if (db == null) return;
      await db.update(table, _sanitize(table, data), where: 'id = ?', whereArgs: [id]);
      if (!silent) notify(table);
    } catch (e) { print("❌ SQLITE UPDATE ERROR: \$e"); }
  }

  Future<void> delete(String table, String id, {bool silent = false}) async {
    try {
      final db = await database; if (db == null) return;
      await db.delete(table, where: 'id = ?', whereArgs: [id]);
      if (!silent) notify(table);
    } catch (e) { print("❌ SQLITE DELETE ERROR: \$e"); }
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    try {
      final db = await database; if (db == null) return [];
      return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
    } catch (e) { print("❌ SQLITE QUERY ERROR: \$e"); return []; }
  }

  Future<void> clearAllData() async {
    final db = await database; if (db == null) return;
    await db.transaction((txn) async {
      for (var t in _tables.keys) {
        if (t != 'settings') await txn.delete(t);
      }
    });
  }
}
