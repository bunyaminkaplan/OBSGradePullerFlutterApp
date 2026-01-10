/// Set Quick Login Profile UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import '../repositories/settings_repository.dart';

/// Hızlı giriş için profil seç veya devre dışı bırak
class SetQuickLoginProfileUseCase {
  final SettingsRepository _repository;

  const SetQuickLoginProfileUseCase(this._repository);

  /// Hızlı giriş profilini ayarla
  /// [username] null geçilirse özellik devre dışı kalır
  Future<void> call(String? username) =>
      _repository.setQuickLoginProfile(username);
}
