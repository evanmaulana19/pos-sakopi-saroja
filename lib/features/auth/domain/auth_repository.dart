import 'user_profile_model.dart';

abstract class AuthRepository {
  Future<UserProfile> login(String email, String password);
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<UserProfile?> getCurrentUser();
}
