import 'package:cloud_firestore/cloud_firestore.dart';

class WordRemoteDatasource {
  final _db = FirebaseFirestore.instance;
  final String collection = 'words';

  Future<(List<QueryDocumentSnapshot<Map<String, dynamic>>>, DocumentSnapshot?)> getPage({
    required String userId,
    required String topicId,
    DocumentSnapshot? lastDoc,
    int limit = 6,
  }) async {
    Query<Map<String, dynamic>> q = _db.collection(collection)
        .where('userId', isEqualTo: userId)
        .where('topicId', isEqualTo: topicId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDoc != null) q = q.startAfterDocument(lastDoc);
    final snap = await q.get();
    final items = snap.docs;
    final next = items.isNotEmpty ? items.last : null;
    return (items, next);
  }

  Future<String> add(Map<String, dynamic> data) async {
    final ref = await _db.collection(collection).add(data);
    return ref.id;
  }

  Future<void> update(String id, Map<String, dynamic> data) =>
      _db.collection(collection).doc(id).update(data);

  Future<void> delete(String id) =>
      _db.collection(collection).doc(id).delete();

  // ✅ NEW: lấy 1 từ theo id để prefill form sửa
  Future<DocumentSnapshot<Map<String, dynamic>>> getById(String id) =>
      _db.collection(collection).doc(id).get();
}
