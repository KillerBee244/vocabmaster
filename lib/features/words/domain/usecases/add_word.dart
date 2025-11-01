import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';

class AddWord {
  final WordRepository repo;
  AddWord(this.repo);
  Future<String> call(Word w) => repo.add(w);
}
