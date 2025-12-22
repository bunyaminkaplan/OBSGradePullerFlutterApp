import 'dart:typed_data';
import '../repositories/auth_repository.dart';
import '../services/captcha_service_interface.dart';
import '../../core/services/logger_service.dart';

class AutoLoginUseCase {
  final AuthRepository _repository;
  final ICaptchaService _captchaService;
  final LoggerService _logger; // Logger eklendi

  AutoLoginUseCase(
    this._repository,
    this._captchaService, [
    LoggerService? logger,
  ]) : _logger = logger ?? LoggerService();

  Future<bool> execute(String studentNumber, String password) async {
    const int maxRetries = 5;

    for (int i = 0; i < maxRetries; i++) {
      try {
        if (i > 0) {
          // Delay before retry
          await Future.delayed(const Duration(milliseconds: 1000));
        }

        _logger.info(
          "AutoLogin: Attempt ${i + 1}/$maxRetries for $studentNumber",
        );

        // 1. Fetch Captcha
        Uint8List? captchaImage = await _repository.fetchCaptchaImage();
        if (captchaImage == null) {
          _logger.warning("AutoLogin: Captcha fetch returned null");
          continue;
        }

        // 2. Solve Captcha
        String? captchaCode = await _captchaService.solveCaptcha(captchaImage);
        if (captchaCode == null) {
          _logger.warning("AutoLogin: AI failed to solve captcha");
          continue;
        }

        // 3. Login
        _logger.info("AutoLogin: Trying with code $captchaCode");
        bool success = await _repository.login(
          studentNumber,
          password,
          captchaCode,
        );

        if (success) {
          return true;
        }

        // If login returned false (e.g. wrong captcha logic on server side despite 200 OK), retry.
      } catch (e) {
        _logger.error("AutoLogin: Error on attempt ${i + 1}: $e", error: e);
        // If ServerException, we might want to retry?
        if (i == maxRetries - 1) {
          // Last attempt failed with exception
          rethrow;
          // Or just return false?
          // If we rethrow, the UI can show the specific error of the last attempt.
        }
      }
    }

    return false;
  }
}
