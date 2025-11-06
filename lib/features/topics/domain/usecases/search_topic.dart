import '../../domain/entities/topic.dart';

class SearchTopic {
  List<(String id, Topic topic)> call(
      List<(String id, Topic topic)> src, {
        String keyword = '',
        String level = 'Tất cả',
        String language = 'Tất cả',
      }) {
    final k = keyword.trim().toLowerCase();
    final out = src.where((e) {
      final t = e.$2;
      final byKw = k.isEmpty || t.name.toLowerCase().contains(k) || t.description.toLowerCase().contains(k);
      final byLevel = level == 'Tất cả' || t.level == level;
      final byLang = language == 'Tất cả' || t.language == language;
      return byKw && byLevel && byLang;
    }).toList();
    out.sort((a, b) => b.$2.createdAt.compareTo(a.$2.createdAt));
    return out;
  }
}
