/// Toggle University UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import 'repositories/settings_repository.dart';
import '../../auth/domain/repositories/auth_repository.dart';

/// Üniversite değiştirme işlemi için UseCase
class ToggleUniversityUseCase {
  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;

  const ToggleUniversityUseCase(this._settingsRepository, this._authRepository);

  /// Üniversiteyi değiştir
  Future<String> call() async {
    // 1. Storage'da toggle
    final newName = await _settingsRepository.toggleUniversity();

    // 2. Yeni URL'i al
    final newUrl = await _settingsRepository.getUniversityUrl();

    // 3. AuthRepository'yi güncelle
    if (newUrl != null) {
      _authRepository.setBaseUrl(newUrl);
    }

    return newName;
  }

  /// Kayıtlı URL'i yükle (uygulama başlangıcı için)
  Future<void> loadSavedUrl() async {
    final saved = await _settingsRepository.getUniversityUrl();
    if (saved != null) {
      _authRepository.setBaseUrl(saved);
    }
  }
}
