import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final int page;

  const PaginationBar({
    super.key,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: canPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Trước'),
        ),
        const SizedBox(width: 12),
        Text('Trang $page', style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        FilledButton.tonalIcon(
          onPressed: canNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Sau'),
        ),
      ],
    );
  }
}
