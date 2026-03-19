import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_app/models/transaction_model.dart';

class FirebaseTransactionService {
  FirebaseTransactionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    final snapshot = await _collection(userId).get();
    return snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveTransactionsByUser({
    required String userId,
    required List<TransactionModel> transactions,
  }) async {
    final batch = _firestore.batch();
    final col = _collection(userId);

    final existing = await col.get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final tx in transactions) {
      batch.set(col.doc(tx.id), tx.toJson());
    }

    await batch.commit();
  }
}
