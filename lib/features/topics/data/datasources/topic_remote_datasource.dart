import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopicRemoteDatasource {
  final _db = FirebaseFirestore.instance;
  final String collection = 'topics';

  Future<(List<QueryDocumentSnapshot<Map<String, dynamic>>>, DocumentSnapshot?)> getPage({
    required String userId,
    String? level,
    String? language,
    DocumentSnapshot? lastDoc,
    int limit = 6,
  }) async {
    Query<Map<String, dynamic>> q = _db.collection(collection).where('userId', isEqualTo: userId);
    if (level != null && level.isNotEmpty && level != 'Tất cả') {
      q = q.where('level', isEqualTo: level);
    }
    if (language != null && language.isNotEmpty && language != 'Tất cả') {
      q = q.where('language', isEqualTo: language);
    }
    q = q.orderBy('createdAt', descending: true).limit(limit);
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



  Future<DocumentSnapshot<Map<String, dynamic>>> getById(String id) =>
      _db.collection(collection).doc(id).get();

  Future<void> delete(String id) async {
    const int chunk = 500;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(plugin: 'auth', message: 'Not signed in');
    }

    // Kiểm tra quyền sở hữu topic trước khi xoá
    final topicRef = _db.collection(collection).doc(id);
    final topicSnap = await topicRef.get();
    if (!topicSnap.exists || topicSnap.data()?['userId'] != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'permission-denied',
      );
    }

    // 1) Xoá WORDS (topicId = id, userId = uid)
    while (true) {
      final qs = await _db
          .collection('words')
          .where('userId', isEqualTo: uid)
          .where('topicId', isEqualTo: id)
          .limit(chunk)
          .get();

      if (qs.docs.isEmpty) break;

      final batch = _db.batch();
      for (final d in qs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      if (qs.docs.length < chunk) break;
    }

    // 2) Xoá SESSIONS (topicId = id, userId = uid)
    while (true) {
      final qs = await _db
          .collection('sessions')
          .where('userId', isEqualTo: uid)
          .where('topicId', isEqualTo: id)
          .limit(chunk)
          .get();

      if (qs.docs.isEmpty) break;

      final batch = _db.batch();
      for (final d in qs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      if (qs.docs.length < chunk) break;
    }

    // 3) Xoá TOPIC
    await topicRef.delete();
  }

}
