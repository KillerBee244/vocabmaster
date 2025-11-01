import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';

class UpdateWord {
  final WordRepository repo;
  UpdateWord(this.repo);
  Future<void> call(String id, Word w) => repo.update(id, w);
}
