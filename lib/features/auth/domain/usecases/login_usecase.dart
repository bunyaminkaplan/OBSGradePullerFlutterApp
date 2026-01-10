/// Login UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import '../repositories/auth_repository.dart';

/// Tek seferlik login işlemi için UseCase
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  /// Login işlemini gerçekleştir
  /// [studentNumber] öğrenci numarası
  /// [password] şifre
  /// [captchaCode] çözülmüş captcha kodu
  Future<bool> call(String studentNumber, String password, String captchaCode) {
    return _repository.login(studentNumber, password, captchaCode);
  }
}
