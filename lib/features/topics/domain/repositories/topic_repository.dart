import '../entities/topic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class TopicRepository {
  Future<({List<(String id, Topic topic)> items, DocumentSnapshot? lastDoc})> getPage({
    required String userId,
    String? level,
    String? language,
    DocumentSnapshot? lastDoc,
    int limit,
  });
  Future<String> add(Topic t);
  Future<void> update(String id, Topic t);
  Future<void> delete(String id);
}
