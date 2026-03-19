import 'package:expense_tracker_app/utils/app_formatters.dart';
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số dư hiện tại', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              AppFormatters.currency(balance),
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thu: ${AppFormatters.currency(income)}'),
                Text('Chi: ${AppFormatters.currency(expense)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
