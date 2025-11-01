import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/word_model.dart';

class WordCard extends StatelessWidget {
  final WordModel word;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WordCard({super.key, required this.word, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: () => context.push('/words/detail/${word.id}'),
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: const Icon(Icons.translate),
        ),
        title: Text('${word.word}  •  ${word.pronunciation}'),
        subtitle: Text('${word.meaning}\n${word.example}', maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 6,
          children: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
