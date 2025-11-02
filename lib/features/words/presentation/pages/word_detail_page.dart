import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../data/datasources/word_remote_datasource.dart';
import '../../data/models/word_model.dart';
import '../../data/repositories/word_repository_impl.dart';
import '../../domain/usecases/delete_word.dart';
import '../../domain/usecases/get_word_by_id.dart';
import 'word_form_page.dart';

class WordDetailPage extends StatefulWidget {
  final String wordId;
  const WordDetailPage({super.key, required this.wordId});

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  final _repo = WordRepositoryImpl(WordRemoteDatasource());
  late final DeleteWord _deleteWord;
  late final GetWordById _getWord;

  WordModel? _model;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _deleteWord = DeleteWord(_repo);
    _getWord = GetWordById(_repo);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final w = await _getWord(widget.wordId);
      if (w == null) { setState(() { _error = 'Từ không tồn tại'; _loading = false; }); return; }
      setState(() {
        _model = WordModel(
          id: widget.wordId, userId: w.userId, topicId: w.topicId, word: w.word,
          meaning: w.meaning, example: w.example, imageUrl: w.imageUrl,
          pronunciation: w.pronunciation, audioUrl: w.audioUrl,
          createdAt: w.createdAt, updatedAt: w.updatedAt,
        );
        _loading = false;
      });
    } catch (e) { setState(() { _error = '$e'; _loading = false; }); }
  }

  Future<void> _onEdit() async {
    final m = _model; if (m == null) return;
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => WordFormPage(topicId: m.topicId, wordId: m.id)));
    if (ok == true) _load();
  }

  Future<void> _onDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá từ vựng?'),
        content: const Text('Thao tác không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _deleteWord(widget.wordId);
        if (!mounted) return;
        // ✅ Trả về true để trang trước hiển thị SnackBar + reload
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xoá: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;

    return GradientScaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Chi tiết từ vựng'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: m == null ? null : _onEdit),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: m == null ? null : _onDelete),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : m == null
          ? const Center(child: Text('Không có dữ liệu'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _Row(label: 'Từ vựng', value: m.word),
            _Row(label: 'Phát âm', value: m.pronunciation),
            _Row(label: 'Nghĩa', value: m.meaning),
            _Row(label: 'Ví dụ', value: m.example),
            _Row(label: 'Tạo lúc', value: m.createdAt.toString()),
            _Row(label: 'Cập nhật', value: m.updatedAt.toString()),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label; final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            SelectableText(value),
          ],
        ),
      ),
    );
  }
}
