import 'dart:async';

import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/services/firebase_transaction_service.dart';
import 'package:expense_tracker_app/services/local_service.dart';
import 'package:flutter/material.dart';

enum TransactionTypeFilter { all, income, expense }

enum TransactionTimeFilter { all, today, thisWeek, thisMonth, thisYear, custom }

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({
    LocalService? localService,
    FirebaseTransactionService? firebaseTransactionService,
    Duration? searchDebounceDuration,
    DateTime Function()? nowProvider,
  }) : _localService = localService ?? LocalService(),
       _firebaseTransactionService = firebaseTransactionService,
       _searchDebounceDuration =
           searchDebounceDuration ?? const Duration(milliseconds: 350),
       _nowProvider = nowProvider ?? DateTime.now;

  final LocalService _localService;
  final FirebaseTransactionService? _firebaseTransactionService;
  final Duration _searchDebounceDuration;
  final DateTime Function() _nowProvider;

  final List<TransactionModel> _transactions = [];
  final List<TransactionModel> _filteredTransactions = [];
  String? _activeUserId;
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  TransactionTypeFilter _typeFilter = TransactionTypeFilter.all;
  TransactionTimeFilter _timeFilter = TransactionTimeFilter.all;
  DateTimeRange? _customDateRange;
  Timer? _searchDebounceTimer;

  List<TransactionModel> get allTransactions =>
      List<TransactionModel>.unmodifiable(_transactions);
  List<TransactionModel> get transactions =>
      List<TransactionModel>.unmodifiable(_filteredTransactions);
  List<TransactionModel> get filteredTransactions =>
      List<TransactionModel>.unmodifiable(_filteredTransactions);

  bool get isLoading => _isLoading;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  TransactionTypeFilter get typeFilter => _typeFilter;
  TransactionTimeFilter get timeFilter => _timeFilter;
  DateTimeRange? get customDateRange => _customDateRange;

  double get totalIncome => _transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  double get totalExpense => _transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  double get filteredIncome => _filteredTransactions
      .where((tx) => tx.type == TransactionType.income)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  double get filteredExpense => _filteredTransactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold<double>(0, (sum, tx) => sum + tx.amount);

  double get balance => totalIncome - totalExpense;
  double get filteredBalance => filteredIncome - filteredExpense;

  TransactionModel? getById(String id) {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) {
      return null;
    }
    return _transactions[index];
  }

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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<TransactionModel> data;

      if (_activeUserId == null) {
        data = await _localService.getTransactions();
      } else {
        final userId = _activeUserId!;
        final localData = await _localService.getTransactionsByUser(userId);
        if (_firebaseTransactionService == null) {
          data = localData;
        } else {
          try {
            final remoteData = await _firebaseTransactionService!
                .getTransactionsByUser(userId);
          if (remoteData.isNotEmpty || localData.isEmpty) {
            data = remoteData;
            await _localService.saveTransactionsByUser(
              userId: userId,
              transactions: remoteData,
            );
          } else {
            data = localData;
            unawaited(
              _firebaseTransactionService!.saveTransactionsByUser(
                userId: userId,
                transactions: localData,
              ),
            );
          }
          } catch (_) {
            data = localData;
          }
        }
      }

      _transactions
        ..clear()
        ..addAll(data);
      _sortByNewest(_transactions);
      _applyFilterAndSearch(shouldNotify: false);
    } catch (e) {
      _error = 'Cannot load transactions: $e';
      _filteredTransactions.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retryLoadTransactions() async {
    await loadTransactions();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    _error = null;
    _transactions.add(transaction);
    _sortByNewest(_transactions);
    _applyFilterAndSearch();
    await _persist();
  }

  Future<void> updateTransaction(TransactionModel updatedTransaction) async {
    _error = null;
    final index = _transactions.indexWhere(
      (tx) => tx.id == updatedTransaction.id,
    );
    if (index == -1) {
      return;
    }

    _transactions[index] = updatedTransaction;
    _sortByNewest(_transactions);
    _applyFilterAndSearch();
    await _persist();
  }

  Future<void> deleteTransaction(String id) async {
    _error = null;
    final before = _transactions.length;
    _transactions.removeWhere((tx) => tx.id == id);
    if (_transactions.length == before) {
      return;
    }

    _applyFilterAndSearch();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      if (_activeUserId == null) {
        await _localService.saveTransactions(_transactions);
      } else {
        final userId = _activeUserId!;
        await _localService.saveTransactionsByUser(
          userId: userId,
          transactions: _transactions,
        );
        if (_firebaseTransactionService != null) {
          await _firebaseTransactionService!.saveTransactionsByUser(
            userId: userId,
            transactions: _transactions,
          );
        }
      }
    } catch (e) {
      _error = 'Cannot save transactions: $e';
      notifyListeners();
    }
  }

  Future<void> persistNow() async {
    await _persist();
  }

  void onSearchQueryChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      _searchQuery = query.trim();
      _applyFilterAndSearch();
    });
  }

  void onSearchChanged(String query) {
    onSearchQueryChanged(query);
  }

  void setSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchQuery = query.trim();
    _applyFilterAndSearch();
  }

  void setTypeFilter(TransactionTypeFilter type) {
    if (_typeFilter == type) {
      return;
    }

    _typeFilter = type;
    _applyFilterAndSearch();
  }

  void setTimeFilter(TransactionTimeFilter filter) {
    if (_timeFilter == filter) {
      return;
    }

    _timeFilter = filter;
    if (filter != TransactionTimeFilter.custom) {
      _customDateRange = null;
    }
    _applyFilterAndSearch();
  }

  void setCustomDateRange(DateTimeRange? range) {
    if (range == null) {
      _customDateRange = null;
      _timeFilter = TransactionTimeFilter.all;
      _applyFilterAndSearch();
      return;
    }

    _customDateRange = _normalizeDateRange(range);
    _timeFilter = TransactionTimeFilter.custom;
    _applyFilterAndSearch();
  }

  void clearFilters() {
    _searchDebounceTimer?.cancel();
    _searchQuery = '';
    _typeFilter = TransactionTypeFilter.all;
    _timeFilter = TransactionTimeFilter.all;
    _customDateRange = null;
    _applyFilterAndSearch();
  }

  Map<String, double> get expenseByCategory {
    final result = <String, double>{};
    for (final tx in _filteredTransactions) {
      if (tx.type != TransactionType.expense) {
        continue;
      }

      result.update(tx.category, (value) => value + tx.amount, ifAbsent: () => tx.amount);
    }

    return result;
  }

  Map<String, double> get allExpenseByCategory {
    final result = <String, double>{};
    for (final tx in _transactions) {
      if (tx.type != TransactionType.expense) {
        continue;
      }

      result.update(tx.category, (value) => value + tx.amount, ifAbsent: () => tx.amount);
    }

    return result;
  }

  Map<String, double> get allIncomeByCategory {
    final result = <String, double>{};
    for (final tx in _transactions) {
      if (tx.type != TransactionType.income) {
        continue;
      }

      result.update(tx.category, (value) => value + tx.amount, ifAbsent: () => tx.amount);
    }

    return result;
  }

  void _applyFilterAndSearch({bool shouldNotify = true}) {
    final normalizedQuery = _searchQuery.toLowerCase();

    Iterable<TransactionModel> result = _transactions;

    if (_typeFilter == TransactionTypeFilter.income) {
      result = result.where((tx) => tx.type == TransactionType.income);
    } else if (_typeFilter == TransactionTypeFilter.expense) {
      result = result.where((tx) => tx.type == TransactionType.expense);
    }

    result = result.where((tx) => _matchesTimeFilter(tx.date));

    if (normalizedQuery.isNotEmpty) {
      result = result.where(
        (tx) => tx.title.toLowerCase().contains(normalizedQuery),
      );
    }

    final sorted = result.toList();
    _sortByNewest(sorted);

    _filteredTransactions
      ..clear()
      ..addAll(sorted);

    if (shouldNotify) {
      notifyListeners();
    }
  }

  bool _matchesTimeFilter(DateTime date) {
    final value = _dateOnly(date);
    final now = _dateOnly(_nowProvider());

    switch (_timeFilter) {
      case TransactionTimeFilter.all:
        return true;
      case TransactionTimeFilter.today:
        return _isSameDate(value, now);
      case TransactionTimeFilter.thisWeek:
        final startOfWeek = _startOfWeek(now);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return !value.isBefore(startOfWeek) && !value.isAfter(endOfWeek);
      case TransactionTimeFilter.thisMonth:
        return value.year == now.year && value.month == now.month;
      case TransactionTimeFilter.thisYear:
        return value.year == now.year;
      case TransactionTimeFilter.custom:
        if (_customDateRange == null) {
          return true;
        }

        final start = _dateOnly(_customDateRange!.start);
        final end = _dateOnly(_customDateRange!.end);
        return !value.isBefore(start) && !value.isAfter(end);
    }
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = _dateOnly(date);
    final daysFromMonday = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: daysFromMonday));
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTimeRange _normalizeDateRange(DateTimeRange range) {
    final start = _dateOnly(range.start);
    final end = _dateOnly(range.end);
    if (end.isBefore(start)) {
      return DateTimeRange(start: end, end: start);
    }

    return DateTimeRange(start: start, end: end);
  }

  void _sortByNewest(List<TransactionModel> data) {
    data.sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
