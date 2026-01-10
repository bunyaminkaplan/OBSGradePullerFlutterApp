/// Auth Repository Interface - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import 'dart:typed_data';
import '../entities/user.dart';

/// Authentication işlemleri için repository sözleşmesi
/// Data katmanı bu interface'i implement eder
abstract interface class AuthRepository {
  /// Login işlemi
  /// [studentNumber] öğrenci numarası
  /// [password] şifre
  /// [captchaCode] çözülmüş captcha kodu
  /// Başarılı ise true döner
  Future<bool> login(String studentNumber, String password, String captchaCode);

  /// Captcha görselini çeker
  /// Başarılı ise Uint8List (image bytes) döner
  Future<Uint8List?> fetchCaptchaImage();

  /// Çıkış işlemi
  Future<void> logout();

  /// Mevcut kullanıcıyı döndür
  Future<User?> getCurrentUser();

  /// Base URL'i değiştir (üniversite değişimi için)
  void setBaseUrl(String url);
}
