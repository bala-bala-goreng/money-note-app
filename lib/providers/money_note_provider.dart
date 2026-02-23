import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/category.dart' as models;
import '../models/transaction.dart';

/// Provider that holds app state and talks to the database.
/// When data changes, we call notifyListeners() so the UI rebuilds.
class MoneyNoteProvider extends ChangeNotifier {
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
}
