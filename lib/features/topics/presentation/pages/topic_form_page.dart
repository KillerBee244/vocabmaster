import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../data/datasources/topic_remote_datasource.dart';
import '../../data/models/topic_model.dart';
import '../../data/repositories/topic_repository_impl.dart';
import '../../domain/entities/topic.dart';
import '../../domain/usecases/add_topic.dart';
import '../../domain/usecases/update_topic.dart';

class TopicFormPage extends StatefulWidget {
  final (String id, TopicModel model)? editing;
  const TopicFormPage({super.key, this.editing});

  @override
  State<TopicFormPage> createState() => _TopicFormPageState();
}

class _TopicFormPageState extends State<TopicFormPage> {
  final _f = GlobalKey<FormState>();
  final name = TextEditingController();
  final desc = TextEditingController();
  final levels = const ['Beginner','Intermediate','Advanced'];
  final langs = const ['EN','JP','FR','DE','ZH','KR','VI'];
  String level = 'Beginner';
  String language = 'EN';

  @override
  void initState() {
    super.initState();
    final e = widget.editing?.$2;
    if (e != null) {
      name.text = e.name; desc.text = e.description;
      level = e.level; language = e.language;
    }
  }

  @override
  void dispose() { name.dispose(); desc.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final repo = TopicRepositoryImpl(TopicRemoteDatasource());
    try {
      if (widget.editing == null) {
        final t = Topic(
            userId: uid, name: name.text.trim(), description: desc.text.trim(),
            level: level, language: language, createdAt: now, updatedAt: now);
        await AddTopic(repo)(t);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm chủ đề')));
      } else {
        final t = Topic(
            userId: widget.editing!.$2.userId, name: name.text.trim(),
            description: desc.text.trim(), level: level, language: language,
            createdAt: widget.editing!.$2.createdAt, updatedAt: now);
        await UpdateTopic(repo)(widget.editing!.$1, t);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu chủ đề')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return GradientScaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(isEdit ? 'Sửa chủ đề' : 'Thêm chủ đề')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _f,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Tên chủ đề'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: desc,
                        decoration: const InputDecoration(labelText: 'Mô tả'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: level,
                              items: levels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) => setState(() => level = v ?? level),
                              decoration: const InputDecoration(labelText: 'Độ khó'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: language,
                              items: langs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) => setState(() => language = v ?? language),
                              decoration: const InputDecoration(labelText: 'Ngôn ngữ'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.save),
                          label: Text(isEdit ? 'Lưu thay đổi' : 'Thêm chủ đề'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
