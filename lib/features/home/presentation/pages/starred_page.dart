// lib/features/home/presentation/pages/starred_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StarredPage extends StatelessWidget {
  const StarredPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _starredStream(String uid) {
    return FirebaseFirestore.instance
        .collection('words')
        .where('userId', isEqualTo: uid)
        .where('is_starred', isEqualTo: true)
        // .orderBy('updatedAt', descending: true) // nếu muốn sắp xếp, bật và tạo index khi Firestore yêu cầu
        .snapshots();
  }

  Future<void> _unstarDoc(String id) async {
    await FirebaseFirestore.instance.collection('words').doc(id).update({
      'is_starred': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> _confirmUnstar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ đánh dấu?'),
        content: const Text('Bạn có chắc chắn muốn bỏ đánh dấu từ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _openDetailDialog(
    BuildContext context, {
    required Map<String, dynamic> m,
    required String id,
  }) async {
    await showDialog(
      context: context,
      builder: (_) {
        final word = (m['word'] ?? '').toString();
        final pro = (m['pronunciation'] ?? '').toString();
        final mean = (m['meaning'] ?? '').toString();
        final ex = (m['example'] ?? '').toString();

        return AlertDialog(
          title: Text(
            word,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pro.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        pro,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  if (mean.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(mean, style: const TextStyle(fontSize: 16)),
                    ),
                  if (ex.isNotEmpty)
                    Text(
                      ex,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.star_outline),
              label: const Text('Huỷ đánh dấu'),
              onPressed: () async {
                // confirm lần nữa
                final ok = await _confirmUnstar(context);
                if (!ok) return;
                await _unstarDoc(id);
                if (context.mounted) {
                  Navigator.pop(context); // đóng dialog chi tiết
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã bỏ đánh dấu')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      // ÁP GRADIENT TÍM Ở ĐÂY
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
      child: Scaffold(
        appBar: AppBar(title: const Text('Từ vựng đã đánh dấu')),

        body: uid == null
            ? const Center(child: Text('Vui lòng đăng nhập'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _starredStream(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Lỗi: ${snap.error}'));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Chưa có từ nào được đánh dấu'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final m = d.data();
                      final title = (m['word'] ?? '').toString();
                      final subtitle = [
                        if ((m['pronunciation'] ?? '').toString().isNotEmpty)
                          m['pronunciation'],
                        if ((m['meaning'] ?? '').toString().isNotEmpty)
                          m['meaning'],
                      ].join(' • ');

                      return Card(
                        clipBehavior:
                            Clip.antiAlias, // Cắt nội dung theo border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.translate),
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () =>
                              _openDetailDialog(context, m: m, id: d.id),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
