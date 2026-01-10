import 'package:flutter/material.dart';

import '../../domain/usecases/get_quick_login_profile_usecase.dart';
import '../../domain/usecases/set_quick_login_profile_usecase.dart';
import '../../../../infrastructure/storage/secure_storage_service.dart';

/// Settings ViewModel - Presentation Layer
/// Ayarlar ekranı için state yönetimi
class SettingsViewModel extends ChangeNotifier {
  final GetQuickLoginProfileUseCase _getQuickLoginProfile;
  final SetQuickLoginProfileUseCase _setQuickLoginProfile;
  final SecureStorageService _storageService;

  // State
  String? _quickLoginProfile;
  List<Map<String, String>> _profiles = [];
  bool _isLoading = true;

  SettingsViewModel({
    required GetQuickLoginProfileUseCase getQuickLoginProfile,
    required SetQuickLoginProfileUseCase setQuickLoginProfile,
    required SecureStorageService storageService,
  }) : _getQuickLoginProfile = getQuickLoginProfile,
       _setQuickLoginProfile = setQuickLoginProfile,
       _storageService = storageService;

  // Getters
  String? get quickLoginProfile => _quickLoginProfile;
  List<Map<String, String>> get profiles => _profiles;
  bool get isLoading => _isLoading;
  bool get isQuickLoginEnabled => _quickLoginProfile != null;

  /// Ayarları yükle
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    _profiles = await _storageService.getProfiles();
    _quickLoginProfile = await _getQuickLoginProfile();

    _isLoading = false;
    notifyListeners();
  }

  /// Hızlı giriş profilini ayarla
  /// [username] null geçilirse özellik devre dışı kalır
  Future<void> setQuickLogin(String? username) async {
    await _setQuickLoginProfile(username);
    _quickLoginProfile = username;
    notifyListeners();
  }

  /// Belirli bir profil için hızlı giriş aktif mi?
  bool isProfileSelected(String username) {
    return _quickLoginProfile == username;
  }
}
