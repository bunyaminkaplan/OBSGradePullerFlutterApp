import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<bool> execute(
    String studentNumber,
    String password,
    String captchaCode,
  ) {
    return repository.login(studentNumber, password, captchaCode);
  }

  Future<void> logout() {
    return repository.logout();
  }
}
