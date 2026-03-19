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
            final income = provider.totalIncome;
            final expense = provider.totalExpense;
            final total = income + expense;

            if (total <= 0) {
              return const Center(child: Text('Chưa có dữ liệu để thống kê.'));
            }

            return Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: income,
                          title: 'Thu',
                          color: Colors.green,
                        ),
                        PieChartSectionData(
                          value: expense,
                          title: 'Chi',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green),
                  title: const Text('Tổng thu'),
                  trailing: Text(AppFormatters.currency(income)),
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.red),
                  title: const Text('Tổng chi'),
                  trailing: Text(AppFormatters.currency(expense)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
