import '../../domain/entities/word.dart';

class SearchWord {
  List<(String id, Word word)> call(
      List<(String id, Word word)> src, {
        String keyword = '',
      }) {
    final k = keyword.trim().toLowerCase();
    final out = src.where((e) {
      final w = e.$2;
      return k.isEmpty || w.word.toLowerCase().contains(k) || w.meaning.toLowerCase().contains(k);
    }).toList();
    out.sort((a, b) => b.$2.createdAt.compareTo(a.$2.createdAt));
    return out;
  }
}
