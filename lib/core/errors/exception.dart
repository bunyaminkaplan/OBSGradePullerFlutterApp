/// Core exception types for Data Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

/// Temel exception sınıfı - Data katmanında kullanılır
/// Repository'ler bu exception'ları Failure'a dönüştürür
sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

/// Sunucu kaynaklı exception'lar (HTTP hataları vb.)
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({required super.message, super.code, this.statusCode});

  @override
  String toString() =>
      'ServerException(message: $message, statusCode: $statusCode)';
}

/// Önbellek/Yerel depolama exception'ları
class CacheException extends AppException {
  const CacheException({required super.message, super.code});

  @override
  String toString() => 'CacheException(message: $message)';
}

/// Ağ bağlantısı exception'ları
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'İnternet bağlantısı yok',
    super.code = 'NO_NETWORK',
  });

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// Captcha çözümleme exception'ları
class CaptchaException extends AppException {
  const CaptchaException({
    super.message = 'Captcha çözülemedi',
    super.code = 'CAPTCHA_ERROR',
  });

  @override
  String toString() => 'CaptchaException(message: $message)';
}

/// HTML parsing exception'ları
class ParseException extends AppException {
  const ParseException({
    super.message = 'Sayfa yapısı çözümlenemedi',
    super.code = 'PARSE_ERROR',
  });

  @override
  String toString() => 'ParseException(message: $message)';
}

/// Oturum exception'ları
class SessionException extends AppException {
  const SessionException({
    super.message = 'Oturum süresi doldu',
    super.code = 'SESSION_EXPIRED',
  });

  @override
  String toString() => 'SessionException(message: $message)';
}
