import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/services/local_service.dart';
import 'package:flutter/material.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({LocalService? localService}) : _localService = localService ?? LocalService();

  final LocalService _localService;

  final List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => List<TransactionModel>.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;

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
}
