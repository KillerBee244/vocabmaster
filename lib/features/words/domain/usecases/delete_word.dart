import '../../domain/repositories/word_repository.dart';

class DeleteWord {
  final WordRepository repo;
  DeleteWord(this.repo);
  Future<void> call(String id) => repo.delete(id);
}
