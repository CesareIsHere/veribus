import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emiliano_cesare_flutter_template/core/utils/app_failure.dart';
import 'package:emiliano_cesare_flutter_template/models/transactions/transaction_model.dart';
import 'package:emiliano_cesare_flutter_template/repositories/transactions/i_transactions_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// `users/{uid}/transactions`, one document per transaction. Filtering by
/// type needs the composite index in firestore.indexes.json.
class FirestoreTransactionsRepository implements ITransactionsRepository {
  FirestoreTransactionsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthorizedFailure();
    return _db.collection('users/$uid/transactions');
  }

  @override
  Future<TransactionsPage> fetchPage({String? cursor, int limit = 20, TransactionType? type}) async {
    var query = _collection.orderBy('date', descending: true).limit(limit);
    if (type != null) query = query.where('type', isEqualTo: type.name);
    if (cursor != null) query = query.startAfterDocument(await _collection.doc(cursor).get());
    final snap = await query.get();
    return (items: snap.docs.map(_fromDoc).toList(), nextCursor: snap.docs.length == limit ? snap.docs.last.id : null);
  }

  @override
  Future<List<TransactionModel>> fetchRange({required DateTime from, required DateTime to}) async {
    final snap = await _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  @override
  Future<TransactionModel> fetchById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) throw const ServerFailure(statusCode: 404);
    return _fromDoc(doc);
  }

  @override
  Future<TransactionModel> save(TransactionModel transaction) async {
    final doc = transaction.id.isEmpty ? _collection.doc() : _collection.doc(transaction.id);
    await doc.set({
      'title': transaction.title,
      'amount': transaction.amount,
      'category': transaction.category.name,
      'type': transaction.type.name,
      'date': Timestamp.fromDate(transaction.date),
      'note': transaction.note,
    });
    return transaction.copyWith(id: doc.id);
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();

  static TransactionModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TransactionModel(
      id: doc.id,
      title: data['title'] as String,
      amount: data['amount'] as int,
      category: TransactionCategory.values.byName(data['category'] as String),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
    );
  }
}
