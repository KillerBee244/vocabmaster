import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/bottom_nav.dart';
import '../../../../core/presentation/widgets/pagination_bar.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../topics/domain/entities/topic.dart';

class PracticeListPage extends StatefulWidget {
  const PracticeListPage({super.key});
  @override
  State<PracticeListPage> createState() => _PracticeListPageState();
}

class _PracticeListPageState extends State<PracticeListPage> {
  // Bộ lọc
  final levels = const ['Tất cả', 'Beginner', 'Intermediate', 'Advanced'];
  final langs = const ['Tất cả', 'EN', 'JP', 'FR', 'DE', 'ZH', 'KR', 'VI'];

  String selectedLevel = 'Tất cả';
  String selectedLanguage = 'Tất cả';
  String keyword = '';

  // Phân trang
  DocumentSnapshot? lastDoc;
  final _stack = <DocumentSnapshot?>[null];
  int page = 1;

  List<(String, Topic)> _cache = [];
  final Map<String, int> _wordCounts = {};

  @override
  void initState() {
    super.initState();
    _reload(reset: true);
  }

  // Helper: ép Timestamp/DateTime/String -> DateTime non-null
  DateTime _dt(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  Query<Map<String, dynamic>> _buildQuery(String uid, {DocumentSnapshot? cursor}) {
    var q = FirebaseFirestore.instance
        .collection('topics')
        .where('userId', isEqualTo: uid);

    if (selectedLevel != 'Tất cả') {
      q = q.where('level', isEqualTo: selectedLevel);
    }
    if (selectedLanguage != 'Tất cả') {
      q = q.where('language', isEqualTo: selectedLanguage);
    }

    q = q.orderBy('createdAt', descending: true);
    if (cursor != null) q = q.startAfterDocument(cursor);
    return q;
  }

  Future<void> _reload({bool reset = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (reset) {
      page = 1;
      _stack
        ..clear()
        ..add(null);
      lastDoc = null;
    }

    final q = _buildQuery(uid, cursor: _stack[page - 1]).limit(6);
    final snap = await q.get();

    _cache = snap.docs.map((d) {
      final m = d.data();
      final t = Topic(
        // ✅ thêm userId & ép kiểu ngày tháng non-null
        userId: (m['userId'] ?? uid) as String,
        name: (m['name'] ?? '') as String,
        language: (m['language'] ?? '') as String,
        level: (m['level'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        createdAt: _dt(m['createdAt']),
        updatedAt: _dt(m['updatedAt']),
      );
      return (d.id, t);
    }).toList();

    lastDoc = snap.docs.isEmpty ? null : snap.docs.last;

    setState(() {});
    _loadWordCounts(uid);
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
  Widget build(BuildContext context) {
    // Lọc keyword cục bộ
    final filtered = _cache
        .where((e) =>
    e.$2.name.toLowerCase().contains(keyword.toLowerCase()) ||
        (e.$2.description.toLowerCase()).contains(keyword.toLowerCase()))
        .toList();

    return GradientScaffold(
      appBar: AppBar(title: const Text('Luyện tập')),
      bottomNavigationBar: const BottomNav(selected: 3),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            // Search
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm chủ đề theo tên / mô tả',
              ),
              onChanged: (v) => setState(() => keyword = v),
            ),
            const SizedBox(height: 12),

            // Bộ lọc
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: const InputDecoration(labelText: 'Độ khó'),
                    items: levels
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) async {
                      selectedLevel = v ?? 'Tất cả';
                      await _reload(reset: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedLanguage,
                    decoration: const InputDecoration(labelText: 'Ngôn ngữ'),
                    items: langs
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) async {
                      selectedLanguage = v ?? 'Tất cả';
                      await _reload(reset: true);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Phân trang
            PaginationBar(
              canPrev: page > 1,
              canNext: lastDoc != null,
              onPrev: () async {
                if (page > 1) {
                  page--;
                  _stack.removeLast();
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

            // Danh sách
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
                      leading: const CircleAvatar(child: Icon(Icons.category)),
                      title: Text(t.name),
                      subtitle: Text(
                        '${t.language} • ${t.level}'
                            '${count != null ? '   |   ${count} từ vựng' : ''}',
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

  Future<bool> _hasWords(String userId, String topicId) async {
    final snap = await FirebaseFirestore.instance
        .collection('words')
        .where('userId', isEqualTo: userId)
        .where('topicId', isEqualTo: topicId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> _chooseMode(BuildContext context, String topicId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final hasData = await _hasWords(uid, topicId);
    if (!hasData) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Chưa có từ vựng'),
          content: const Text('Chủ đề này chưa có từ vựng. Vui lòng thêm từ để luyện tập.'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
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
                context.push('${AppRoutes.practiceFlashcard}?topicId=$topicId&total=$total');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Ghép thẻ'),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.practiceMatching}?topicId=$topicId&total=$total');
              },
            ),
          ],
        ),
      ),
    );
  }

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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    if (ok != true) return null;
    return int.tryParse(c.text.trim());
  }
}
