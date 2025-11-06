import '../../domain/repositories/topic_repository.dart';
import '../../domain/entities/topic.dart';

class AddTopic {
  final TopicRepository repo;
  AddTopic(this.repo);
  Future<String> call(Topic t) => repo.add(t);
}
