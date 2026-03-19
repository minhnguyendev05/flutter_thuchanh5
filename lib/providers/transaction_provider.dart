import 'dart:async';

import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/services/local_service.dart';
import 'package:flutter/material.dart';

enum TransactionTypeFilter { all, income, expense }

enum TransactionTimeFilter { all, today, thisWeek, thisMonth, thisYear, custom }

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({
    LocalService? localService,
    Duration? searchDebounceDuration,
    DateTime Function()? nowProvider,
  }) : _localService = localService ?? LocalService(),
       _searchDebounceDuration =
           searchDebounceDuration ?? const Duration(milliseconds: 350),
       _nowProvider = nowProvider ?? DateTime.now;

  final LocalService _localService;
  final Duration _searchDebounceDuration;
  final DateTime Function() _nowProvider;

  final List<TransactionModel> _transactions = [];
  final List<TransactionModel> _filteredTransactions = [];
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

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _localService.getTransactions();
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

  void onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      setSearchQuery(query);
    });
  }

  void setSearchQuery(String query) {
    final normalized = query.trim();
    if (_searchQuery == normalized) {
      return;
    }

    _searchQuery = normalized;
    _applyFilterAndSearch();
  }

  void clearSearch() {
    setSearchQuery('');
  }

  void setTypeFilter(TransactionTypeFilter filter) {
    if (_typeFilter == filter) {
      return;
    }

    _typeFilter = filter;
    _applyFilterAndSearch();
  }

  void setTimeFilter(TransactionTimeFilter filter) {
    if (_timeFilter == filter && filter != TransactionTimeFilter.custom) {
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
      final hadCustomRange =
          _customDateRange != null || _timeFilter != TransactionTimeFilter.all;
      _customDateRange = null;
      _timeFilter = TransactionTimeFilter.all;
      if (hadCustomRange) {
        _applyFilterAndSearch();
      }
      return;
    }

    final normalizedRange = _normalizeDateRange(range);
    final hasSameRange =
        _customDateRange != null &&
        _isSameDate(_customDateRange!.start, normalizedRange.start) &&
        _isSameDate(_customDateRange!.end, normalizedRange.end) &&
        _timeFilter == TransactionTimeFilter.custom;

    if (hasSameRange) {
      return;
    }

    _customDateRange = normalizedRange;
    _timeFilter = TransactionTimeFilter.custom;
    _applyFilterAndSearch();
  }

  void clearFilters() {
    final hasStateToClear =
        _searchQuery.isNotEmpty ||
        _typeFilter != TransactionTypeFilter.all ||
        _timeFilter != TransactionTimeFilter.all;

    _searchDebounceTimer?.cancel();
    _searchQuery = '';
    _typeFilter = TransactionTypeFilter.all;
    _timeFilter = TransactionTimeFilter.all;
    _customDateRange = null;

    if (hasStateToClear) {
      _applyFilterAndSearch();
    }
  }

  void clearInMemoryData() {
    _searchDebounceTimer?.cancel();
    _transactions.clear();
    _filteredTransactions.clear();
    _searchQuery = '';
    _typeFilter = TransactionTypeFilter.all;
    _timeFilter = TransactionTimeFilter.all;
    _customDateRange = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _localService.saveTransactions(_transactions);
      if (_error != null) {
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Cannot save transactions: $e';
      notifyListeners();
    }
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
