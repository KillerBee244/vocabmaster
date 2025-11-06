import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/word.dart';

class WordModel extends Word {
  final String id;

  WordModel({
    required this.id,
    required super.userId,
    required super.topicId,
    required super.word,
    required super.meaning,
    required super.example,
    required super.imageUrl,
    required super.pronunciation,
    required super.audioUrl,
    required super.createdAt,
    required super.updatedAt,
    super.isStarred = false, // NEW
  });

  factory WordModel.fromJson(String id, Map<String, dynamic> json) {
    DateTime _dt(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return WordModel(
      id: id,
      userId: (json['userId'] ?? '').toString(),
      topicId: (json['topicId'] ?? '').toString(),
      word: (json['word'] ?? '').toString(),
      meaning: (json['meaning'] ?? '').toString(),
      example: (json['example'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
      audioUrl: (json['audioUrl'] ?? '').toString(),
      createdAt: _dt(json['createdAt']),
      updatedAt: _dt(json['updatedAt']),
      isStarred: (json['is_starred'] ?? false) == true, // NEW (mặc định false)
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'topicId': topicId,
    'word': word,
    'meaning': meaning,
    'example': example,
    'imageUrl': imageUrl,
    'pronunciation': pronunciation,
    'audioUrl': audioUrl,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'is_starred': isStarred, // NEW
  };

  // tiện cho UI
  WordModel copyWithModel({
    String? id,
    bool? isStarred,
    DateTime? updatedAt,
  }) {
    return WordModel(
      id: id ?? this.id,
      userId: userId,
      topicId: topicId,
      word: word,
      meaning: meaning,
      example: example,
      imageUrl: imageUrl,
      pronunciation: pronunciation,
      audioUrl: audioUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}
