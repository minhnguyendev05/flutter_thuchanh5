import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/utils/app_formatters.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }
          return Column(
            children: [
              _buildSearchBar(context, provider),
              _buildDashboard(context, provider),
              _buildFilterBar(context, provider),
              Expanded(child: _buildTransactionList(context, provider)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.transactionForm),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Expense Tracker - Team'),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.statistics),
          icon: const Icon(Icons.pie_chart_outline),
          tooltip: 'Thống kê',
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, TransactionProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm giao dịch...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        onChanged: (value) => provider.search(value),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, TransactionProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDashboardItem('Tổng thu', provider.totalIncome, Colors.green),
            _buildDashboardItem('Tổng chi', provider.totalExpense, Colors.red),
            _buildDashboardItem(
              'Số dư',
              provider.balance,
              provider.balance >= 0 ? Colors.blue : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount >= 0 ? '+' : ''}${AppFormatters.currency(amount.abs())}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, TransactionProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SegmentedButton<FilterType>(
        segments: const [
          ButtonSegment(value: FilterType.all, label: Text('Tất cả')),
          ButtonSegment(value: FilterType.income, label: Text('Thu')),
          ButtonSegment(value: FilterType.expense, label: Text('Chi')),
        ],
        selected: {provider.filterType},
        onSelectionChanged: (Set<FilterType> selected) {
          provider.setFilter(selected.first);
        },
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final transactions = provider.filteredTransactions;
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 100,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(context, transaction);
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, dynamic transaction) {
    final color = transaction.isIncome ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: Image.asset(
          transaction.categoryIcon,
          width: 40,
          height: 40,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.category, size: 40),
        ),
        title: Text(transaction.title),
        subtitle: Text(AppFormatters.date(transaction.date)),
        trailing: Text(
          '${transaction.isIncome ? '+' : '-'}${AppFormatters.currency(transaction.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.transactionForm,
          arguments: transaction,
        ),
      ),
    );
  }
}
