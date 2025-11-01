import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';

class GetWordById {
  final WordRepository repo;
  GetWordById(this.repo);
  Future<Word?> call(String id) => repo.getById(id);
}
