class Session {
  final String userId;
  final String topicId;
  final String mode;      // flashcard | matching
  final int totalWords;
  final int timeSpent;    // giây
  final double score;     // tuỳ chọn
  final DateTime completedAt;

  const Session({
    required this.userId,
    required this.topicId,
    required this.mode,
    required this.totalWords,
    required this.timeSpent,
    required this.score,
    required this.completedAt,
  });
}
