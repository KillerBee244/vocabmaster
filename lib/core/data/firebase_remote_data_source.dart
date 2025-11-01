import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRemoteDataSource {
  final FirebaseFirestore firestore;
  FirebaseRemoteDataSource({FirebaseFirestore? instance})
      : firestore = instance ?? FirebaseFirestore.instance;

  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    final ref = await firestore.collection(collection).add(data);
    return ref.id;
  }

  Future<void> updateDocument(String collection, String id, Map<String, dynamic> data) {
    return firestore.collection(collection).doc(id).update(data);
  }

  Future<void> deleteDocument(String collection, String id) {
    return firestore.collection(collection).doc(id).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getById(String collection, String id) {
    return firestore.collection(collection).doc(id).get();
  }
}
