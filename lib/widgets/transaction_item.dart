import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/utils/app_formatters.dart';
import 'package:expense_tracker_app/utils/app_routes.dart';
import 'package:expense_tracker_app/utils/constants.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final color = isIncome ? Colors.green : scheme.error;
    final categoryIcon = AppConstants.iconForCategory(transaction.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        key: ValueKey(transaction.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
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
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.transactionDetail,
                arguments: transaction,
              );
            },
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(categoryIcon, color: color),
            ),
            title: Text(
              transaction.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${transaction.category} • ${AppFormatters.date(transaction.date)}'),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${AppFormatters.currency(transaction.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  isIncome ? 'Thu' : 'Chi',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
