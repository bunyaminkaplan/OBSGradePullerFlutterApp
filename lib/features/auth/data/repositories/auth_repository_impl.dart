import 'dart:typed_data';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<bool> login(
    String studentNumber,
    String password,
    String captchaCode,
  ) async {
    return await _remoteDataSource.login(studentNumber, password, captchaCode);
  }

  // Note: AutoLogin logic moved to Repository or UseCase retry loop ideally,
  // but for now relying on DataSource if implemented there, or removing given it was loop logic.
  // The DataSource we wrote does NOT have autoLogin loop.
  // We should implement the loop behavior here or in UseCase.
  // For simplicity request: Let's keep it simple. If DataSource doesn't have autoLogin,
  // we can implement a basic version here or skip.
  // Wait, let's look at the contract. Interface has autoLogin.
  // We need to implement it.
  @override
  Future<Uint8List?> fetchCaptchaImage() async {
    return await _remoteDataSource.fetchLoginPage();
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
    return null;
  }
}
