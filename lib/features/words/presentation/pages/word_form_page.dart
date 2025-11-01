import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../data/datasources/word_remote_datasource.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../../domain/entities/word.dart';
import '../../domain/usecases/add_word.dart';
import '../../domain/usecases/update_word.dart';
import '../../domain/usecases/get_word_by_id.dart';

class WordFormPage extends StatefulWidget {
  final String topicId;
  final String? wordId;
  const WordFormPage({super.key, required this.topicId, this.wordId});

  @override
  State<WordFormPage> createState() => _WordFormPageState();
}

class _WordFormPageState extends State<WordFormPage> {
  final _f = GlobalKey<FormState>();
  final word = TextEditingController();
  final meaning = TextEditingController();
  final example = TextEditingController();
  final pronunciation = TextEditingController();
  final audioUrl = TextEditingController();
  final imageUrl = TextEditingController();

  final repo = WordRepositoryImpl(WordRemoteDatasource());
  bool _loading = false;
  DateTime? _createdAtOriginal;
  String? _userIdOriginal;

  @override
  void initState() { super.initState(); _bootstrap(); }

  Future<void> _bootstrap() async {
    if (widget.wordId != null) {
      setState(() => _loading = true);
      try {
        final w = await GetWordById(repo)(widget.wordId!);
        if (w != null) {
          word.text = w.word; meaning.text = w.meaning; example.text = w.example;
          pronunciation.text = w.pronunciation; audioUrl.text = w.audioUrl; imageUrl.text = w.imageUrl;
          _createdAtOriginal = w.createdAt; _userIdOriginal = w.userId;
        }
      } finally { if (mounted) setState(() => _loading = false); }
    }
  }

  @override
  void dispose() {
    word.dispose(); meaning.dispose(); example.dispose();
    pronunciation.dispose(); audioUrl.dispose(); imageUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid; if (uid == null) return;
    final now = DateTime.now();

    try {
      if (widget.wordId == null) {
        final w = Word(
            userId: uid, topicId: widget.topicId, word: word.text.trim(),
            meaning: meaning.text.trim(), example: example.text.trim(),
            imageUrl: imageUrl.text.trim(), pronunciation: pronunciation.text.trim(),
            audioUrl: audioUrl.text.trim(), createdAt: now, updatedAt: now);
        await AddWord(repo)(w);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm từ')));
      } else {
        final w = Word(
            userId: _userIdOriginal ?? uid, topicId: widget.topicId, word: word.text.trim(),
            meaning: meaning.text.trim(), example: example.text.trim(), imageUrl: imageUrl.text.trim(),
            pronunciation: pronunciation.text.trim(), audioUrl: audioUrl.text.trim(),
            createdAt: _createdAtOriginal ?? now, updatedAt: now);
        await UpdateWord(repo)(widget.wordId!, w);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu từ')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.wordId != null;

    return GradientScaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(isEdit ? 'Sửa từ' : 'Thêm từ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _f,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextFormField(controller: word, decoration: const InputDecoration(labelText: 'Từ vựng'),
                        validator: (v) => v==null||v.trim().isEmpty ? 'Nhập từ' : null),
                    const SizedBox(height: 8),
                    TextFormField(controller: meaning, decoration: const InputDecoration(labelText: 'Nghĩa'),
                        validator: (v) => v==null||v.trim().isEmpty ? 'Nhập nghĩa' : null),
                    const SizedBox(height: 8),
                    TextFormField(controller: pronunciation, decoration: const InputDecoration(labelText: 'Phát âm')),
                    const SizedBox(height: 8),
                    TextFormField(controller: example, decoration: const InputDecoration(labelText: 'Ví dụ'), maxLines: 2),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save),
                        label: Text(isEdit ? 'Lưu' : 'Thêm'),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
