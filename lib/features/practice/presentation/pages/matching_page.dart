import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../words/data/models/word_model.dart';
import '../../domain/usecases/finish_session.dart';
import '../../domain/usecases/get_random_words.dart';

class _CardItem {
  final String text;
  final int pairId;   // cùng pairId là một cặp
  final bool isWord;  // true = từ, false = nghĩa
  bool removed;       // đã ghép đúng → biến mất
  _CardItem({
    required this.text,
    required this.pairId,
    required this.isWord,
    this.removed = false,
  });
}

class MatchingPage extends StatefulWidget {
  final String topicId;
  final int total;
  const MatchingPage({super.key, required this.topicId, required this.total});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  late final Stopwatch sw;
  Timer? _tick;

  List<_CardItem> cards = [];
  int? first;               // index thẻ được chọn đầu tiên
  int mistakes = 0;

  @override
  void initState() {
    super.initState();
    sw = Stopwatch()..start();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final list = await GetRandomWords()(userId: uid, topicId: widget.topicId, total: widget.total);

    final tmp = <_CardItem>[];
    for (var i = 0; i < list.length; i++) {
      final w = list[i];
      tmp.add(_CardItem(text: w.word,    pairId: i, isWord: true));
      tmp.add(_CardItem(text: w.meaning, pairId: i, isWord: false));
    }
    tmp.shuffle();
    setState(() => cards = tmp);
  }

  @override
  void dispose() {
    _tick?.cancel();
    sw.stop();
    super.dispose();
  }

  bool _isPair(int a, int b) {
    final ca = cards[a];
    final cb = cards[b];
    return ca.pairId == cb.pairId && ca.isWord != cb.isWord;
  }

  Future<void> _finish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FinishSession()(
        userId: uid,
        topicId: widget.topicId,
        mode: 'matching',
        totalWords: cards.length ~/ 2,
        timeSpent: sw.elapsed.inSeconds,
      );
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DoneSheet(
        secs: sw.elapsed.inSeconds,
        mistakes: mistakes,
        onReplay: () { Navigator.pop(context); Navigator.pop(context); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secs = sw.elapsed.inSeconds;
    final done = cards.every((e) => e.removed);

    // responsive: 3 cột dọc, 4 cột ngang
    final cross = MediaQuery.of(context).size.width > 520 ? 4 : 3;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: Text('$secs giây'),
        actions: [
          IconButton(icon: const Icon(Icons.volume_up_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black12),
        ),
      ),
      body: cards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 3/4,
                ),
                itemCount: cards.length,
                itemBuilder: (_, i) {
                  final c = cards[i];
                  if (c.removed) return const SizedBox.shrink();

                  final selected = first == i;

                  return _Tile(
                    text: c.text,
                    selected: selected,
                    onTap: done ? null : () async {
                      if (first == null) {
                        setState(() => first = i);
                        return;
                      }
                      if (first == i) {
                        setState(() => first = null);
                        return;
                      }

                      final prev = first!;
                      setState(() => first = null);

                      if (_isPair(prev, i)) {
                        setState(() {
                          cards[prev].removed = true;
                          cards[i].removed = true;
                        });
                        if (cards.every((e) => e.removed)) {
                          await _finish();
                        }
                      } else {
                        mistakes++;
                        // flash đỏ nhanh
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sai cặp! Hãy thử lại'), duration: Duration(milliseconds: 500)),
                        );
                      }
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

class _Tile extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _Tile({required this.text, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg = selected ? Colors.blueGrey.shade200 : cs.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ),
    );
  }
}

class _DoneSheet extends StatelessWidget {
  final int secs;
  final int mistakes;
  final VoidCallback onReplay;
  const _DoneSheet({required this.secs, required this.mistakes, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 48),
            const SizedBox(height: 8),
            const Text('Chúc mừng! Bạn đã hoàn thành', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$secs giây • Lỗi: $mistakes', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onReplay,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: const StadiumBorder()),
              child: const Text('Chơi lại'),
            ),
          ],
        ),
      ),
    );
  }
}
