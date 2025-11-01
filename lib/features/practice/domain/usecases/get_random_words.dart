import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../words/data/models/word_model.dart';

class GetRandomWords {
  final _db = FirebaseFirestore.instance;
  Future<List<WordModel>> call({required String userId, required String topicId, required int total}) async {
    final snap = await _db.collection('words')
        .where('userId', isEqualTo: userId)
        .where('topicId', isEqualTo: topicId)
        .limit(100) // lấy trước 100 -> shuffle -> take total
        .get();
    final list = snap.docs.map((d) => WordModel.fromJson(d.id, d.data())).toList();
    list.shuffle();
    return list.take(total).toList();
  }
}
