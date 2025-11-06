import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../data/datasources/topic_remote_datasource.dart';
import '../../data/models/topic_model.dart';
import '../../data/repositories/topic_repository_impl.dart';
import '../../domain/usecases/delete_topic.dart';
import 'topic_form_page.dart';

class TopicDetailPage extends StatefulWidget {
  final String topicId;
  const TopicDetailPage({super.key, required this.topicId});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  final _remote = TopicRemoteDatasource();
  late final DeleteTopic _deleteTopic;

  TopicModel? _model;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _deleteTopic = DeleteTopic(TopicRepositoryImpl(_remote));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snap = await _remote.getById(widget.topicId);
      if (!snap.exists) {
        setState(() { _error = 'Chủ đề không tồn tại'; _loading = false; });
        return;
      }
      final m = TopicModel.fromJson(snap.id, snap.data()!);
      setState(() { _model = m; _loading = false; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _onEdit() async {
    final t = _model; if (t == null) return;
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => TopicFormPage(editing: (t.id, t))));
    if (ok == true) _load();
  }

  Future<void> _onDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá chủ đề?'),
        content: const Text('Thao tác không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteTopic(widget.topicId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;

    return GradientScaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Chi tiết chủ đề'),
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
            _Row(label: 'Tên chủ đề', value: m.name),
            _Row(label: 'Mô tả', value: m.description),
            _Row(label: 'Ngôn ngữ', value: m.language),
            _Row(label: 'Độ khó', value: m.level),
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
