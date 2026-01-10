import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_captcha_usecase.dart';
import '../../domain/usecases/auto_login_usecase.dart';
import '../../../settings/domain/toggle_university_usecase.dart';
import '../../../captcha/domain/services/captcha_solver.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../infrastructure/storage/secure_storage_service.dart';

enum LoginState { initial, loading, success, failure }

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCaptchaUseCase _getCaptchaUseCase;
  final AutoLoginUseCase _autoLoginUseCase;
  final ToggleUniversityUseCase _toggleUniversityUseCase;
  final CaptchaSolver _captchaService;
  final LoggerService _logger;
  final SecureStorageService _storageService;

  LoginState _state = LoginState.initial;
  String _errorMessage = '';
  Uint8List? _captchaImage;
  String _captchaCode = '';

  // Profile Data
  List<Map<String, String>> _profiles = [];
  bool _showHint = true;

  LoginViewModel({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCaptchaUseCase getCaptchaUseCase,
    required AutoLoginUseCase autoLoginUseCase,
    required ToggleUniversityUseCase toggleUniversityUseCase,
    required CaptchaSolver captchaService,
    required SecureStorageService storageService,
    LoggerService? logger,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _getCaptchaUseCase = getCaptchaUseCase,
       _autoLoginUseCase = autoLoginUseCase,
       _toggleUniversityUseCase = toggleUniversityUseCase,
       _captchaService = captchaService,
       _storageService = storageService,
       _logger = logger ?? LoggerService();

  LoginState get state => _state;
  String get errorMessage => _errorMessage;
  Uint8List? get captchaImage => _captchaImage;
  String get captchaCode => _captchaCode;
  List<Map<String, String>> get profiles => _profiles;
  bool get showHint => _showHint;

  Future<void> loadInitialData() async {
    await _toggleUniversityUseCase.loadSavedUrl();
    await loadCaptcha();
    await _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final list = await _storageService.getProfiles();
    for (var p in list) {
      if (p['alias'] == 'Varsayılan' && p['username'] == '02230202057') {
        p['alias'] = 'Bunyamin';
      }
    }
    _profiles = list;
    _showHint = await _storageService.shouldShowHint();
    notifyListeners();
  }

  Future<void> removeProfile(String username) async {
    await _storageService.removeProfile(username);
    await _loadProfiles();
  }

  Future<void> setHintShown() async {
    await _storageService.setHintShown();
    _showHint = false;
    notifyListeners();
  }

  Future<String> toggleUniversity() async {
    final name = await _toggleUniversityUseCase();
    await loadCaptcha();
    return name;
  }

  Future<void> loadCaptcha() async {
    _state = LoginState.loading;
    notifyListeners();

    try {
      final image = await _getCaptchaUseCase();

      if (image != null) {
        _captchaImage = image;
        _state = LoginState.initial;
        notifyListeners();

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
        _logger.info("MİMARİ LOG: Manual Login requested.");
        success = await _loginUseCase(studentNumber, password, manualCaptcha);
      } else {
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
