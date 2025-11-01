import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';

class GetWordsPage {
  final WordRepository repo;
  GetWordsPage(this.repo);

  Future<({List<(String id, Word word)> items, DocumentSnapshot? lastDoc})> call({
    required String userId,
    required String topicId,
    DocumentSnapshot? lastDoc,
    int limit = 6,
  }) => repo.getPage(userId: userId, topicId: topicId, lastDoc: lastDoc, limit: limit);
}
