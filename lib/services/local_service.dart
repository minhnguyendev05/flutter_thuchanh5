import 'dart:convert';

import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalService {
  static const String _transactionKey = 'transactions';
  static const String _userKey = 'current_user';

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(transactions.map((e) => e.toJson()).toList());
    await prefs.setString(_transactionKey, encoded);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_transactionKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    final decoded = (jsonDecode(data) as List<dynamic>)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return decoded;
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data == null || data.isEmpty) {
      return null;
    }

    return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}