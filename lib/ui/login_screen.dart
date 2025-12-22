import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';

import '../viewmodels/login_view_model.dart';
import 'grades_screen.dart';

// Widgets
import 'widgets/login/easter_egg_logo.dart';
import 'widgets/login/login_manual_form.dart';
import 'widgets/login/profile_selection_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();

  // Animations (Only for Overlay coordination if needed, but Overlay manages itself mostly)
  // Actually, TriggerButton needs to coordinate vibration with Overlay.
  // We can lift the vibration controller here to pass to both.
  late AnimationController _vibrationController;

  // UI State
  List<Map<String, String>> _profiles = [];
  bool _showManualLogin = false;
  bool _showMenu = false;
  int _hoveredIndex = -1;
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _vibrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: -1.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _vibrationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final list = await _storage.getProfiles();
    // Legacy fix
    for (var p in list) {
      if (p['alias'] == 'Varsayılan' && p['username'] == '02230202057') {
        p['alias'] = 'Bunyamin';
      }
    }
    final showHint = await _storage.shouldShowHint();

    if (mounted) {
      await context.read<LoginViewModel>().loadInitialSettings();
      setState(() {
        _profiles = list;
        _showHint = showHint;
        if (_profiles.isEmpty) {
          _showManualLogin = true;
        } else {
          _showManualLogin = false;
        }
        // Always load captcha to initialize session/viewstate for one-tap login
        // context.read<LoginViewModel>().loadCaptcha(); // Done in loadInitialSettings
      });
    }
  }

  Future<void> _loginWithProfile(int index) async {
    if (index < 0 || index >= _profiles.length) return;

    final p = _profiles[index];
    final viewModel = context.read<LoginViewModel>();

    final success = await viewModel.login(p['username']!, p['password']!);

    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GradesScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(viewModel.errorMessage)));
      }
    }
  }

  // Coordination methods
  void _onShowMenu() {
    setState(() {
      _showMenu = true;
      _hoveredIndex = -1;
      _showHint = false;
    });
    _startVibration();
  }

  void _onHoverIndexChanged(int index) {
    // Validate index
    int validIndex = index;
    if (index < 0 || index >= _profiles.length) validIndex = -1;

    if (_hoveredIndex != validIndex) {
      setState(() => _hoveredIndex = validIndex);
    }
  }

  void _onSelectionConfirmed(int index) {
    // -1 logic checked, -2 cancel
    _stopVibration();
    if (_showMenu) {
      if (index == -1) {
        // Standard check from hover state
        if (_hoveredIndex >= 0 && _hoveredIndex < _profiles.length) {
          _storage.setHintShown();
          _loginWithProfile(_hoveredIndex);
        }
      }
      setState(() => _showMenu = false);
    }
  }

  void _startVibration() {
    if (!_vibrationController.isAnimating)
      _vibrationController.repeat(reverse: true);
  }

  void _stopVibration() {
    _vibrationController.stop();
    _vibrationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ViewModel just for loading state if needed for global blocking
    // or let widgets handle it.
    // Manual Form handles its own listening. Trigger Button doesn't need it.

    final showProfiles = _profiles.isNotEmpty && !_showManualLogin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: isDark ? Colors.grey[800] : Colors.black,
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: Colors.white,
        ),
        onPressed: () => context.read<ThemeService>().toggleTheme(),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const EasterEggLogo(),
                    const SizedBox(height: 24),
                    Text(
                      "OBS Ozal",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 48),

                    if (showProfiles)
                      ProfileTriggerButton(
                        onShowMenu: _onShowMenu,
                        onManualLogin: () {
                          setState(() => _showManualLogin = true);
                          context.read<LoginViewModel>().loadCaptcha();
                        },
                        onHoverIndexChanged: _onHoverIndexChanged,
                        onSelectionConfirmed: _onSelectionConfirmed,
                        showHint: _showHint,
                        profiles: _profiles,
                      )
                    else
                      LoginManualForm(
                        showCancelButton: _profiles.isNotEmpty,
                        onCancel: () =>
                            setState(() => _showManualLogin = false),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (_showMenu)
            ProfileSelectionOverlay(
              profiles: _profiles,
              hoveredIndex: _hoveredIndex,
              vibrationController: _vibrationController,
            ),
        ],
      ),
    );
  }
}
