import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';

/// Database helper for SQLite.
/// Handles creating tables and CRUD operations.
///
/// ## Adding schema changes (new columns, tables)
/// 1. Bump [dbVersion] below
/// 2. Add a migration in [_runMigrations] for the new version
/// 3. Use [addColumnIfMissing] for new columns - safe, no data loss
/// 4. Update _onCreate with the latest schema for fresh installs
///
/// Migrations run in order. Never drop tables with user data.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String _dbFileName = 'spendly.db';

  /// Increment this when you add schema changes. Migrations run from old to this.
  static const int dbVersion = 7;

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
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Add a column to a table if it doesn't exist. Safe for existing users.
  /// For NOT NULL columns, always provide [defaultValue] so existing rows get a value.
  static Future<void> addColumnIfMissing(
    Database db,
    String table,
    String column,
    String sqlType, {
    String? defaultValue,
  }) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    if (info.any((row) => row['name'] == column)) return;
    final def = defaultValue != null ? ' DEFAULT $defaultValue' : '';
    await db.execute(
      'ALTER TABLE $table ADD COLUMN $column $sqlType$def',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion; v < newVersion; v++) {
      await _runMigration(db, v, v + 1);
    }
  }

  /// Migrations: one block per version step. Add new migrations here.
  Future<void> _runMigration(Database db, int from, int to) async {
    // v1 -> v2: (example - adjust to match your history)
    if (from < 2) {
      // placeholder if you had v2 changes
    }

    // v2 -> v3: transaction_date
    if (from < 3) {
      await addColumnIfMissing(db, 'transactions', 'transaction_date', 'TEXT');
      await db.execute(
        "UPDATE transactions SET transaction_date = created_at WHERE transaction_date IS NULL",
      );
    }

    // v3 -> v4: is_favorite on categories
    if (from < 4) {
      await addColumnIfMissing(
        db, 'categories', 'is_favorite', 'INTEGER NOT NULL',
        defaultValue: '0',
      );
    }

    // v4 -> v5: recurring_transactions table
    if (from < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_id INTEGER NOT NULL,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          is_income INTEGER NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id)
        )
      ''');
    }

    // v5 -> v6: is_reminder, reminder_type on recurring_transactions
    if (from < 6) {
      await addColumnIfMissing(
        db, 'recurring_transactions', 'is_reminder', 'INTEGER NOT NULL',
        defaultValue: '0',
      );
      await addColumnIfMissing(
        db, 'recurring_transactions', 'reminder_type', 'TEXT',
      );
    }

    // v6 -> v7: monthly_budget on categories
    if (from < 7) {
      await addColumnIfMissing(db, 'categories', 'monthly_budget', 'REAL');
    }

    // Add future migrations here, e.g.:
    // if (from < 7) {
    //   await addColumnIfMissing(db, 'transactions', 'notes', 'TEXT');
    // }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    await db.insert('categories', {
      'name': 'Salary',
      'icon_name': 'work',
      'is_income': 1,
      'is_favorite': 0,
      'monthly_budget': null,
    });
    await db.insert('categories', {
      'name': 'Food',
      'icon_name': 'restaurant',
      'is_income': 0,
      'is_favorite': 0,
      'monthly_budget': 2000000,
    });
    await db.insert('categories', {
      'name': 'Transport',
      'icon_name': 'local_gas_station',
      'is_income': 0,
      'is_favorite': 0,
      'monthly_budget': 1000000,
    });
  }

  /// Create tables on first run. Must match latest schema (dbVersion).
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        is_income INTEGER NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        monthly_budget REAL
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

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        is_income INTEGER NOT NULL,
        is_reminder INTEGER NOT NULL DEFAULT 0,
        reminder_type TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await _seedDefaultCategories(db);
  }

  /// Reset all data: clear transactions, recurring, and categories, then re-seed default categories.
  Future<void> resetData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('recurring_transactions');
    await db.delete('categories');
    await _seedDefaultCategories(db);
  }

  /// Seed test data in Indonesian for testing all features.
  Future<void> seedTestData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('recurring_transactions');
    await db.delete('categories');

    // Reset sqlite_sequence agar ID mulai dari 1 (AUTOINCREMENT tidak reset otomatis saat delete)
    await db.rawUpdate(
      "DELETE FROM sqlite_sequence WHERE name IN ('categories', 'transactions', 'recurring_transactions')",
    );

    // Kategori pendapatan (1-4) - ID eksplisit agar cocok dengan category_id di transaksi
    await db.insert('categories', {'id': 1, 'name': 'Gaji', 'icon_name': 'work', 'is_income': 1, 'is_favorite': 1, 'monthly_budget': null});
    await db.insert('categories', {'id': 2, 'name': 'Freelance', 'icon_name': 'payments', 'is_income': 1, 'is_favorite': 0, 'monthly_budget': null});
    await db.insert('categories', {'id': 3, 'name': 'Investasi', 'icon_name': 'trending_up', 'is_income': 1, 'is_favorite': 0, 'monthly_budget': null});
    await db.insert('categories', {'id': 4, 'name': 'Bonus', 'icon_name': 'card_giftcard', 'is_income': 1, 'is_favorite': 0, 'monthly_budget': null});

    // Kategori pengeluaran (5-12)
    await db.insert('categories', {'id': 5, 'name': 'Makanan', 'icon_name': 'restaurant', 'is_income': 0, 'is_favorite': 1, 'monthly_budget': 2500000});
    await db.insert('categories', {'id': 6, 'name': 'Transportasi', 'icon_name': 'local_gas_station', 'is_income': 0, 'is_favorite': 1, 'monthly_budget': 1200000});
    await db.insert('categories', {'id': 7, 'name': 'Sewa Rumah', 'icon_name': 'home', 'is_income': 0, 'is_favorite': 0, 'monthly_budget': 1500000});
    await db.insert('categories', {'id': 8, 'name': 'Listrik', 'icon_name': 'receipt_long', 'is_income': 0, 'is_favorite': 0, 'monthly_budget': 300000});
    await db.insert('categories', {'id': 9, 'name': 'Belanja', 'icon_name': 'shopping_cart', 'is_income': 0, 'is_favorite': 1, 'monthly_budget': 1500000});
    await db.insert('categories', {'id': 10, 'name': 'Hiburan', 'icon_name': 'movie', 'is_income': 0, 'is_favorite': 0, 'monthly_budget': 500000});
    await db.insert('categories', {'id': 11, 'name': 'Kesehatan', 'icon_name': 'medical_services', 'is_income': 0, 'is_favorite': 0, 'monthly_budget': 400000});
    await db.insert('categories', {'id': 12, 'name': 'Internet', 'icon_name': 'wifi', 'is_income': 0, 'is_favorite': 0, 'monthly_budget': 250000});

    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final twoMonthsAgo = DateTime(now.year, now.month - 2);

    Future<void> tx(String desc, num amt, int catId, DateTime dt, int isInc) async {
      await db.insert('transactions', {
        'description': desc,
        'amount': amt,
        'category_id': catId,
        'transaction_date': dt.toIso8601String(),
        'created_at': dt.toIso8601String(),
        'is_income': isInc,
      });
    }

    // --- Bulan ini ---
    await tx('Gaji bulanan', 8500000, 1, DateTime(now.year, now.month, 1), 1);
    await tx('Makan siang kantor', 45000, 5, DateTime(now.year, now.month, 2), 0);
    await tx('Grab ke kantor', 35000, 6, DateTime(now.year, now.month, 2), 0);
    await tx('Kopi pagi', 25000, 5, DateTime(now.year, now.month, 3), 0);
    await tx('Makan siang', 55000, 5, DateTime(now.year, now.month, 5), 0);
    await tx('Bensin motor', 50000, 6, DateTime(now.year, now.month, 5), 0);
    await tx('Parkir', 15000, 6, DateTime(now.year, now.month, 6), 0);
    await tx('Nasi goreng', 30000, 5, DateTime(now.year, now.month, 7), 0);
    await tx('Gojek', 28000, 6, DateTime(now.year, now.month, 8), 0);
    await tx('Bensin motor', 50000, 6, DateTime(now.year, now.month, 10), 0);
    await tx('Nongki bareng teman', 75000, 5, DateTime(now.year, now.month, 10), 0);
    await tx('Belanja bulanan', 450000, 9, DateTime(now.year, now.month, 12), 0);
    await tx('Token listrik', 200000, 8, DateTime(now.year, now.month, 12), 0);
    await tx('Paket data', 150000, 12, DateTime(now.year, now.month, 13), 0);
    await tx('Nonton bioskop', 80000, 10, DateTime(now.year, now.month, 14), 0);
    await tx('Makan malam', 120000, 5, DateTime(now.year, now.month, 15), 0);
    await tx('Proyek website', 1500000, 2, DateTime(now.year, now.month, 18), 1);
    await tx('Sewa kos', 1500000, 7, DateTime(now.year, now.month, 20), 0);
    await tx('Obat & vitamin', 85000, 11, DateTime(now.year, now.month, 21), 0);
    await tx('Bensin motor', 50000, 6, DateTime(now.year, now.month, 22), 0);
    await tx('Makan siang', 48000, 5, DateTime(now.year, now.month, 25), 0);
    await tx('Dividen saham', 125000, 3, DateTime(now.year, now.month, 28), 1);

    // --- Bulan lalu ---
    await tx('Gaji bulan lalu', 8500000, 1, DateTime(lastMonth.year, lastMonth.month, 1), 1);
    await tx('Sewa kos', 1500000, 7, DateTime(lastMonth.year, lastMonth.month, 1), 0);
    await tx('Token listrik', 200000, 8, DateTime(lastMonth.year, lastMonth.month, 5), 0);
    await tx('Makan siang', 52000, 5, DateTime(lastMonth.year, lastMonth.month, 8), 0);
    await tx('Bensin motor', 50000, 6, DateTime(lastMonth.year, lastMonth.month, 10), 0);
    await tx('Belanja bulanan', 380000, 9, DateTime(lastMonth.year, lastMonth.month, 12), 0);
    await tx('Paket data', 150000, 12, DateTime(lastMonth.year, lastMonth.month, 15), 0);
    await tx('Freelance desain', 800000, 2, DateTime(lastMonth.year, lastMonth.month, 18), 1);
    await tx('Nongki', 65000, 5, DateTime(lastMonth.year, lastMonth.month, 20), 0);
    await tx('Bayar dokter', 150000, 11, DateTime(lastMonth.year, lastMonth.month, 22), 0);

    // --- Dua bulan lalu ---
    await tx('Gaji', 8500000, 1, DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 1), 1);
    await tx('Sewa kos', 1500000, 7, DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 1), 0);
    await tx('Token listrik', 200000, 8, DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 10), 0);
    await tx('Makan siang', 45000, 5, DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 5), 0);
    await tx('Bensin motor', 50000, 6, DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 12), 0);
    await tx('Belanja', 520000, 9, DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 15), 0);
    await tx('Bonus THR', 2500000, 4, DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 20), 1);

    // Recurring
    await db.insert('recurring_transactions', {
      'category_id': 7,
      'description': 'Sewa bulanan',
      'amount': 1500000,
      'is_income': 0,
      'is_reminder': 1,
      'reminder_type': 'end_month_minus_3',
    });
    await db.insert('recurring_transactions', {
      'category_id': 8,
      'description': 'Listrik',
      'amount': 200000,
      'is_income': 0,
      'is_reminder': 1,
      'reminder_type': 'start_month_plus_3',
    });
    await db.insert('recurring_transactions', {
      'category_id': 1,
      'description': 'Gaji',
      'amount': 8500000,
      'is_income': 1,
      'is_reminder': 0,
      'reminder_type': null,
    });
    await db.insert('recurring_transactions', {
      'category_id': 9,
      'description': 'Belanja bulanan',
      'amount': 400000,
      'is_income': 0,
      'is_reminder': 0,
      'reminder_type': null,
    });
    await db.insert('recurring_transactions', {
      'category_id': 12,
      'description': 'Paket data',
      'amount': 150000,
      'is_income': 0,
      'is_reminder': 0,
      'reminder_type': null,
    });
  }

  /// Export database. If [targetDirectoryPath] is set and writable, save there; otherwise use app documents. Returns path of exported file.
  Future<String> exportData({String? targetDirectoryPath}) async {
    final src = await databasePath;
    final date = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-.]'), '').substring(0, 14);
    final fileName = 'spendly_export_$date.db';

    // Try user-selected path first (desktop)
    if (targetDirectoryPath != null && targetDirectoryPath.isNotEmpty) {
      try {
        final dest = join(targetDirectoryPath, fileName);
        await File(src).copy(dest);
        return dest;
      } catch (_) {
        // Fall through to app documents
      }
    }

    // Use app documents (always works on mobile/desktop)
    final dir = await getApplicationDocumentsDirectory();
    final dest = join(dir.path, fileName);
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
    const orderBy = 'is_favorite DESC, name ASC';
    List<Map<String, dynamic>> maps;
    if (isIncome != null) {
      maps = await db.query(
        'categories',
        where: 'is_income = ?',
        whereArgs: [isIncome ? 1 : 0],
        orderBy: orderBy,
      );
    } else {
      maps = await db.query('categories', orderBy: orderBy);
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

  /// Total expense for one category in the month of [date].
  Future<double> getCategoryExpenseTotalForMonth(
    int categoryId,
    DateTime date, {
    int? excludeTransactionId,
  }) async {
    final db = await database;
    final start = DateTime(
      date.year,
      date.month,
      1,
    ).toIso8601String().substring(0, 10);
    final end = DateTime(
      date.year,
      date.month + 1,
      0,
    ).toIso8601String().substring(0, 10);
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE category_id = ?
        AND is_income = 0
        AND date(transaction_date) >= ?
        AND date(transaction_date) <= ?
        ${excludeTransactionId != null ? 'AND id != ?' : ''}
      ''',
      excludeTransactionId != null
          ? [categoryId, start, end, excludeTransactionId]
          : [categoryId, start, end],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Daily totals (income, expense) for each date in [start]..[end] (inclusive).
  /// Keys are 'yyyy-MM-dd'. Dates with no transactions have (0, 0).
  Future<Map<String, ({double income, double expense})>> getDailyTotals(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String().substring(0, 10);
    final endStr = DateTime(end.year, end.month, end.day).toIso8601String().substring(0, 10);
    final maps = await db.rawQuery('''
      SELECT date(transaction_date) as day,
             SUM(CASE WHEN is_income = 1 THEN amount ELSE 0 END) as income,
             SUM(CASE WHEN is_income = 0 THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE date(transaction_date) >= ? AND date(transaction_date) <= ?
      GROUP BY date(transaction_date)
    ''', [startStr, endStr]);
    final result = <String, ({double income, double expense})>{};
    for (final m in maps) {
      final day = m['day'] as String?;
      if (day != null) {
        result[day] = (
          income: (m['income'] as num?)?.toDouble() ?? 0,
          expense: (m['expense'] as num?)?.toDouble() ?? 0,
        );
      }
    }
    return result;
  }

  /// Category totals for date range: {categoryId: amount}.
  /// Returns (expenseByCategory, incomeByCategory).
  Future<({Map<int, double> expense, Map<int, double> income})> getCategoryTotalsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String().substring(0, 10);
    final endStr = DateTime(end.year, end.month, end.day).toIso8601String().substring(0, 10);
    final maps = await db.rawQuery('''
      SELECT category_id, is_income, SUM(amount) as total
      FROM transactions
      WHERE date(transaction_date) >= ? AND date(transaction_date) <= ?
      GROUP BY category_id, is_income
    ''', [startStr, endStr]);
    final expense = <int, double>{};
    final income = <int, double>{};
    for (final m in maps) {
      final catId = m['category_id'] as int?;
      final isInc = (m['is_income'] as int?) == 1;
      final total = (m['total'] as num?)?.toDouble() ?? 0;
      if (catId != null && total > 0) {
        if (isInc) {
          income[catId] = total;
        } else {
          expense[catId] = total;
        }
      }
    }
    return (expense: expense, income: income);
  }

  // ---------- Recurring Transactions ----------

  Future<int> insertRecurring(RecurringTransaction r) async {
    final db = await database;
    return await db.insert('recurring_transactions', r.toMap());
  }

  Future<List<RecurringTransaction>> getRecurringTransactions({
    bool? isIncome,
  }) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (isIncome != null) {
      maps = await db.query(
        'recurring_transactions',
        where: 'is_income = ?',
        whereArgs: [isIncome ? 1 : 0],
      );
    } else {
      maps = await db.query('recurring_transactions');
    }
    return maps.map((m) => RecurringTransaction.fromMap(m)).toList();
  }

  Future<int> updateRecurring(RecurringTransaction r) async {
    final db = await database;
    return await db.update(
      'recurring_transactions',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  /// True if there is at least one transaction this month for [categoryId] and [isIncome].
  Future<bool> hasTransactionThisMonth(int categoryId, bool isIncome) async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final startStr = start.toIso8601String().substring(0, 10);
    final endStr = end.toIso8601String().substring(0, 10);
    final result = await db.rawQuery('''
      SELECT 1 FROM transactions
      WHERE category_id = ? AND is_income = ?
        AND date(transaction_date) >= ? AND date(transaction_date) <= ?
      LIMIT 1
    ''', [categoryId, isIncome ? 1 : 0, startStr, endStr]);
    return result.isNotEmpty;
  }

  Future<int> deleteRecurring(int id) async {
    final db = await database;
    return await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
