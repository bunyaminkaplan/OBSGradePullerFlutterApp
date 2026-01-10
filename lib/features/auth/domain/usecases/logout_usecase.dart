/// Logout UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import '../repositories/auth_repository.dart';

/// Çıkış işlemi için UseCase
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  /// Çıkış işlemini gerçekleştir
  Future<void> call() {
    return _repository.logout();
  }
}
