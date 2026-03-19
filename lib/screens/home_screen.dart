import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/providers/user_provider.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:expense_tracker_app/utils/constants.dart';
import 'package:expense_tracker_app/widgets/dashboard_widget.dart';
import 'package:expense_tracker_app/widgets/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _transactionSnapshot(TransactionProvider provider) {
    return provider.transactions
        .map(
          (tx) =>
              '${tx.id}|${tx.title}|${tx.amount}|${tx.category}|${tx.type.name}|${tx.date.toIso8601String()}|${tx.note ?? ''}',
        )
        .join('||');
  }

  Future<void> _openTransactionForm(
    BuildContext context, {
    Object? arguments,
    required String successMessage,
  }) async {
    final providerBefore = context.read<TransactionProvider>();
    final beforeSnapshot = _transactionSnapshot(providerBefore);

    await Navigator.pushNamed(
      context,
      AppRoutes.transactionForm,
      arguments: arguments,
    );

    if (!context.mounted) {
      return;
    }

    final providerAfter = context.read<TransactionProvider>();
    final afterSnapshot = _transactionSnapshot(providerAfter);
    if (beforeSnapshot == afterSnapshot) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(successMessage)));
  }

  Future<void> _confirmDelete(BuildContext context, String transactionId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    await context.read<TransactionProvider>().deleteTransaction(transactionId);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch.')));
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final now = DateTime.now();
    final initialRange = provider.customDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      helpText: 'Chọn khoảng thời gian',
    );

    if (!context.mounted || selected == null) {
      return;
    }

    provider.setCustomDateRange(selected);
  }

  Widget _buildTypeFilters(TransactionProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<TransactionTypeFilter>(
        expandedInsets: EdgeInsets.zero,
        segments: const [
          ButtonSegment<TransactionTypeFilter>(
            value: TransactionTypeFilter.all,
            label: Text('Tất cả'),
          ),
          ButtonSegment<TransactionTypeFilter>(
            value: TransactionTypeFilter.income,
            label: Text('Thu'),
          ),
          ButtonSegment<TransactionTypeFilter>(
            value: TransactionTypeFilter.expense,
            label: Text('Chi'),
          ),
        ],
        selected: <TransactionTypeFilter>{provider.typeFilter},
        onSelectionChanged: (value) => provider.setTypeFilter(value.first),
      ),
    );
  }

  Future<void> _showUserInfoSheet(BuildContext context) async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(user.name.isEmpty ? 'U' : user.name.characters.first.toUpperCase())
                    : null,
              ),
              const SizedBox(height: 10),
              Text(user.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await context.read<UserProvider>().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeFilterLabel(TransactionTimeFilter filter) {
    switch (filter) {
      case TransactionTimeFilter.all:
        return 'Tất cả thời gian';
      case TransactionTimeFilter.today:
        return 'Hôm nay';
      case TransactionTimeFilter.thisWeek:
        return 'Tuần này';
      case TransactionTimeFilter.thisMonth:
        return 'Tháng này';
      case TransactionTimeFilter.thisYear:
        return 'Năm nay';
      case TransactionTimeFilter.custom:
        return 'Tùy chỉnh';
    }
  }

  Widget _buildTimeFilters(BuildContext context, TransactionProvider provider) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<TransactionTimeFilter>(
            value: provider.timeFilter,
            decoration: const InputDecoration(
              labelText: 'Lọc thời gian',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: TransactionTimeFilter.values
                .map(
                  (filter) => DropdownMenuItem<TransactionTimeFilter>(
                    value: filter,
                    child: Text(_timeFilterLabel(filter)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              provider.setTimeFilter(value);
              if (value == TransactionTimeFilter.custom) {
                _pickCustomDateRange(context);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: provider.clearFilters,
          icon: const Icon(Icons.filter_alt_off),
          tooltip: 'Xóa bộ lọc',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 56),
            const SizedBox(height: 10),
            Text(
              'Chưa có giao dịch nào',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Nhấn nút + để thêm giao dịch đầu tiên.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _showUserInfoSheet(context),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.name.isEmpty ? 'U' : user.name.characters.first.toUpperCase(),
                        )
                      : null,
                ),
              ),
            ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.statistics),
            icon: const Icon(Icons.pie_chart_outline),
            tooltip: 'Thống kê',
          ),
          IconButton(
            onPressed: () async {
              await context.read<UserProvider>().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactionProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      transactionProvider.error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.read<TransactionProvider>().loadTransactions(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DashboardWidget(
                      balance: transactionProvider.balance,
                      income: transactionProvider.totalIncome,
                      expense: transactionProvider.totalExpense,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: transactionProvider.onSearchQueryChanged,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tiêu đề giao dịch...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: transactionProvider.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  transactionProvider.setSearchQuery('');
                                },
                                icon: const Icon(Icons.close),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTypeFilters(transactionProvider),
                    const SizedBox(height: 12),
                    _buildTimeFilters(context, transactionProvider),
                  ],
                ),
              ),
              Expanded(
                child: transactionProvider.transactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: transactionProvider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactionProvider.transactions[index];
                          return TransactionItem(
                            transaction: transaction,
                            onEdit: () => _openTransactionForm(
                              context,
                              arguments: transaction,
                              successMessage: 'Sửa giao dịch thành công.',
                            ),
                            onDelete: () => _confirmDelete(context, transaction.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTransactionForm(
          context,
          successMessage: 'Thêm giao dịch thành công.',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
    );
  }
}
