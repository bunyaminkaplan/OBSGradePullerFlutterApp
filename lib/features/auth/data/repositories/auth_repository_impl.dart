/// Auth Repository Implementation - Data Layer
library;

import 'dart:typed_data';
import '../datasources/auth_remote_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// AuthRepository implementasyonu
/// DataSource'u kullanarak domain sözleşmesini yerine getirir
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<bool> login(
    String studentNumber,
    String password,
    String captchaCode,
  ) async {
    return _remoteDataSource.login(studentNumber, password, captchaCode);
  }

  @override
  Future<Uint8List?> fetchCaptchaImage() async {
    return _remoteDataSource.fetchLoginPage();
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
  }

  @override
  void setBaseUrl(String url) {
    _remoteDataSource.setBaseUrl(url);
  }

  @override
  Future<User?> getCurrentUser() async {
    // TODO: Implement user persistence if needed
    return null;
  }
}
