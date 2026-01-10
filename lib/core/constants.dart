/// Core Constants - SAF DART
/// Tüm sabitler burada kategorize edilmiştir
library;

/// API endpoint sabitleri
abstract final class ApiConstants {
  static const String loginEndpoint = '/oibs/std/login.aspx';
  static const String gradesEndpoint = '/oibs/std/not_listesi_op.aspx';
  static const String statsEndpoint = '/oibs/acd/new_not_giris_istatistik.aspx';
  static const String captchaEndpoint = '/oibs/captcha/CaptchaImg.aspx';
}

/// Üniversite URL sabitleri
abstract final class UniversityConstants {
  static const String ozalUrl = 'https://obs.ozal.edu.tr';
  static const String inonuUrl = 'https://obs.inonu.edu.tr'; // Örnek alternatif

  static const Map<String, String> universities = {
    'ozal': ozalUrl,
    // Gelecekte eklenebilecek diğer üniversiteler
  };
}

/// Captcha işleme sabitleri
abstract final class CaptchaConstants {
  /// Digit slice koordinatları (x_start, x_end)
  /// Yükseklik her zaman 40px
  static const List<List<int>> digitSlices = [
    [13, 29], // Digit 1 (Width: 16)
    [29, 52], // Digit 2 (Width: 23)
    [88, 110], // Digit 3 (Width: 22)
  ];

  /// AI model dosya yolları
  static const String modelPath = 'assets/digit_model.tflite';
  static const String modelOldPath = 'assets/digit_model_old.tflite';
}

/// Storage key sabitleri
abstract final class StorageKeys {
  static const String profiles = 'obs_profiles';
  static const String universityUrl = 'uni_base_url_v1';
  static const String hintShown = 'hint_shown_v1';
  static const String quickLoginProfile = 'quick_login_profile_v1';

  // Legacy keys (migrasyon için)
  static const String legacyUsername = 'obs_username';
  static const String legacyPassword = 'obs_password';
}

/// HTTP Header sabitleri
abstract final class HttpConstants {
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Login retry sabitleri
abstract final class RetryConstants {
  static const int maxLoginAttempts = 5;
  static const Duration retryDelay = Duration(milliseconds: 1000);
}
