import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/utils/app_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  Widget _buildPieSection({
    required BuildContext context,
    required String title,
    required Map<String, double> values,
    required List<Color> colors,
    required String emptyMessage,
  }) {
    final total = values.values.fold<double>(0, (sum, amount) => sum + amount);

    if (total <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(emptyMessage),
        ),
      );
    }

    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final percent = (entry.value / total) * 100;
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${percent.toStringAsFixed(0)}%',
          color: colors[i % colors.length],
          radius: 78,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            ListView.builder(
              itemCount: entries.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final color = colors[index % colors.length];
                final percent = (entry.value / total) * 100;

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: color, radius: 10),
                  title: Text(entry.key),
                  subtitle: Text('${percent.toStringAsFixed(1)}%'),
                  trailing: Text(AppFormatters.currency(entry.value)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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

            final expenseColors = <Color>[
              Colors.red,
              Colors.orange,
              Colors.amber,
              Colors.pink,
              Colors.indigo,
              Colors.cyan,
              Colors.teal,
              Colors.blue,
            ];

            final incomeColors = <Color>[
              Colors.green,
              Colors.lightGreen,
              Colors.teal,
              Colors.cyan,
              Colors.blue,
              Colors.indigo,
              Colors.amber,
              Colors.orange,
            ];

            return ListView(
              children: [
                _buildPieSection(
                  context: context,
                  title: 'Tỷ lệ chi theo danh mục',
                  values: provider.allExpenseByCategory,
                  colors: expenseColors,
                  emptyMessage: 'Chưa có dữ liệu chi tiêu để thống kê.',
                ),
                const SizedBox(height: 14),
                _buildPieSection(
                  context: context,
                  title: 'Tỷ lệ thu theo danh mục',
                  values: provider.allIncomeByCategory,
                  colors: incomeColors,
                  emptyMessage: 'Chưa có dữ liệu thu nhập để thống kê.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
