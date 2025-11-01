class Word {
  final String userId;
  final String topicId;
  final String word;
  final String meaning;
  final String example;
  final String imageUrl;
  final String pronunciation;
  final String audioUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // NEW
  final bool isStarred;

  const Word({
    required this.userId,
    required this.topicId,
    required this.word,
    required this.meaning,
    required this.example,
    required this.imageUrl,
    required this.pronunciation,
    required this.audioUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isStarred = false, // default
  });

  Word copyWith({
    String? userId,
    String? topicId,
    String? word,
    String? meaning,
    String? example,
    String? imageUrl,
    String? pronunciation,
    String? audioUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStarred,
  }) {
    return Word(
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      imageUrl: imageUrl ?? this.imageUrl,
      pronunciation: pronunciation ?? this.pronunciation,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}
