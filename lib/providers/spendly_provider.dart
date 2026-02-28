import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';

/// Provider that holds app state and talks to the database.
/// When data changes, we call notifyListeners() so the UI rebuilds.
class SpendlyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<TransactionRecord> _transactions = [];
  List<models.Category> _categories = [];
  double _totalIncome = 0;
  double _totalExpense = 0;

  List<TransactionRecord> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _totalIncome - _totalExpense;

  /// Load all data from database - call on app start and after changes
  Future<void> loadAll() async {
    _transactions = await _db.getTransactions();
    _categories = await _db.getCategories();
    _totalIncome = await _db.getTotalIncome();
    _totalExpense = await _db.getTotalExpense();
    notifyListeners();
  }

  Future<List<TransactionRecord>> getExpenses({int? limit}) async {
    return _db.getTransactions(isIncome: false, limit: limit);
  }

  Future<List<TransactionRecord>> getIncomes({int? limit}) async {
    return _db.getTransactions(isIncome: true, limit: limit);
  }

  Future<void> addTransaction(TransactionRecord t) async {
    await _db.insertTransaction(t);
    await loadAll();
  }

  Future<void> updateTransaction(TransactionRecord t) async {
    await _db.updateTransaction(t);
    await loadAll();
  }

  Future<void> addCategory(models.Category c) async {
    await _db.insertCategory(c);
    await loadAll();
  }

  Future<void> updateCategory(models.Category c) async {
    await _db.updateCategory(c);
    await loadAll();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await loadAll();
  }

  models.Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> resetData() async {
    await _db.resetData();
    await loadAll();
  }

  Future<void> seedTestData() async {
    await _db.seedTestData();
    await loadAll();
  }

  Future<List<RecurringTransaction>> getRecurringTransactions({
    bool? isIncome,
  }) =>
      _db.getRecurringTransactions(isIncome: isIncome);

  Future<void> addRecurring(RecurringTransaction r) async {
    await _db.insertRecurring(r);
    await loadAll();
  }

  Future<void> updateRecurring(RecurringTransaction r) async {
    await _db.updateRecurring(r);
    await loadAll();
  }

  Future<void> deleteRecurring(int id) async {
    await _db.deleteRecurring(id);
    await loadAll();
  }

  /// Recurring transactions with reminders that are due (in window + not yet added this month).
  Future<List<RecurringTransaction>> getDueRecurringReminders() async {
    final all = await _db.getRecurringTransactions();
    final now = DateTime.now();
    final due = <RecurringTransaction>[];
    for (final r in all) {
      if (!r.isReminderEnabled) continue;
      if (!RecurringTransaction.isInReminderWindow(r.reminderType, now)) {
        continue;
      }
      final hasTx = await _db.hasTransactionThisMonth(r.categoryId, r.isIncome);
      if (!hasTx) due.add(r);
    }
    return due;
  }

  Future<Map<String, ({double income, double expense})>> getDailyTotals(
    DateTime start,
    DateTime end,
  ) =>
      _db.getDailyTotals(start, end);

  Future<({Map<int, double> expense, Map<int, double> income})> getCategoryTotalsForRange(
    DateTime start,
    DateTime end,
  ) =>
      _db.getCategoryTotalsForRange(start, end);

  Future<double> getCategoryExpenseTotalForMonth(
    int categoryId,
    DateTime date, {
    int? excludeTransactionId,
  }) =>
      _db.getCategoryExpenseTotalForMonth(
        categoryId,
        date,
        excludeTransactionId: excludeTransactionId,
      );

  Future<String> exportData({String? targetDirectoryPath}) async =>
      _db.exportData(targetDirectoryPath: targetDirectoryPath);

  Future<void> importData(String path) async {
    await _db.importData(path);
    await loadAll();
  }
}
