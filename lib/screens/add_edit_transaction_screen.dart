import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({super.key});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  TransactionModel? _editingTransaction;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editingTransaction == null) {
      _editingTransaction = ModalRoute.of(context)?.settings.arguments as TransactionModel?;
      if (_editingTransaction != null) {
        _titleController.text = _editingTransaction!.title;
        _amountController.text = _editingTransaction!.amount.toString();
        _categoryController.text = _editingTransaction!.category;
        _selectedType = _editingTransaction!.type;
        _selectedDate = _editingTransaction!.date;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingTransaction != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
              validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tiêu đề' : null,
            ),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Số tiền'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập số tiền' : null,
            ),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Danh mục'),
              validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập danh mục' : null,
            ),
            DropdownButtonFormField<TransactionType>(
              initialValue: _selectedType,
              items: TransactionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
              decoration: const InputDecoration(labelText: 'Loại'),
            ),
            ListTile(
              title: const Text('Ngày'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              onTap: _selectDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final model = TransactionModel(
      id: _editingTransaction?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: amount,
      date: _selectedDate,
      category: _categoryController.text.trim(),
      categoryIcon: 'assets/icons/default.png',
      type: _selectedType,
    );

    final provider = context.read<TransactionProvider>();
    if (_editingTransaction == null) {
      await provider.addTransaction(model);
    } else {
      await provider.updateTransaction(model);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
