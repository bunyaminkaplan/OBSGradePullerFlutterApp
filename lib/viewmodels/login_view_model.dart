import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/get_captcha_usecase.dart';
import '../features/auth/domain/usecases/auto_login_usecase.dart';
import '../features/settings/domain/toggle_university_usecase.dart';
import '../services/captcha_service.dart';
import '../core/services/logger_service.dart';

enum LoginState { initial, loading, success, failure }

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCaptchaUseCase _getCaptchaUseCase;
  final AutoLoginUseCase _autoLoginUseCase;
  final ToggleUniversityUseCase _toggleUniversityUseCase;
  final CaptchaService _captchaService;
  final LoggerService _logger; // Logger eklendi

  LoginState _state = LoginState.initial;
  String _errorMessage = '';
  Uint8List? _captchaImage;
  String _captchaCode = '';

  LoginViewModel({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCaptchaUseCase getCaptchaUseCase,
    required AutoLoginUseCase autoLoginUseCase,
    required ToggleUniversityUseCase toggleUniversityUseCase,
    required CaptchaService captchaService,
    LoggerService? logger, // Opsiyonel parametre
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _getCaptchaUseCase = getCaptchaUseCase,
       _autoLoginUseCase = autoLoginUseCase,
       _toggleUniversityUseCase = toggleUniversityUseCase,
       _captchaService = captchaService,
       _logger = logger ?? LoggerService();

  Future<void> loadInitialSettings() async {
    await _toggleUniversityUseCase.loadSavedUrl();
    await loadCaptcha(); // Load captcha after setting URL
  }

  Future<String> toggleUniversity() async {
    final name = await _toggleUniversityUseCase();
    await loadCaptcha(); // Reload captcha from new university
    return name;
  }

  LoginState get state => _state;
  String get errorMessage => _errorMessage;
  Uint8List? get captchaImage => _captchaImage;
  String get captchaCode => _captchaCode;

  Future<void> loadCaptcha() async {
    _state = LoginState.loading;
    notifyListeners();

    try {
      // Use the new UseCase instead of direct Service call
      final image = await _getCaptchaUseCase();

      if (image != null) {
        _captchaImage = image;
        _state = LoginState.initial;
        notifyListeners();

        // Auto-solve
        final solvedCode = await _captchaService.solve(image);
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
        _logger.info("MİMARİ LOG: Manual Login requested.");
        success = await _loginUseCase(studentNumber, password, manualCaptcha);
      } else {
        // AUTO LOGIN (Retry Logic in UseCase)
        _logger.info("MİMARİ LOG: Auto Login requested (Smart Retry).");
        success = await _autoLoginUseCase(studentNumber, password);
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
      _logger.error("Login View Model Error", error: e);
    }

    notifyListeners();
    // Refresh captcha if failed so user can try again
    if (_state == LoginState.failure) {
      loadCaptcha();
    }
    return false;
  }

  Future<void> logout() async {
    await _logoutUseCase();
    _state = LoginState.initial;
    notifyListeners();
  }
}
