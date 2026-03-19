import 'dart:async';

import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/services/local_service.dart';
import 'package:flutter/material.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({LocalService? localService}) : _localService = localService ?? LocalService();

  final LocalService _localService;

  final List<TransactionModel> _transactions = [];
  String? _activeUserId;
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

  void bindUser(String? userId) {
    if (_activeUserId == userId) {
      return;
    }

    _activeUserId = userId;
    _error = null;

    if (userId == null) {
      _isLoading = false;
      _transactions.clear();
      notifyListeners();
      return;
    }

    unawaited(loadTransactions());
  }

  Future<void> loadTransactions() async {
    if (_activeUserId == null) {
      _transactions.clear();
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _localService.getTransactionsByUser(_activeUserId!);
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
    if (_activeUserId == null) {
      _error = 'Cannot save transactions: user not found';
      notifyListeners();
      return;
    }

    _error = null;
    notifyListeners();

    try {
      await _localService.saveTransactionsByUser(
        userId: _activeUserId!,
        transactions: _transactions,
      );
    } catch (e) {
      _error = 'Cannot save transactions: $e';
    } finally {
      notifyListeners();
    }
  }
}
