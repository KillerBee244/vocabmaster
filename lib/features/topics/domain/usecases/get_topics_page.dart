import '../../domain/repositories/topic_repository.dart';
import '../../domain/entities/topic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GetTopicsPage {
  final TopicRepository repo;
  GetTopicsPage(this.repo);

  Future<({List<(String id, Topic topic)> items, DocumentSnapshot? lastDoc})> call({
    required String userId,
    String? level,
    String? language,
    DocumentSnapshot? lastDoc,
    int limit = 6,
  }) {
    return repo.getPage(userId: userId, level: level, language: language, lastDoc: lastDoc, limit: limit);
  }
}
