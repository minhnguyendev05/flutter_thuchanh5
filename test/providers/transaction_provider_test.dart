import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/services/local_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocalService extends LocalService {
  FakeLocalService({List<TransactionModel>? seed})
    : _stored = List<TransactionModel>.from(seed ?? <TransactionModel>[]);

  List<TransactionModel> _stored;
  bool failOnLoad = false;
  bool failOnSave = false;
  int saveCallCount = 0;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    if (failOnLoad) {
      throw Exception('load failed');
    }

    return List<TransactionModel>.from(_stored);
  }

  @override
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    if (failOnSave) {
      throw Exception('save failed');
    }

    saveCallCount += 1;
    _stored = List<TransactionModel>.from(transactions);
  }
}

TransactionModel tx({
  required String id,
  required String title,
  required double amount,
  required TransactionType type,
  required DateTime date,
}) {
  return TransactionModel(
    id: id,
    title: title,
    amount: amount,
    type: type,
    category: 'General',
    date: date,
  );
}

void main() {
  const debounce = Duration(milliseconds: 15);
  final fixedNow = DateTime(2026, 3, 19, 10);

  test(
    'loadTransactions sorts newest and computes totals from base list',
    () async {
      final fake = FakeLocalService(
        seed: [
          tx(
            id: '1',
            title: 'Old expense',
            amount: 100,
            type: TransactionType.expense,
            date: DateTime(2026, 3, 10),
          ),
          tx(
            id: '2',
            title: 'New income',
            amount: 250,
            type: TransactionType.income,
            date: DateTime(2026, 3, 18),
          ),
        ],
      );

      final provider = TransactionProvider(
        localService: fake,
        searchDebounceDuration: debounce,
        nowProvider: () => fixedNow,
      );

      await provider.loadTransactions();

      expect(provider.transactions.map((e) => e.id).toList(), <String>[
        '2',
        '1',
      ]);
      expect(provider.totalIncome, 250);
      expect(provider.totalExpense, 100);
      expect(provider.balance, 150);
    },
  );

  test(
    'supports type filter + custom date range + search query together',
    () async {
      final fake = FakeLocalService(
        seed: [
          tx(
            id: 'a',
            title: 'An trua',
            amount: 50,
            type: TransactionType.expense,
            date: DateTime(2026, 3, 19),
          ),
          tx(
            id: 'b',
            title: 'Luong thang',
            amount: 1000,
            type: TransactionType.income,
            date: DateTime(2026, 3, 18),
          ),
          tx(
            id: 'c',
            title: 'An toi',
            amount: 30,
            type: TransactionType.expense,
            date: DateTime(2026, 3, 17),
          ),
          tx(
            id: 'd',
            title: 'Ca phe',
            amount: 20,
            type: TransactionType.expense,
            date: DateTime(2026, 2, 20),
          ),
        ],
      );

      final provider = TransactionProvider(
        localService: fake,
        searchDebounceDuration: debounce,
        nowProvider: () => fixedNow,
      );
      await provider.loadTransactions();

      provider.setTypeFilter(TransactionTypeFilter.expense);
      provider.setCustomDateRange(
        DateTimeRange(start: DateTime(2026, 3, 17), end: DateTime(2026, 3, 19)),
      );
      provider.setSearchQuery('an');

      expect(provider.transactions.map((e) => e.id).toList(), <String>[
        'a',
        'c',
      ]);
      expect(provider.filteredExpense, 80);
      expect(provider.filteredIncome, 0);
      expect(provider.filteredBalance, -80);
    },
  );

  test('time filters work for today, week, month and year', () async {
    final fake = FakeLocalService(
      seed: [
        tx(
          id: 'today',
          title: 'Today tx',
          amount: 1,
          type: TransactionType.expense,
          date: DateTime(2026, 3, 19),
        ),
        tx(
          id: 'week',
          title: 'Week tx',
          amount: 1,
          type: TransactionType.expense,
          date: DateTime(2026, 3, 16),
        ),
        tx(
          id: 'month',
          title: 'Month tx',
          amount: 1,
          type: TransactionType.expense,
          date: DateTime(2026, 3, 2),
        ),
        tx(
          id: 'year',
          title: 'Year tx',
          amount: 1,
          type: TransactionType.expense,
          date: DateTime(2026, 1, 7),
        ),
        tx(
          id: 'old',
          title: 'Old tx',
          amount: 1,
          type: TransactionType.expense,
          date: DateTime(2025, 12, 31),
        ),
      ],
    );

    final provider = TransactionProvider(
      localService: fake,
      searchDebounceDuration: debounce,
      nowProvider: () => fixedNow,
    );
    await provider.loadTransactions();

    provider.setTimeFilter(TransactionTimeFilter.today);
    expect(provider.transactions.map((e) => e.id).toList(), <String>['today']);

    provider.setTimeFilter(TransactionTimeFilter.thisWeek);
    expect(provider.transactions.map((e) => e.id).toList(), <String>[
      'today',
      'week',
    ]);

    provider.setTimeFilter(TransactionTimeFilter.thisMonth);
    expect(provider.transactions.map((e) => e.id).toList(), <String>[
      'today',
      'week',
      'month',
    ]);

    provider.setTimeFilter(TransactionTimeFilter.thisYear);
    expect(provider.transactions.map((e) => e.id).toList(), <String>[
      'today',
      'week',
      'month',
      'year',
    ]);
  });

  test('onSearchChanged uses debounce and keeps only latest query', () async {
    final fake = FakeLocalService(
      seed: [
        tx(
          id: '1',
          title: 'An trua',
          amount: 20,
          type: TransactionType.expense,
          date: DateTime(2026, 3, 19),
        ),
        tx(
          id: '2',
          title: 'Ca phe',
          amount: 10,
          type: TransactionType.expense,
          date: DateTime(2026, 3, 18),
        ),
      ],
    );

    final provider = TransactionProvider(
      localService: fake,
      searchDebounceDuration: debounce,
      nowProvider: () => fixedNow,
    );
    await provider.loadTransactions();

    provider.onSearchChanged('an');
    provider.onSearchChanged('ca');

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(provider.searchQuery, 'ca');
    expect(provider.transactions.map((e) => e.id).toList(), <String>['2']);
  });

  test('add/update/delete persist and keep sorted order', () async {
    final fake = FakeLocalService(seed: []);
    final provider = TransactionProvider(
      localService: fake,
      searchDebounceDuration: debounce,
      nowProvider: () => fixedNow,
    );

    await provider.addTransaction(
      tx(
        id: '1',
        title: 'Older',
        amount: 10,
        type: TransactionType.expense,
        date: DateTime(2026, 3, 10),
      ),
    );
    await provider.addTransaction(
      tx(
        id: '2',
        title: 'Newer',
        amount: 20,
        type: TransactionType.expense,
        date: DateTime(2026, 3, 19),
      ),
    );

    expect(provider.transactions.map((e) => e.id).toList(), <String>['2', '1']);

    await provider.updateTransaction(
      tx(
        id: '1',
        title: 'Updated newest',
        amount: 15,
        type: TransactionType.expense,
        date: DateTime(2026, 3, 20),
      ),
    );

    expect(provider.transactions.map((e) => e.id).toList(), <String>['1', '2']);
    expect(provider.transactions.first.title, 'Updated newest');

    await provider.deleteTransaction('2');
    expect(provider.transactions.map((e) => e.id).toList(), <String>['1']);
    expect(fake.saveCallCount, 4);
  });
}
