import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/bottom_nav.dart';
import '../../../../core/presentation/widgets/pagination_bar.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../../core/routing/app_routes.dart';
import '../../data/datasources/topic_remote_datasource.dart';
import '../../data/models/topic_model.dart';
import '../../data/repositories/topic_repository_impl.dart';
import '../../domain/entities/topic.dart';
import '../../domain/usecases/delete_topic.dart';
import '../../domain/usecases/get_topics_page.dart';
import '../../domain/usecases/search_topic.dart';
import '../widgets/topic_card.dart';
import 'topic_form_page.dart';

class TopicListPage extends StatefulWidget {
  const TopicListPage({super.key});
  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> {
  final levels = const ['Tất cả', 'Beginner', 'Intermediate', 'Advanced'];
  final langs = const ['Tất cả', 'EN', 'JP', 'FR', 'DE', 'ZH', 'KR', 'VI'];
  String selectedLevel = 'Tất cả';
  String selectedLanguage = 'Tất cả';
  String keyword = '';

  final repo = TopicRepositoryImpl(TopicRemoteDatasource());
  late final GetTopicsPage getPage;
  late final DeleteTopic deleteTopic;
  late final SearchTopic search;

  DocumentSnapshot? lastDoc;
  final List<DocumentSnapshot?> _pageStack = [null];
  int page = 1;
  List<(String, Topic)> _cache = [];

  @override
  void initState() {
    super.initState();
    getPage = GetTopicsPage(repo);
    deleteTopic = DeleteTopic(repo);
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

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá chủ đề?'),
        content: const Text('Thao tác không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await deleteTopic(id);
      _reload(reset: true);
    }
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
        title: const Text('Chủ đề'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const TopicFormPage()),
              );
              if (ok == true) _reload(reset: true);
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(selected: 1),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
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
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
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
                        decoration: const InputDecoration(
                          labelText: 'Ngôn ngữ',
                        ),
                        items: langs
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
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
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Không có chủ đề'))
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
                          onTap: () => context.push('/topics/detail/${m.id}'),
                          onEdit: () async {
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TopicFormPage(editing: (id, m)),
                              ),
                            );
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
