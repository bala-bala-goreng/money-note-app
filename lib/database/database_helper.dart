import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Database helper for SQLite.
/// Handles creating tables and CRUD operations.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_note.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Create tables on first run
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        is_income INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_income INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Seed default categories for learning
    await db.insert('categories', {
      'name': 'Salary',
      'icon_name': 'work',
      'is_income': 1,
    });
    await db.insert('categories', {
      'name': 'Food',
      'icon_name': 'restaurant',
      'is_income': 0,
    });
    await db.insert('categories', {
      'name': 'Transport',
      'icon_name': 'local_gas_station',
      'is_income': 0,
    });
  }

  // ---------- Categories ----------

  Future<int> insertCategory(Category cat) async {
    final db = await database;
    return await db.insert('categories', cat.toMap());
  }

  Future<List<Category>> getCategories({bool? isIncome}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (isIncome != null) {
      maps = await db.query(
        'categories',
        where: 'is_income = ?',
        whereArgs: [isIncome ? 1 : 0],
      );
    } else {
      maps = await db.query('categories');
    }
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> updateCategory(Category cat) async {
    final db = await database;
    return await db.update(
      'categories',
      cat.toMap(),
      where: 'id = ?',
      whereArgs: [cat.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Transactions ----------

  Future<int> insertTransaction(TransactionRecord t) async {
    final db = await database;
    return await db.insert('transactions', t.toMap());
  }

  Future<List<TransactionRecord>> getTransactions({
    bool? isIncome,
    int? limit,
  }) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (isIncome != null) {
      maps = await db.query(
        'transactions',
        where: 'is_income = ?',
        whereArgs: [isIncome ? 1 : 0],
        orderBy: 'created_at DESC',
        limit: limit,
      );
    } else {
      maps = await db.query(
        'transactions',
        orderBy: 'created_at DESC',
        limit: limit,
      );
    }
    return maps.map((m) => TransactionRecord.fromMap(m)).toList();
  }

  Future<double> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE is_income = 1',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE is_income = 0',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
