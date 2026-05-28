import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;

  Future<Database?> get database async {
    if (kIsWeb) return null; 
    if (_database != null) return _database;
    _database = await _initDb();
    return _database;
  }

  Future<Database> _initDb() async {
    final String path = join(await getDatabasesPath(), 'misfinanzas_v2.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // TABLA DE TRANSACCIONES
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            amount REAL,
            currency TEXT,
            date TEXT,
            category TEXT,
            type TEXT,
            isCompleted INTEGER,
            brandLogo TEXT,
            categoryColor INTEGER,
            includedInCard INTEGER,
            templateId TEXT,
            paidFromAccountId TEXT
          )
        ''');

        // TABLA DE CATEGORÍAS
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            color INTEGER,
            icon TEXT,
            budgetAmount REAL,
            budgetCurrency TEXT
          )
        ''');

        // TABLA DE CUENTAS / SALDOS
        await db.execute('''
          CREATE TABLE balances (
            id TEXT PRIMARY KEY,
            accountName TEXT,
            amount REAL,
            currency TEXT,
            brandLogo TEXT,
            includeInCoverage INTEGER,
            updatedAt TEXT
          )
        ''');

        // TABLA DE METAS (GOALS)
        await db.execute('''
          CREATE TABLE goals (
            id TEXT PRIMARY KEY,
            title TEXT,
            targetAmount REAL,
            currentAmount REAL,
            currency TEXT,
            deadline TEXT,
            linkedAccountId TEXT,
            color INTEGER,
            icon TEXT
          )
        ''');

        // TABLA DE SUSCRIPCIONES
        await db.execute('''
          CREATE TABLE subscriptions (
            id TEXT PRIMARY KEY,
            name TEXT,
            amount REAL,
            currency TEXT,
            category TEXT,
            linkType TEXT,
            linkId TEXT,
            nextBillingDay INTEGER
          )
        ''');

        // TABLA DE PLANTILLAS (TEMPLATES)
        await db.execute('''
          CREATE TABLE templates (
            id TEXT PRIMARY KEY,
            title TEXT,
            type TEXT,
            category TEXT,
            currency TEXT,
            defaultAmount REAL,
            dueDay INTEGER,
            brandLogo TEXT,
            isCreditCard INTEGER,
            orderIndex INTEGER
          )
        ''');
      },
    );
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    if (db == null) return;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    if (db == null) return;
    await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String table, String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    if (db == null) return [];
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }
}
