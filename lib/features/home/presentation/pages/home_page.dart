import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/app_drawer.dart';
import '../../../../core/presentation/widgets/bottom_nav.dart';
import '../../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../../core/routing/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ======== Đếm thống kê tổng ========
  Future<int> _count(String col, String uid) async {
    final q = await FirebaseFirestore.instance
        .collection(col)
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    return q.count ?? 0; // fix nullable
  }

  // ======== DỮ LIỆU 2: Top 5 nhanh nhất ========
  Future<List<_FastSession>> _fetchFastest(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('sessions')
        .where('userId', isEqualTo: uid)
        .orderBy('timeSpent')
        .limit(5)
        .get();

    return snap.docs.map((d) {
      final m = d.data();
      return _FastSession(
        timeSpent: (m['timeSpent'] ?? 0) as int,
        mode: (m['mode'] ?? '').toString(),
        createdAt: (m['completedAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return GradientScaffold(
      appBar: AppBar(title: const Text('VocabMaster')),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomNav(selected: 0),
      body: uid == null
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: ListView(
          children: [
            // ====== Khối thống kê nhanh ======
            FutureBuilder(
              future: Future.wait<int>([
                _count('topics', uid),
                _count('words', uid),
                _count('sessions', uid),
              ]),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final [topics, words, sessions] = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Thống kê của bạn',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _StatCard(
                                label: 'Chủ đề',
                                value: topics,
                                icon: Icons.category)),
                        Expanded(
                            child: _StatCard(
                                label: 'Từ vựng',
                                value: words,
                                icon: Icons.translate)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'Buổi luyện',
                            value: sessions,
                            icon: Icons.school)),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Text('Bắt đầu nhanh',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.flash_on)),
                        title: const Text('Tiếp tục học'),
                        subtitle: const Text(
                            'Vào phần Luyện tập để bắt đầu ngay'),
                        trailing: FilledButton(
                            onPressed: () => context.push(AppRoutes.practice),
                            child: const Text('Bắt đầu')),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.star)),
                title: const Text('Từ đã đánh dấu'),
                subtitle: const Text('Xem và quản lý các từ bạn đánh dấu'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.starred),
              ),
            ),
            const SizedBox(height: 24),
            // ====== Biểu đồ tần suất luyện tập theo tuần ======
            Row(
              children: [
                Text(
                  'Tần suất luyện tập ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.trending_up,
                  size: 28,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _WeeklySection(uid: uid),

            const SizedBox(height: 24),

            // ====== Top 5 nhanh nhất ======
            Row(
              children: [
                Text(
                  'Kỷ lục',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.emoji_events,
                  size: 28,
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<_FastSession>>(
              future: _fetchFastest(uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child:
                      Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('Chưa có dữ liệu'),
                    ),
                  );
                }
                return Card(
                  child: Column(
                    children: [
                      const ListTile(
                        dense: true,
                        title: Text('Thời gian hoàn thành'),
                        trailing: Text('Loại'),
                      ),
                      const Divider(height: 1),
                      ...items.map((e) => ListTile(
                        leading:
                        const Icon(Icons.timer_outlined),
                        title: Text('${e.timeSpent}s'),
                        subtitle: e.createdAt == null
                            ? null
                            : Text(
                          _fmtDate(e.createdAt!),
                          style:
                          const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          e.mode,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      )),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm, $hh:$mi';
  }
}

// ==================== WIDGETS PHỤ ====================

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('$value',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FastSession {
  final int timeSpent;
  final String mode;
  final DateTime? createdAt;
  _FastSession({required this.timeSpent, required this.mode, this.createdAt});
}

// ==================== CHỌN TUẦN & BIỂU ĐỒ ====================

class _WeeklySection extends StatefulWidget {
  final String uid;
  const _WeeklySection({required this.uid});
  @override
  State<_WeeklySection> createState() => _WeeklySectionState();
}

class _WeeklySectionState extends State<_WeeklySection> {
  late DateTime weekStart; // Monday của tuần hiện tại
  late Future<List<int>> future;

  @override
  void initState() {
    super.initState();
    weekStart = _mondayOf(DateTime.now());
    future = _fetchWeeklyCountsByWeek(widget.uid, weekStart);
  }

  void _reload() {
    // không dùng async trong setState
    final f = _fetchWeeklyCountsByWeek(widget.uid, weekStart);
    setState(() {
      future = f;
    });
  }

  void _prevWeek() {
    weekStart = weekStart.subtract(const Duration(days: 7));
    _reload();
  }

  void _nextWeek() {
    final next = weekStart.add(const Duration(days: 7));
    if (next.isAfter(_mondayOf(DateTime.now()))) return;
    weekStart = next;
    _reload();
  }


  Future<void> _pickAnyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: weekStart,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      weekStart = _mondayOf(picked);
      _reload();
    }
  }

  String _weekLabel() {
    final end = weekStart.add(const Duration(days: 6));
    String ddmm(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '${ddmm(weekStart)} – ${ddmm(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: _prevWeek,
                    icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(_weekLabel(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                    onPressed: _nextWeek,
                    icon: const Icon(Icons.chevron_right)),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickAnyDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Chọn ngày'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<int>>(
              future: future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return SizedBox(
                  height: 220,
                  child: _WeeklyBarChart(
                    data: snap.data!,
                    start: weekStart,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== XỬ LÝ TUẦN & BIỂU ĐỒ ====================

DateTime _mondayOf(DateTime d) {
  final base = DateTime(d.year, d.month, d.day);
  final delta = (base.weekday - DateTime.monday) % 7;
  return base.subtract(Duration(days: delta));
}

Future<List<int>> _fetchWeeklyCountsByWeek(String uid, DateTime weekStart) async {
  final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final end = start.add(const Duration(days: 7));
  final startTs = Timestamp.fromDate(start);
  final endTs = Timestamp.fromDate(end);

  final snap = await FirebaseFirestore.instance
      .collection('sessions')
      .where('userId', isEqualTo: uid)
      .where('completedAt', isGreaterThanOrEqualTo: startTs)
      .where('completedAt', isLessThan: endTs)
      .get();

  final counts = List<int>.filled(7, 0);
  for (final doc in snap.docs) {
    final ts = doc.data()['completedAt'] as Timestamp?;
    if (ts == null) continue;
    final d = ts.toDate();
    final diff = d.difference(start).inDays;
    if (diff >= 0 && diff < 7) counts[diff]++;
  }
  return counts;
}

class _WeeklyBarChart extends StatelessWidget {
  final List<int> data;
  final DateTime start;
  const _WeeklyBarChart({required this.data, required this.start});

  List<String> _labels() {
    return List.generate(7, (i) {
      final d = start.add(Duration(days: i));
      switch (d.weekday) {
        case DateTime.monday:
          return 'M';
        case DateTime.tuesday:
          return 'T';
        case DateTime.wednesday:
          return 'W';
        case DateTime.thursday:
          return 'Th';
        case DateTime.friday:
          return 'F';
        case DateTime.saturday:
          return 'S';
        default:
          return 'Su';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels();
    final maxY = (data.isEmpty
        ? 1
        : (data.reduce((a, b) => a > b ? a : b)).toDouble())
        .clamp(1, double.infinity);

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (maxY / 3).ceilToDouble().clamp(1, 1000),
              getTitlesWidget: (v, _) =>
                  Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child:
                  Text(labels[i], style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          data.length,
              (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].toDouble(),
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
