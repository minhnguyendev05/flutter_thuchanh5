import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/utils/app_formatters.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            icon: Icons.edit,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Sửa',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            icon: Icons.delete,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: 'Xóa',
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.transactionDetail,
            arguments: transaction,
          );
        },
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${transaction.category} • ${AppFormatters.date(transaction.date)}'),
        trailing: Text(
          '${isIncome ? '+' : '-'}${AppFormatters.currency(transaction.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
