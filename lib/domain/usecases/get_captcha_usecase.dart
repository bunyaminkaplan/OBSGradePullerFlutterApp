import 'dart:typed_data';
import '../repositories/auth_repository.dart';

class GetCaptchaUseCase {
  final AuthRepository _repository;

  GetCaptchaUseCase(this._repository);

  Future<Uint8List?> execute() async {
    return await _repository.fetchCaptchaImage();
  }
}
