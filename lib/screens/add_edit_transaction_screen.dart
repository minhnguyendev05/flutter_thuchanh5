import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/providers/transaction_provider.dart';
import 'package:expense_tracker_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({super.key});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _didAutoSave = false;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionModel? _editingTransaction;
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = AppConstants.categories.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

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
      _selectedCategory = args.category;
      _noteController.text = args.note ?? '';
      _selectedDate = args.date;
      _selectedType = args.type;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _autoSaveWithoutPop();
    }
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
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _isSaving = true;
    try {
      final amount =
          double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
      final model = TransactionModel(
        id: _editingTransaction?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _selectedType,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      final provider = context.read<TransactionProvider>();
      if (_editingTransaction == null) {
        await provider.addTransaction(model);
        _editingTransaction = model;
      } else {
        await provider.updateTransaction(model);
        _editingTransaction = model;
      }

      _didAutoSave = true;
    } finally {
      _isSaving = false;
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _autoSaveWithoutPop() async {
    if (_isSaving || _didAutoSave) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _isSaving = true;
    try {
      final amount =
          double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;
      final model = TransactionModel(
        id: _editingTransaction?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _selectedType,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      final provider = context.read<TransactionProvider>();
      await provider.addOrUpdateTransaction(model, syncRemote: false);
      _editingTransaction = model;

      _didAutoSave = true;
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingTransaction != null;

    return WillPopScope(
      onWillPop: () async {
        await _autoSaveWithoutPop();
        return true;
      },
      child: Scaffold(
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
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Số tiền'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (value) {
                    final raw = (value ?? '').trim().replaceAll(',', '.');
                    final validPattern = RegExp(r'^\d+(\.\d{1,2})?$');
                    if (!validPattern.hasMatch(raw)) {
                      return 'Chỉ nhập số, tối đa 2 số thập phân';
                    }
                    final amount = double.tryParse(raw);
                    if (amount == null || amount <= 0) {
                      return 'Số tiền phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: AppConstants.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(AppConstants.iconForCategory(category), size: 18),
                              const SizedBox(width: 8),
                              Text(category),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Vui lòng chọn danh mục' : null,
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
      ),
    );
  }
}
