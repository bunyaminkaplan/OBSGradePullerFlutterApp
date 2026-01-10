/// Settings Repository Interface - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

/// Uygulama ayarları için repository sözleşmesi
abstract interface class SettingsRepository {
  /// Üniversite URL'ini değiştir (toggle)
  Future<String> toggleUniversity();

  /// Kayıtlı üniversite URL'ini getir
  Future<String?> getUniversityUrl();

  /// Üniversite URL'ini kaydet
  Future<void> saveUniversityUrl(String url);

  /// Hızlı giriş için seçili profil username'ini getir
  Future<String?> getQuickLoginProfile();

  /// Hızlı giriş için profil seç (null = devre dışı bırak)
  Future<void> setQuickLoginProfile(String? username);
}
