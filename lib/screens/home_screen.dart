import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/providers/user_provider.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:expense_tracker_app/widgets/balance_card.dart';
import 'package:expense_tracker_app/widgets/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
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
                child: BalanceCard(
                  balance: transactionProvider.balance,
                  income: transactionProvider.totalIncome,
                  expense: transactionProvider.totalExpense,
                ),
              ),
              Expanded(
                child: transactionProvider.transactions.isEmpty
                    ? const Center(child: Text('Chưa có giao dịch nào.'))
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
