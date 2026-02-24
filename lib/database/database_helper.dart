import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Database helper for SQLite.
/// Handles creating tables and CRUD operations.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String _dbFileName = 'money_note.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbFileName);
    return _database!;
  }

  /// Path to the SQLite database file.
  Future<String> get databasePath async {
    final dir = await getDatabasesPath();
    return join(dir, _dbFileName);
  }

  /// Close the database (e.g. before import). Next access will reopen.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureTransactionDateColumn(db);
  }

  /// Adds [transaction_date] column if missing (handles DBs created before we added it).
  Future<void> _ensureTransactionDateColumn(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(transactions)');
    final hasColumn = info.any((row) => row['name'] == 'transaction_date');
    if (hasColumn) return;
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN transaction_date TEXT',
    );
    await db.execute(
      "UPDATE transactions SET transaction_date = created_at WHERE transaction_date IS NULL",
    );
  }

  Future<void> _seedDefaultCategories(Database db) async {
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
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_income INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await _seedDefaultCategories(db);
  }

  /// Reset all data: clear transactions and categories, then re-seed default categories.
  Future<void> resetData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('categories');
    await _seedDefaultCategories(db);
  }

  /// Export database. If [targetDirectoryPath] is set, save there; otherwise use app documents. Returns path of exported file.
  Future<String> exportData({String? targetDirectoryPath}) async {
    final src = await databasePath;
    final String dirPath;
    if (targetDirectoryPath != null && targetDirectoryPath.isNotEmpty) {
      dirPath = targetDirectoryPath;
    } else {
      dirPath = (await getApplicationDocumentsDirectory()).path;
    }
    final date = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-.]'), '').substring(0, 14);
    final dest = join(dirPath, 'money_note_export_$date.db');
    await File(src).copy(dest);
    return dest;
  }

  /// Import database from a file (replaces current DB). Close DB first, copy file, then reopen on next access.
  Future<void> importData(String sourceFilePath) async {
    await close();
    final dest = await databasePath;
    await File(sourceFilePath).copy(dest);
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

  Future<int> updateTransaction(TransactionRecord t) async {
    final db = await database;
    return await db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<List<TransactionRecord>> getTransactions({
    bool? isIncome,
    int? limit,
  }) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    const orderBy = 'transaction_date DESC, created_at DESC';
    if (isIncome != null) {
      maps = await db.query(
        'transactions',
        where: 'is_income = ?',
        whereArgs: [isIncome ? 1 : 0],
        orderBy: orderBy,
        limit: limit,
      );
    } else {
      maps = await db.query(
        'transactions',
        orderBy: orderBy,
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
