import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/topic.dart';
import '../../domain/repositories/topic_repository.dart';
import '../datasources/topic_remote_datasource.dart';
import '../models/topic_model.dart';

class TopicRepositoryImpl implements TopicRepository {
  final TopicRemoteDatasource remote;
  TopicRepositoryImpl(this.remote);

  @override
  Future<({List<(String id, Topic topic)> items, DocumentSnapshot? lastDoc})> getPage({
    required String userId,
    String? level,
    String? language,
    DocumentSnapshot? lastDoc,
    int limit = 6,
  }) async {
    final (raw, next) = await remote.getPage(userId: userId, level: level, language: language, lastDoc: lastDoc, limit: limit);
    final items = raw.map((d) {
      final m = TopicModel.fromJson(d.id, d.data());
      return (m.id, Topic(
        userId: m.userId,
        name: m.name,
        description: m.description,
        level: m.level,
        language: m.language,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      ));
    }).toList();
    return (items: items, lastDoc: next);
  }

  @override
  Future<String> add(Topic t) {
    final payload = TopicModel(
      id: '',
      userId: t.userId,
      name: t.name,
      description: t.description,
      level: t.level,
      language: t.language,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
    ).toJson();
    return remote.add(payload);
  }

  @override
  Future<void> update(String id, Topic t) {
    final payload = TopicModel(
      id: id,
      userId: t.userId,
      name: t.name,
      description: t.description,
      level: t.level,
      language: t.language,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
    ).toJson();
    return remote.update(id, payload);
  }

  @override
  Future<void> delete(String id) => remote.delete(id);

}
