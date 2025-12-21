import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/get_captcha_usecase.dart';
import '../domain/usecases/auto_login_usecase.dart';
import '../services/captcha_service.dart';

enum LoginState { initial, loading, success, failure }

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final GetCaptchaUseCase _getCaptchaUseCase;
  final AutoLoginUseCase _autoLoginUseCase;
  final CaptchaService _captchaService;

  LoginState _state = LoginState.initial;
  String _errorMessage = '';
  Uint8List? _captchaImage;
  String _captchaCode = '';

  LoginViewModel({
    required LoginUseCase loginUseCase,
    required GetCaptchaUseCase getCaptchaUseCase,
    required AutoLoginUseCase autoLoginUseCase,
    required CaptchaService captchaService,
  }) : _loginUseCase = loginUseCase,
       _getCaptchaUseCase = getCaptchaUseCase,
       _autoLoginUseCase = autoLoginUseCase,
       _captchaService = captchaService;

  LoginState get state => _state;
  String get errorMessage => _errorMessage;
  Uint8List? get captchaImage => _captchaImage;
  String get captchaCode => _captchaCode;

  Future<void> loadCaptcha() async {
    _state = LoginState.loading;
    notifyListeners();

    try {
      // Use the new UseCase instead of direct Service call
      final image = await _getCaptchaUseCase.execute();

      if (image != null) {
        _captchaImage = image;
        _state = LoginState.initial;
        notifyListeners();

        // Auto-solve
        final solvedCode = await _captchaService.solveCaptcha(image);
        if (solvedCode != null) {
          _captchaCode = solvedCode;
        } else {
          _errorMessage = "AI Okuyamadı";
        }
      } else {
        _errorMessage = "Captcha Yüklenemedi";
        _state = LoginState.failure;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = LoginState.failure;
    }
    notifyListeners();
  }

  Future<bool> login(
    String studentNumber,
    String password, {
    String? manualCaptcha,
  }) async {
    _state = LoginState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      bool success = false;

      if (manualCaptcha != null) {
        // MANUAL LOGIN (Single Attempt)
        print("MİMARİ LOG: Manual Login requested.");
        success = await _loginUseCase.execute(
          studentNumber,
          password,
          manualCaptcha,
        );
      } else {
        // AUTO LOGIN (Retry Logic in UseCase)
        print("MİMARİ LOG: Auto Login requested (Smart Retry).");
        success = await _autoLoginUseCase.execute(studentNumber, password);
      }

      if (success) {
        _state = LoginState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Giriş Başarısız. Bilgileri kontrol edin.";
        _state = LoginState.failure;
      }
    } catch (e) {
      _errorMessage = "Hata: $e";
      _state = LoginState.failure;
    }

    notifyListeners();
    // Refresh captcha if failed so user can try again
    if (_state == LoginState.failure) {
      loadCaptcha();
    }
    return false;
  }
}
