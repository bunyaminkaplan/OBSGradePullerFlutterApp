/// Secure Storage Service - Infrastructure Layer
library;

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';
import '../../core/services/logger_service.dart';

/// Güvenli yerel depolama servisi
/// Kullanıcı profilleri ve ayarlar için
class SecureStorageService {
  final FlutterSecureStorage _storage;
  final LoggerService _logger;

  SecureStorageService([FlutterSecureStorage? storage, LoggerService? logger])
    : _storage = storage ?? const FlutterSecureStorage(),
      _logger = logger ?? LoggerService();

  /// Kayıtlı profilleri getir
  Future<List<Map<String, String>>> getProfiles() async {
    try {
      // Legacy migrasyon kontrolü
      final legacyUser = await _storage.read(key: StorageKeys.legacyUsername);
      if (legacyUser != null) {
        await _migrateLegacyProfile();
      }

      final json = await _storage.read(key: StorageKeys.profiles);
      if (json == null) return [];

      final decoded = jsonDecode(json) as List;
      return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (e) {
      _logger.error('Profil okuma hatası: $e', error: e);
      return [];
    }
  }

  /// Profil kaydet
  Future<void> saveProfile({
    required String username,
    required String password,
    String? alias,
  }) async {
    try {
      final profiles = await getProfiles();

      // Mevcut profili bul veya yeni ekle
      final existingIndex = profiles.indexWhere(
        (p) => p['username'] == username,
      );

      final profile = {
        'username': username,
        'password': password,
        if (alias != null) 'alias': alias,
      };

      if (existingIndex >= 0) {
        profiles[existingIndex] = profile;
      } else {
        profiles.add(profile);
      }

      await _storage.write(
        key: StorageKeys.profiles,
        value: jsonEncode(profiles),
      );
      _logger.info('Profil kaydedildi: $username');
    } catch (e) {
      _logger.error('Profil kaydetme hatası: $e', error: e);
    }
  }

  /// Profil sil
  Future<void> removeProfile(String username) async {
    try {
      final profiles = await getProfiles();
      profiles.removeWhere((p) => p['username'] == username);

      await _storage.write(
        key: StorageKeys.profiles,
        value: jsonEncode(profiles),
      );
      _logger.info('Profil silindi: $username');
    } catch (e) {
      _logger.error('Profil silme hatası: $e', error: e);
    }
  }

  /// Üniversite URL'ini getir
  Future<String?> getUniversityUrl() async {
    return _storage.read(key: StorageKeys.universityUrl);
  }

  /// Üniversite URL'ini kaydet
  Future<void> saveUniversityUrl(String url) async {
    await _storage.write(key: StorageKeys.universityUrl, value: url);
  }

  /// Hint gösterildi mi?
  Future<bool> shouldShowHint() async {
    final shown = await _storage.read(key: StorageKeys.hintShown);
    return shown != 'true';
  }

  /// Hint gösterildi olarak işaretle
  Future<void> setHintShown() async {
    await _storage.write(key: StorageKeys.hintShown, value: 'true');
  }

  /// Hızlı giriş profili getir
  Future<String?> getQuickLoginProfile() async {
    return _storage.read(key: StorageKeys.quickLoginProfile);
  }

  /// Hızlı giriş profili kaydet
  Future<void> setQuickLoginProfile(String? username) async {
    if (username == null || username.isEmpty) {
      await _storage.delete(key: StorageKeys.quickLoginProfile);
      _logger.info('Hızlı giriş devre dışı bırakıldı');
    } else {
      await _storage.write(key: StorageKeys.quickLoginProfile, value: username);
      _logger.info('Hızlı giriş profili ayarlandı: $username');
    }
  }

  /// Tüm verileri temizle
  Future<void> clearAll() async {
    await _storage.deleteAll();
    _logger.info('Tüm depolama temizlendi');
  }

  /// Legacy profil migrasyonu
  Future<void> _migrateLegacyProfile() async {
    try {
      final username = await _storage.read(key: StorageKeys.legacyUsername);
      final password = await _storage.read(key: StorageKeys.legacyPassword);

      if (username != null && password != null) {
        await saveProfile(username: username, password: password);
        await _storage.delete(key: StorageKeys.legacyUsername);
        await _storage.delete(key: StorageKeys.legacyPassword);
        _logger.info('Legacy profil migre edildi');
      }
    } catch (e) {
      _logger.error('Legacy migrasyon hatası: $e', error: e);
    }
  }
}
