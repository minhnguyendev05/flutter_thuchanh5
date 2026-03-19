import 'package:flutter/material.dart';

class AppConstants {
  static const String appTitle = 'Expense Tracker - Nhom 8';

  static const List<String> categories = <String>[
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Hóa đơn',
    'Giải trí',
    'Lương',
    'Thưởng',
    'Khác',
  ];

  static const Map<String, IconData> categoryIcons = <String, IconData>{
    'Ăn uống': Icons.restaurant,
    'Di chuyển': Icons.directions_bus,
    'Mua sắm': Icons.shopping_bag,
    'Hóa đơn': Icons.receipt_long,
    'Giải trí': Icons.movie,
    'Lương': Icons.account_balance_wallet,
    'Thưởng': Icons.emoji_events,
    'Khác': Icons.category,
  };

  static IconData iconForCategory(String category) {
    final trimmed = category.trim();
    final exact = categoryIcons[trimmed];
    if (exact != null) {
      return exact;
    }

    switch (trimmed.toLowerCase()) {
      case 'an uong':
        return categoryIcons['Ăn uống']!;
      case 'di chuyen':
        return categoryIcons['Di chuyển']!;
      case 'mua sam':
        return categoryIcons['Mua sắm']!;
      case 'hoa don':
        return categoryIcons['Hóa đơn']!;
      case 'giai tri':
        return categoryIcons['Giải trí']!;
      case 'luong':
        return categoryIcons['Lương']!;
      case 'thuong':
        return categoryIcons['Thưởng']!;
      case 'khac':
        return categoryIcons['Khác']!;
      default:
        return Icons.category;
    }
  }
}
