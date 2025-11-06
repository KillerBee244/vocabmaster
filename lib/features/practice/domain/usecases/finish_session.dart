import 'package:cloud_firestore/cloud_firestore.dart';

class FinishSession {
  final _db = FirebaseFirestore.instance;

  Future<void> call({
    required String userId,
    required String topicId,
    required String mode,
    required int totalWords,
    required int timeSpent,
    double score = 0,
  }) async {
    await _db.collection('sessions').add({
      'userId': userId,
      'topicId': topicId,
      'mode': mode,
      'totalWords': totalWords,
      'timeSpent': timeSpent,
      'score': score,
      'completedAt': DateTime.now(),
    });
  }
}
