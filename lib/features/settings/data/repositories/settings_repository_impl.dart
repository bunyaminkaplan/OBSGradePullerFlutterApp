import '../../../../infrastructure/storage/secure_storage_service.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SecureStorageService _storageService;

  // Hardcoded constants moved here or in AppConstants
  final String _ozalUrl = "https://obs.ozal.edu.tr";
  final String _inonuUrl = "https://obs.inonu.edu.tr";

  SettingsRepositoryImpl(this._storageService);

  @override
  Future<String> toggleUniversity() async {
    String? current = await _storageService.getUniversityUrl();
    String newUrl;
    String newName;

    if (current == _inonuUrl) {
      newUrl = _ozalUrl;
      newName = "Turgut Özal Üniversitesi";
    } else {
      newUrl = _inonuUrl;
      newName = "İnönü Üniversitesi";
    }

    await _storageService.saveUniversityUrl(newUrl);
    return newName;
  }

  @override
  Future<String?> getUniversityUrl() async {
    return await _storageService.getUniversityUrl();
  }

  @override
  Future<void> saveUniversityUrl(String url) async {
    await _storageService.saveUniversityUrl(url);
  }

  @override
  Future<String?> getQuickLoginProfile() async {
    return await _storageService.getQuickLoginProfile();
  }

  @override
  Future<void> setQuickLoginProfile(String? username) async {
    await _storageService.setQuickLoginProfile(username);
  }
}
