import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/services/local_service.dart';
import 'package:flutter/material.dart';

enum FilterType { all, income, expense }

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({LocalService? localService}) : _localService = localService ?? LocalService();

  final LocalService _localService;

  final List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  FilterType _filterType = FilterType.all;
  String _searchQuery = '';

  List<TransactionModel> get transactions => List<TransactionModel>.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;
  FilterType get filterType => _filterType;
  String get searchQuery => _searchQuery;

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((tx) {
      if (_filterType != FilterType.all && tx.type != (_filterType == FilterType.income ? TransactionType.income : TransactionType.expense)) {
        return false;
      }
      if (_searchQuery.isNotEmpty && !tx.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  double get totalIncome => _transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get totalExpense => _transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _localService.getTransactions();
      _transactions
        ..clear()
        ..addAll(data);
    } catch (e) {
      _error = 'Cannot load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.insert(0, transaction);
    await _persist();
  }

  Future<void> updateTransaction(TransactionModel updatedTransaction) async {
    final index = _transactions.indexWhere((tx) => tx.id == updatedTransaction.id);
    if (index == -1) {
      return;
    }

    _transactions[index] = updatedTransaction;
    await _persist();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((tx) => tx.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    _error = null;
    notifyListeners();

    try {
      await _localService.saveTransactions(_transactions);
    } catch (e) {
      _error = 'Cannot save transactions: $e';
    } finally {
      notifyListeners();
    }
  }

  void setFilter(FilterType type) {
    _filterType = type;
    notifyListeners();
  }

  void search(String value) {
    _searchQuery = value;
    notifyListeners();
  }
}
