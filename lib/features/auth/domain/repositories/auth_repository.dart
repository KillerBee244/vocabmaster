import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> signup(String email, String password);
  Future<void> logout();
  UserEntity? getCurrentUser();
}
