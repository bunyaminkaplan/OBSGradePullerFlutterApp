/// Core error types for Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

/// Temel hata sınıfı - Domain katmanında kullanılır
/// Data katmanından gelen exception'lar burada Failure'a dönüştürülür
sealed class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Sunucu kaynaklı hatalar (API, OBS vb.)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, super.code, this.statusCode});

  @override
  String toString() =>
      'ServerFailure(message: $message, statusCode: $statusCode)';
}

/// Önbellek/Yerel depolama hataları
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});

  @override
  String toString() => 'CacheFailure(message: $message)';
}

/// Ağ bağlantısı hataları
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'İnternet bağlantısı yok',
    super.code = 'NO_NETWORK',
  });

  @override
  String toString() => 'NetworkFailure(message: $message)';
}

/// Captcha çözümleme hataları
class CaptchaFailure extends Failure {
  const CaptchaFailure({
    super.message = 'Captcha çözülemedi',
    super.code = 'CAPTCHA_ERROR',
  });

  @override
  String toString() => 'CaptchaFailure(message: $message)';
}

/// Oturum hataları (session expired vb.)
class SessionFailure extends Failure {
  const SessionFailure({
    super.message = 'Oturum süresi doldu',
    super.code = 'SESSION_EXPIRED',
  });

  @override
  String toString() => 'SessionFailure(message: $message)';
}

/// Bilinmeyen/Beklenmeyen hatalar
class UnknownFailure extends Failure {
  final Object? originalError;

  const UnknownFailure({
    super.message = 'Beklenmeyen bir hata oluştu',
    super.code = 'UNKNOWN',
    this.originalError,
  });

  @override
  String toString() =>
      'UnknownFailure(message: $message, error: $originalError)';
}
