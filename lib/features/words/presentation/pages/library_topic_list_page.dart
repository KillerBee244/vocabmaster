import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/bottom_nav.dart';
import '../../../../core/presentation/widgets/pagination_bar.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../topics/data/datasources/topic_remote_datasource.dart';
import '../../../topics/data/models/topic_model.dart';
import '../../../topics/data/repositories/topic_repository_impl.dart';
import '../../../topics/domain/entities/topic.dart';
import '../../../topics/domain/usecases/get_topics_page.dart';
import '../../../topics/domain/usecases/search_topic.dart';
import '../../../topics/presentation/widgets/topic_card.dart';

class LibraryTopicListPage extends StatefulWidget {
  const LibraryTopicListPage({super.key});

  @override
  State<LibraryTopicListPage> createState() => _LibraryTopicListPageState();
}

class _LibraryTopicListPageState extends State<LibraryTopicListPage> {
  final levels = const ['Tất cả', 'Beginner', 'Intermediate', 'Advanced'];
  final langs = const ['Tất cả', 'EN', 'JP', 'FR', 'DE', 'ZH', 'KR', 'VI'];

  String selectedLevel = 'Tất cả';
  String selectedLanguage = 'Tất cả';
  String keyword = '';

  final repo = TopicRepositoryImpl(TopicRemoteDatasource());
  late final GetTopicsPage getPage;
  late final SearchTopic search;

  DocumentSnapshot? lastDoc;
  final List<DocumentSnapshot?> _pageStack = [null];
  int page = 1;

  List<(String, Topic)> _cache = [];

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
      _pageStack
        ..clear()
        ..add(null);
    }

    final res = await getPage(
      userId: uid,
      level: selectedLevel,
      language: selectedLanguage,
      lastDoc: _pageStack[page - 1],
      limit: 6,
    );

    lastDoc = res.lastDoc;
    _cache = res.items;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = search(
      _cache,
      keyword: keyword,
      level: selectedLevel,
      language: selectedLanguage,
    );

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Thư viện từ vựng'),
        centerTitle: true,
      ),
      bottomNavigationBar: const BottomNav(selected: 2),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            // 🔍 Thanh tìm kiếm và lọc
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HÀNG 1: Ô tìm kiếm
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Tìm theo tên / mô tả',
                        ),
                        onChanged: (v) => setState(() => keyword = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // HÀNG 2: 2 ô lọc (Độ khó + Ngôn ngữ)
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
                          setState(() {}); // đảm bảo UI cập nhật
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
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 📄 Phân trang
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
                  _pageStack.add(lastDoc);
                  page++;
                  await _reload();
                }
              },
              page: page,
            ),
            const SizedBox(height: 8),

            // 🧩 Danh sách chủ đề
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Không có chủ đề nào'))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final (id, t) = filtered[i];
                  final m = TopicModel(
                    id: id,
                    userId: t.userId,
                    name: t.name,
                    description: t.description,
                    level: t.level,
                    language: t.language,
                    createdAt: t.createdAt,
                    updatedAt: t.updatedAt,
                  );

                  return TopicCard(
                    topic: m,
                    showActions: false, // ❌ không có nút sửa/xoá ở Library
                    onTap: () {
                      // 👉 Chuyển sang danh sách từ vựng của chủ đề đó
                      context.push('${AppRoutes.libraryWords}?topicId=$id');
                    },
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
