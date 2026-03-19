import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/providers/user_provider.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:expense_tracker_app/widgets/balance_card.dart';
import 'package:expense_tracker_app/widgets/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            return Center(child: Text(transactionProvider.error!));
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
                            onEdit: () => Navigator.pushNamed(
                              context,
                              AppRoutes.transactionForm,
                              arguments: transaction,
                            ),
                            onDelete: () => context
                                .read<TransactionProvider>()
                                .deleteTransaction(transaction.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.transactionForm),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
    );
  }
}
