/// Get Captcha UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import 'dart:typed_data';
import '../repositories/auth_repository.dart';

/// Captcha görselini çekme işlemi için UseCase
class GetCaptchaUseCase {
  final AuthRepository _repository;

  const GetCaptchaUseCase(this._repository);

  /// Captcha görselini çek
  /// Başarılı ise image bytes döner
  Future<Uint8List?> call() {
    return _repository.fetchCaptchaImage();
  }
}
