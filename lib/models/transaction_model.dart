enum TransactionType { income, expense }

class TransactionModel {
  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.categoryIcon,
    required this.type,
    this.note,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String categoryIcon;
  final TransactionType type;
  final String? note;

  bool get isIncome => type == TransactionType.income;

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? categoryIcon,
    TransactionType? type,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      categoryIcon: json['categoryIcon'] as String,
      type: (json['type'] as String) == TransactionType.income.name
          ? TransactionType.income
          : TransactionType.expense,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'categoryIcon': categoryIcon,
      'type': type.name,
      'note': note,
    };
  }
}
