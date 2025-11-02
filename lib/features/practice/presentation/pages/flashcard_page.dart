// lib/features/practice/presentation/pages/flashcard_page.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../words/data/models/word_model.dart';
import '../../domain/usecases/finish_session.dart';
import '../../domain/usecases/get_random_words.dart';
import '../widgets/flip_card.dart';

class FlashcardPage extends StatefulWidget {
  final String topicId;
  final int total;
  const FlashcardPage({super.key, required this.topicId, required this.total});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  final PageController _pc = PageController();
  List<WordModel> words = [];

  int known = 0;
  int learning = 0;
  late final Stopwatch sw;
  Timer? _tick;

  final Set<int> _knownIndex = {};

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
    final list = await GetRandomWords()(
      userId: uid,
      topicId: widget.topicId,
      total: widget.total,
    );
    setState(() {
      words = list;
      learning = list.length;
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    sw.stop();
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FinishSession()(
        userId: uid,
        topicId: widget.topicId,
        mode: 'flashcard',
        totalWords: words.length,
        timeSpent: sw.elapsed.inSeconds,
      );
    }
    if (!mounted) return;

    final k = known;
    final l = learning;
    final t = words.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FinishSheet(
        seconds: sw.elapsed.inSeconds,
        known: k,
        learning: l,
        total: t,
        onPlayAgain: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  // 🔹 Toggle “yêu thích” (is_starred)
  Future<void> _toggleStar(WordModel w, int index) async {
    final newVal = !w.isStarred;

    // cập nhật UI trước
    setState(() {
      words[index] = w.copyWithModel(
        isStarred: newVal,
        updatedAt: DateTime.now(),
      );
    });

    try {
      await FirebaseFirestore.instance.collection('words').doc(w.id).update({
        'is_starred': newVal,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // rollback nếu lỗi
      if (mounted) {
        setState(() {
          words[index] = w;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật dấu sao: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int idx = (_pc.hasClients && _pc.positions.isNotEmpty)
        ? (_pc.page?.round() ?? 0)
        : 0;
    final total = words.length;
    final secs = sw.elapsed.inSeconds;

    final String titleText = total == 0
        ? '0 / 0'
        : '${(idx + 1).clamp(1, total)} / $total';
    final double? progress = total == 0 ? null : (idx + 1) / total;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(titleText),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F3FF), // Tím nhạt
              Color(0xFFF0EFFF), // Tím → xanh nhạt
            ],
          ),
        ),
        child: total == 0
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Badge thống kê
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _Pill(text: '$learning', color: Colors.orange.shade200),
                        const Spacer(),
                        Text(
                          '${secs}s',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        _Pill(text: '$known', color: Colors.green.shade200),
                      ],
                    ),
                  ),

                  // ==== Thẻ flashcard + nút sao ====
                  Expanded(
                    child: PageView.builder(
                      controller: _pc,
                      physics: const BouncingScrollPhysics(),
                      itemCount: words.length,
                      itemBuilder: (_, i) {
                        final w = words[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Stack(
                                children: [
                                  // FlipCard
                                  Positioned.fill(
                                    child: FlipCard(
                                      key: ValueKey(w.id),
                                      front: w.word,
                                      back:
                                          '${w.pronunciation.isNotEmpty ? '${w.pronunciation} - ' : ''}${w.meaning}\n${w.example}',
                                      duration: const Duration(
                                        milliseconds: 480,
                                      ),
                                      curve: Curves.easeInOutCubicEmphasized,
                                      elevation: 10,
                                    ),
                                  ),
                                  // Icon sao góc phải
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: () => _toggleStar(w, i),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          w.isStarred
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          color: w.isStarred
                                              ? Colors.amber
                                              : Colors.grey.withOpacity(0.4),
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Hướng dẫn nhỏ
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Chạm vào thẻ để lật',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Điều hướng
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () {
                            final i = (_pc.page?.round() ?? 0);
                            if (!_knownIndex.contains(i)) {
                              setState(() {
                                _knownIndex.add(i);
                                if (learning > 0) learning--;
                                known++;
                              });
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () {
                            final prev = (_pc.page?.round() ?? 0) - 1;
                            if (prev >= 0) {
                              _pc.animateToPage(
                                prev,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            final next = (_pc.page?.round() ?? 0) + 1;
                            if (next < total) {
                              _pc.animateToPage(
                                next,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            } else {
                              _finish();
                            }
                          },
                          icon: Icon(
                            (idx + 1) < total
                                ? Icons.arrow_forward
                                : Icons.check,
                          ),
                          label: Text(
                            (idx + 1) < total ? 'Tiếp' : 'Hoàn thành',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}

class _FinishSheet extends StatelessWidget {
  final int seconds;
  final int known;
  final int learning;
  final int total;
  final VoidCallback onPlayAgain;

  const _FinishSheet({
    required this.seconds,
    required this.known,
    required this.learning,
    required this.total,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : known / total;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiến độ của bạn',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Vòng tròn tiến độ + 2 pill
            Row(
              children: [
                // Donut progress
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 30,
                        backgroundColor: Colors.orange.shade100,
                        color: Colors.orange,
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Biết / Đang học
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pillStat('Biết', known, const Color(0xFFCFF9E5)),
                      const SizedBox(height: 10),
                      _pillStat('Đang học', learning, const Color(0xFFFFECD8)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'Thời gian hoàn thành: $seconds giây',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),
            FilledButton(
              onPressed: onPlayAgain,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              child: const Text('Chơi lại'),
            ),
          ],
        ),
      ),
    );
  }

  // pill “Biết / Đang học”
  Widget _pillStat(String label, int value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
