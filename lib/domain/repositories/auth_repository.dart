import 'dart:typed_data';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<bool> login(String studentNumber, String password, String captchaCode);
  Future<Uint8List?> fetchCaptchaImage();
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}
