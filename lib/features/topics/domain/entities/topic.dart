class Topic {
  final String userId;
  final String name;
  final String description;
  final String level;    // Beginner | Intermediate | Advanced
  final String language; // EN | JP | ...
  final DateTime createdAt;
  final DateTime updatedAt;

  const Topic({
    required this.userId,
    required this.name,
    required this.description,
    required this.level,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });
}
