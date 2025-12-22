import '../repositories/settings_repository.dart';
import '../repositories/auth_repository.dart';

class ToggleUniversityUseCase {
  final ISettingsRepository _settingsRepository;
  final AuthRepository _authRepository;

  ToggleUniversityUseCase(this._settingsRepository, this._authRepository);

  Future<String> execute() async {
    // 1. Toggle Storage
    String newName = await _settingsRepository.toggleUniversity();

    // 2. Get New URL
    String? newUrl = await _settingsRepository.getUniversityUrl();

    // 3. Update AuthRepo (which updates DataSource)
    if (newUrl != null) {
      _authRepository.setBaseUrl(newUrl);
    }

    return newName;
  }

  // Also useful: Load Initial UseCase
  Future<void> loadSavedUrl() async {
    String? saved = await _settingsRepository.getUniversityUrl();
    if (saved != null) {
      _authRepository.setBaseUrl(saved);
    }
  }
}
