/// Get Quick Login Profile UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import '../repositories/settings_repository.dart';

/// Hızlı giriş için seçili profili getir
class GetQuickLoginProfileUseCase {
  final SettingsRepository _repository;

  const GetQuickLoginProfileUseCase(this._repository);

  /// Hızlı giriş için seçili username'i döndürür
  /// Eğer ayarlanmamışsa null döner
  Future<String?> call() => _repository.getQuickLoginProfile();
}
