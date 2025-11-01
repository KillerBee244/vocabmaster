import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/bottom_nav.dart';
import '../../../../core/presentation/widgets/pagination_bar.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../topics/data/datasources/topic_remote_datasource.dart';
import '../../../topics/data/repositories/topic_repository_impl.dart';
import '../../../topics/domain/entities/topic.dart';
import '../../../topics/domain/usecases/get_topics_page.dart';
import '../../../topics/domain/usecases/search_topic.dart';

class PracticeListPage extends StatefulWidget {
  const PracticeListPage({super.key});
  @override
  State<PracticeListPage> createState() => _PracticeListPageState();
}

class _PracticeListPageState extends State<PracticeListPage> {
  final repo = TopicRepositoryImpl(TopicRemoteDatasource());
  late final GetTopicsPage getPage;
  late final SearchTopic search;

  DocumentSnapshot? lastDoc;
  final _stack = <DocumentSnapshot?>[null];
  int page = 1;
  String keyword = '';
  List<(String, Topic)> _cache = [];
  final Map<String, int> _wordCounts = {}; // 🔹 lưu số lượng từ từng chủ đề

  @override
  void initState() {
    super.initState();
    getPage = GetTopicsPage(repo);
    search = SearchTopic();
  }

  Future<void> _reload({bool reset = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (reset) {
      page = 1;
      _stack
        ..clear()
        ..add(null);
    }
    final res = await getPage(userId: uid, lastDoc: _stack[page - 1], limit: 6);
    lastDoc = res.lastDoc;
    _cache = res.items;
    setState(() {});
    _loadWordCounts(uid); // 🔹 tải số lượng từ song song
  }

  Future<void> _loadWordCounts(String uid) async {
    for (final (id, _) in _cache) {
      final countSnap = await FirebaseFirestore.instance
          .collection('words')
          .where('userId', isEqualTo: uid)
          .where('topicId', isEqualTo: id)
          .count()
          .get();
      _wordCounts[id] = countSnap.count ?? 0;
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = search(_cache, keyword: keyword).toList();

    return GradientScaffold(
      appBar: AppBar(title: const Text('Luyện tập')),
      bottomNavigationBar: const BottomNav(selected: 3),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm chủ đề'),
              onChanged: (v) => setState(() => keyword = v),
            ),
            const SizedBox(height: 12),
            PaginationBar(
              canPrev: page > 1,
              canNext: lastDoc != null,
              onPrev: () async {
                if (page > 1) {
                  page--;
                  await _reload();
                }
              },
              onNext: () async {
                if (lastDoc != null) {
                  _stack.add(lastDoc);
                  page++;
                  await _reload();
                }
              },
              page: page,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Không có chủ đề'))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final (id, t) = filtered[i];
                  final count = _wordCounts[id];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.category)),
                      title: Text(t.name),
                      subtitle: Text(
                        '${t.language} • ${t.level}${count != null ? '   |   ${count} từ vựng' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _chooseMode(context, id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Kiểm tra xem chủ đề có từ vựng nào không
  Future<bool> _hasWords(String userId, String topicId) async {
    final snap = await FirebaseFirestore.instance
        .collection('words')
        .where('userId', isEqualTo: userId)
        .where('topicId', isEqualTo: topicId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// 🔹 Chọn chế độ luyện tập (có kiểm tra dữ liệu)
  Future<void> _chooseMode(BuildContext context, String topicId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ kiểm tra có từ vựng trước
    final hasData = await _hasWords(uid, topicId);
    if (!hasData) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Chưa có từ vựng'),
          content: const Text(
              'Chủ đề này chưa có từ vựng. Vui lòng thêm từ vựng để có thể luyện tập.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final total = await _askTotal(context);
    if (total == null) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.flip),
              title: const Text('Flashcard'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                    '${AppRoutes.practiceFlashcard}?topicId=$topicId&total=$total');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Ghép thẻ'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                    '${AppRoutes.practiceMatching}?topicId=$topicId&total=$total');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Hộp chọn số lượng từ muốn học
  Future<int?> _askTotal(BuildContext context) async {
    final c = TextEditingController(text: '6');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn số từ muốn học'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số từ'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) return null;
    return int.tryParse(c.text.trim());
  }
}
