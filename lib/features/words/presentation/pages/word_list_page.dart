// chỉ đổi Scaffold -> GradientScaffold + padding + AppBar đẹp hơn
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/pagination_bar.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../data/datasources/word_remote_datasource.dart';
import '../../data/models/word_model.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../../domain/entities/word.dart';
import '../../domain/usecases/delete_word.dart';
import '../../domain/usecases/get_words_page.dart';
import '../../domain/usecases/search_word.dart';
import '../widgets/word_card.dart';
import 'word_form_page.dart';

class WordListPage extends StatefulWidget {
  final String topicId;
  const WordListPage({super.key, required this.topicId});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  final repo = WordRepositoryImpl(WordRemoteDatasource());
  late final GetWordsPage getPage;
  late final DeleteWord deleteWord;
  late final SearchWord search;

  DocumentSnapshot? lastDoc;
  final _stack = <DocumentSnapshot?>[null];
  int page = 1;

  String keyword = '';
  List<(String, Word)> _cache = [];

  @override
  void initState() {
    super.initState();
    getPage = GetWordsPage(repo);
    deleteWord = DeleteWord(repo);
    search = SearchWord();
  }

  Future<void> _reload({bool reset = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (reset) { page = 1; _stack..clear()..add(null); }
    final res = await getPage(
      userId: uid, topicId: widget.topicId,
      lastDoc: _stack[page - 1], limit: 6,
    );
    lastDoc = res.lastDoc; _cache = res.items; setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload(reset: true);
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá từ?'),
        content: const Text('Thao tác không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok == true) { await deleteWord(id); _reload(reset: true); }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = search(_cache, keyword: keyword);

    return GradientScaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Từ vựng theo chủ đề'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                  context, MaterialPageRoute(builder: (_) => WordFormPage(topicId: widget.topicId)));
              if (ok == true) _reload(reset: true);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Tìm theo từ / nghĩa'),
              onChanged: (v) => setState(() => keyword = v),
            ),
            const SizedBox(height: 12),
            PaginationBar(
              canPrev: page > 1,
              canNext: lastDoc != null,
              onPrev: () async { if (page > 1){ page--; await _reload(); } },
              onNext: () async { if (lastDoc != null){ _stack.add(lastDoc); page++; await _reload(); } },
              page: page,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Chưa có từ'))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final (id, w) = filtered[i];
                  final m = WordModel(
                    id: id, userId: w.userId, topicId: w.topicId, word: w.word,
                    meaning: w.meaning, example: w.example, imageUrl: w.imageUrl,
                    pronunciation: w.pronunciation, audioUrl: w.audioUrl,
                    createdAt: w.createdAt, updatedAt: w.updatedAt,
                  );
                  return WordCard(
                    word: m,
                    onEdit: () async {
                      final ok = await Navigator.push<bool>(
                          context, MaterialPageRoute(builder: (_) => WordFormPage(topicId: w.topicId, wordId: id)));
                      if (ok == true) _reload(reset: true);
                    },
                    onDelete: () => _confirmDelete(id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
