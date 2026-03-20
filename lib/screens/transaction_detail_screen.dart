import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/utils/app_formatters.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  String? _transactionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_transactionId != null) {
      return;
    }

    final transaction = ModalRoute.of(context)!.settings.arguments as TransactionModel;
    _transactionId = transaction.id;
  }

  @override
  Widget build(BuildContext context) {
    final transaction = context.select<TransactionProvider, TransactionModel?>((provider) {
      final id = _transactionId;
      if (id == null) {
        return null;
      }
      return provider.getById(id);
    });

    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết giao dịch')),
        body: const Center(child: Text('Giao dịch không còn tồn tại.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết giao dịch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.transactionForm,
                arguments: transaction,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, transaction),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(transaction),
            const SizedBox(height: 24),
            _buildDetailRow(context, Icons.category, 'Danh mục', transaction.category),
            const Divider(height: 32),
            _buildDetailRow(context, Icons.calendar_today, 'Ngày', AppFormatters.date(transaction.date)),
            const Divider(height: 32),
            _buildDetailRow(context, Icons.notes, 'Ghi chú', transaction.note ?? 'Không có ghi chú'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            transaction.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${isIncome ? '+' : '-'}${AppFormatters.currency(transaction.amount)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<TransactionProvider>().deleteTransaction(transaction.id);
      if (context.mounted) {
        Navigator.pop(context); // Back to Home
      }
    }
  }
}
