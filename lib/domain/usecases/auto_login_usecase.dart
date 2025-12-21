import 'dart:typed_data';
import '../repositories/auth_repository.dart';
import '../services/captcha_service_interface.dart';

class AutoLoginUseCase {
  final AuthRepository _repository;
  final ICaptchaService _captchaService;

  AutoLoginUseCase(this._repository, this._captchaService);

  Future<bool> execute(String studentNumber, String password) async {
    const int maxRetries = 5;

    for (int i = 0; i < maxRetries; i++) {
      try {
        if (i > 0) {
          // Delay before retry
          await Future.delayed(const Duration(milliseconds: 1000));
        }

        print("AutoLogin: Attempt ${i + 1}/$maxRetries for $studentNumber");

        // 1. Fetch Captcha
        Uint8List? captchaImage = await _repository.fetchCaptchaImage();
        if (captchaImage == null) {
          print("AutoLogin: Captcha fetch returned null");
          continue;
        }

        // 2. Solve Captcha
        String? captchaCode = await _captchaService.solveCaptcha(captchaImage);
        if (captchaCode == null) {
          print("AutoLogin: AI failed to solve captcha");
          continue;
        }

        // 3. Login
        print("AutoLogin: Trying with code $captchaCode");
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
        print("AutoLogin: Error on attempt ${i + 1}: $e");
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
