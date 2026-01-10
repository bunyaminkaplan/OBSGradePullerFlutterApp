/// Captcha Solver Interface - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import 'dart:typed_data';

/// Captcha çözme işlemi için interface
/// Data katmanında TFLite implementasyonu olacak
abstract interface class CaptchaSolver {
  /// Modeli yükle
  Future<void> loadModel();

  /// Captcha görselini çöz
  /// [imageBytes] captcha görselinin byte'ları
  /// Başarılı ise çözüm (örn: "45"), başarısız ise null
  Future<String?> solve(Uint8List imageBytes);
}
