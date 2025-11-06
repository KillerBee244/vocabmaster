import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';
import '../datasources/word_remote_datasource.dart';
import '../models/word_model.dart';

class WordRepositoryImpl implements WordRepository {
  final WordRemoteDatasource remote;
  WordRepositoryImpl(this.remote);

  @override
  Future<({List<(String id, Word word)> items, DocumentSnapshot? lastDoc})> getPage({
    required String userId,
    required String topicId,
    DocumentSnapshot? lastDoc,
    int limit = 6,
  }) async {
    final (raw, next) = await remote.getPage(userId: userId, topicId: topicId, lastDoc: lastDoc, limit: limit);
    final items = raw.map((d) {
      final m = WordModel.fromJson(d.id, d.data());
      return (m.id, Word(
        userId: m.userId,
        topicId: m.topicId,
        word: m.word,
        meaning: m.meaning,
        example: m.example,
        imageUrl: m.imageUrl,
        pronunciation: m.pronunciation,
        audioUrl: m.audioUrl,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      ));
    }).toList();
    return (items: items, lastDoc: next);
  }

  @override
  Future<String> add(Word w) {
    final payload = WordModel(
      id: '',
      userId: w.userId,
      topicId: w.topicId,
      word: w.word,
      meaning: w.meaning,
      example: w.example,
      imageUrl: w.imageUrl,
      pronunciation: w.pronunciation,
      audioUrl: w.audioUrl,
      createdAt: w.createdAt,
      updatedAt: w.updatedAt,
    ).toJson();
    return remote.add(payload);
  }

  @override
  Future<void> update(String id, Word w) {
    final payload = WordModel(
      id: id,
      userId: w.userId,
      topicId: w.topicId,
      word: w.word,
      meaning: w.meaning,
      example: w.example,
      imageUrl: w.imageUrl,
      pronunciation: w.pronunciation,
      audioUrl: w.audioUrl,
      createdAt: w.createdAt,   // ✅ giữ nguyên createdAt cũ
      updatedAt: w.updatedAt,
    ).toJson();
    return remote.update(id, payload);
  }

  @override
  Future<void> delete(String id) => remote.delete(id);

  @override
  Future<Word?> getById(String id) async {
    final snap = await remote.getById(id);
    if (!snap.exists) return null;
    final m = WordModel.fromJson(snap.id, snap.data()!);
    return Word(
      userId: m.userId,
      topicId: m.topicId,
      word: m.word,
      meaning: m.meaning,
      example: m.example,
      imageUrl: m.imageUrl,
      pronunciation: m.pronunciation,
      audioUrl: m.audioUrl,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
    );
  }
}
