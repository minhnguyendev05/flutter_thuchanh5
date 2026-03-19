import 'dart:convert';

import 'package:expense_tracker_app/models/transaction_model.dart';
import 'package:expense_tracker_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalService {
  static const String _legacyTransactionKey = 'transactions';
  static const String _userKey = 'current_user';

  String _transactionKeyByUser(String userId) => 'transactions_$userId';

  Future<void> saveTransactionsByUser({
    required String userId,
    required List<TransactionModel> transactions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(transactions.map((e) => e.toJson()).toList());
    await prefs.setString(_transactionKeyByUser(userId), encoded);
  }

  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userScopedData = prefs.getString(_transactionKeyByUser(userId));
    if (userScopedData != null && userScopedData.isNotEmpty) {
      final decoded = (jsonDecode(userScopedData) as List<dynamic>)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return decoded;
    }

    // Backward compatibility: migrate old shared key once to the current user.
    final legacyData = prefs.getString(_legacyTransactionKey);
    if (legacyData == null || legacyData.isEmpty) {
      return [];
    }

    final decoded = (jsonDecode(legacyData) as List<dynamic>)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    await prefs.setString(_transactionKeyByUser(userId), legacyData);
    await prefs.remove(_legacyTransactionKey);
    return decoded;
  }

  @Deprecated('Use saveTransactionsByUser instead')
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(transactions.map((e) => e.toJson()).toList());
    await prefs.setString(_legacyTransactionKey, encoded);
  }

  @Deprecated('Use getTransactionsByUser instead')
  Future<List<TransactionModel>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_legacyTransactionKey);

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
