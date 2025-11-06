import '../../domain/repositories/topic_repository.dart';

class DeleteTopic {
  final TopicRepository repo;
  DeleteTopic(this.repo);
  Future<void> call(String id) => repo.delete(id);
}
