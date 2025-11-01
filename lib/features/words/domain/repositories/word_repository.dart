import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/word.dart';

abstract class WordRepository {
  Future<({List<(String id, Word word)> items, DocumentSnapshot? lastDoc})> getPage({
    required String userId,
    required String topicId,
    DocumentSnapshot? lastDoc,
    int limit,
  });
  Future<String> add(Word w);
  Future<void> update(String id, Word w);
  Future<void> delete(String id);

  Future<Word?> getById(String id);
}
