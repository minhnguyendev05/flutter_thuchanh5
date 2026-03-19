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
  final _noteController = TextEditingController();

  TransactionModel? _editingTransaction;
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editingTransaction != null) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TransactionModel) {
      _editingTransaction = args;
      _titleController.text = args.title;
      _amountController.text = args.amount.toString();
      _categoryController.text = args.category;
      _noteController.text = args.note ?? '';
      _selectedDate = args.date;
      _selectedType = args.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _selectedDate,
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
      type: _selectedType,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingTransaction != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment<TransactionType>(
                    value: TransactionType.expense,
                    label: Text('Chi'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment<TransactionType>(
                    value: TransactionType.income,
                    label: Text('Thu'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (value) {
                  setState(() {
                    _selectedType = value.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Số tiền'),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Vui lòng nhập danh mục' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.date_range),
                label: Text('Ngày: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(isEditing ? 'Cập nhật' : 'Lưu giao dịch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
