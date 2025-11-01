import '../../domain/repositories/topic_repository.dart';
import '../../domain/entities/topic.dart';

class UpdateTopic {
  final TopicRepository repo;
  UpdateTopic(this.repo);
  Future<void> call(String id, Topic t) => repo.update(id, t);
}
