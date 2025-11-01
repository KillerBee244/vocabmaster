import '../../domain/entities/session.dart';

class StartSession {
  Future<void> call({required String userId, required String topicId, required String mode, required int totalWords}) async {
    // Bạn có thể tạo doc sessions ngay khi bắt đầu (optional)
  }
}
