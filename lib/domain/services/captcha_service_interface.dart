import 'dart:typed_data';

abstract class ICaptchaService {
  Future<void> loadModel();
  Future<String?> solveCaptcha(Uint8List imageBytes);
}
