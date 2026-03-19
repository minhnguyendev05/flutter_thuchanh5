import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/utils/app_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
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
                        provider.error!,
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

            final expenseByCategory = <String, double>{};
            for (final tx in provider.transactions) {
              if (tx.type == TransactionType.expense) {
                expenseByCategory.update(
                  tx.category,
                  (value) => value + tx.amount,
                  ifAbsent: () => tx.amount,
                );
              }
            }

            final totalExpense = expenseByCategory.values.fold<double>(0, (sum, amount) => sum + amount);

            if (totalExpense <= 0) {
              return const Center(child: Text('Chưa có dữ liệu chi tiêu để thống kê.'));
            }

            final colors = <Color>[
              Colors.red,
              Colors.orange,
              Colors.amber,
              Colors.pink,
              Colors.indigo,
              Colors.cyan,
              Colors.teal,
              Colors.blue,
            ];

            final entries = expenseByCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final sections = <PieChartSectionData>[];
            for (var i = 0; i < entries.length; i++) {
              final entry = entries[i];
              final percent = (entry.value / totalExpense) * 100;
              sections.add(
                PieChartSectionData(
                  value: entry.value,
                  title: '${percent.toStringAsFixed(0)}%',
                  color: colors[i % colors.length],
                  radius: 82,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tỷ lệ chi theo danh mục',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sections,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final color = colors[index % colors.length];
                      final percent = (entry.value / totalExpense) * 100;

                      return ListTile(
                        leading: CircleAvatar(backgroundColor: color),
                        title: Text(entry.key),
                        subtitle: Text('${percent.toStringAsFixed(1)}%'),
                        trailing: Text(AppFormatters.currency(entry.value)),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
