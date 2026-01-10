/// Auto Login UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import 'dart:typed_data';
import '../repositories/auth_repository.dart';
import '../../../../core/utils/logger.dart';
import '../../../captcha/domain/services/captcha_solver.dart';

/// Otomatik login işlemi için UseCase
/// Captcha çözme ve retry mantığını içerir
class AutoLoginUseCase {
  final AuthRepository _repository;
  final CaptchaSolver _captchaSolver;
  final Logger _logger;

  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(milliseconds: 1000);

  AutoLoginUseCase(this._repository, this._captchaSolver, [Logger? logger])
    : _logger = logger ?? const Logger(tag: 'AutoLogin');

  /// Otomatik login işlemini gerçekleştir
  /// [studentNumber] öğrenci numarası
  /// [password] şifre
  /// Başarılı ise true, aksi halde false döner
  Future<bool> call(String studentNumber, String password) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          await Future.delayed(_retryDelay);
        }

        _logger.info('Deneme $attempt/$_maxRetries ($studentNumber)');

        // 1. Captcha'yı çek
        final Uint8List? captchaImage = await _repository.fetchCaptchaImage();
        if (captchaImage == null) {
          _logger.warning('Captcha çekilemedi');
          continue;
        }

        // 2. Captcha'yı çöz
        final String? captchaCode = await _captchaSolver.solve(captchaImage);
        if (captchaCode == null) {
          _logger.warning('Captcha çözülemedi');
          continue;
        }

        // 3. Login dene
        _logger.info('Kod: $captchaCode ile deneniyor');
        final bool success = await _repository.login(
          studentNumber,
          password,
          captchaCode,
        );

        if (success) {
          _logger.info('Giriş başarılı!');
          return true;
        }

        _logger.warning('Giriş başarısız, yeniden deneniyor...');
      } catch (e) {
        _logger.error('Deneme $attempt hatası: $e', error: e);

        if (attempt == _maxRetries) {
          rethrow;
        }
      }
    }

    return false;
  }
}
