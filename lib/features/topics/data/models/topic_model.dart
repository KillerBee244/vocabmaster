import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/topic.dart';

class TopicModel extends Topic {
  final String id;
  TopicModel({
    required this.id,
    required super.userId,
    required super.name,
    required super.description,
    required super.level,
    required super.language,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TopicModel.fromJson(String id, Map<String, dynamic> json) {
    DateTime _dt(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return TopicModel(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? 'Beginner',
      language: json['language'] ?? 'EN',
      createdAt: _dt(json['createdAt']),
      updatedAt: _dt(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'description': description,
    'level': level,
    'language': language,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
