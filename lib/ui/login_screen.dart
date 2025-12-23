import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';

import '../viewmodels/login_view_model.dart';
import 'grades_screen.dart';

// Widgets
import 'widgets/login/easter_egg_logo.dart';
import 'widgets/login/animated_login_content.dart';
import 'widgets/login/profile_selection_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();

  late AnimationController _vibrationController;

  // UI State
  List<Map<String, String>> _profiles = [];
  bool _showManualLogin = false;
  bool _showMenu = false;
  int _hoveredIndex = -1;
  bool _showHint = true;
  double _buttonTopY = 0; // Y position of button for menu alignment

  // Swipe gesture state
  double _swipeDelta = 0.0; // Current swipe offset
  bool _isIsolated = false; // Whether an item is currently isolated

  // Key for getting button position
  final GlobalKey _contentKey = GlobalKey();

  // Edit State
  Map<String, String>? _editingProfile;

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
        _showManualLogin = _profiles.isEmpty;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onShowMenu() {
    // Calculate button position for menu alignment
    final RenderBox? box =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final position = box.localToGlobal(Offset.zero);
      _buttonTopY = position.dy;
    }

    setState(() {
      _showMenu = true;
      _hoveredIndex = -1;
      _showHint = false;
    });
    _startVibration();
  }

  void _onHoverIndexChanged(int index) {
    int validIndex = index;
    if (index < 0 || index >= _profiles.length) validIndex = -1;
    if (_hoveredIndex != validIndex) {
      setState(() => _hoveredIndex = validIndex);
    }
  }

  void _onSelectionConfirmed(int index) {
    _stopVibration();
    if (_showMenu) {
      if (index == -1) {
        if (_hoveredIndex >= 0 && _hoveredIndex < _profiles.length) {
          _storage.setHintShown();
          _loginWithProfile(_hoveredIndex);
        }
      }
      setState(() => _showMenu = false);
    }
  }

  void _startVibration() {
    if (!_vibrationController.isAnimating) {
      _vibrationController.repeat(reverse: true);
    }
  }

  void _stopVibration() {
    _vibrationController.stop();
    _vibrationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: isDark ? Colors.grey[800] : Colors.black,
        onPressed: () => context.read<ThemeService>().toggleTheme(),
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          // Main Content - Bottom Aligned
          SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // HEADER
                          const EasterEggLogo(),
                          const SizedBox(height: 24),
                          Text(
                            "OBS Ozal",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // ANIMATED CONTENT (Profile <-> Form)
                          AnimatedLoginContent(
                            key: _contentKey,
                            showManualForm: _showManualLogin,
                            profiles: _profiles,
                            showHint: _showHint,
                            editingUsername: _editingProfile?['username'],
                            editingPassword: _editingProfile?['password'],
                            onManualLoginRequested: () {
                              setState(() {
                                _showManualLogin = true;
                                _editingProfile = null;
                              });
                            },
                            onCancelRequested: () {
                              setState(() {
                                _showManualLogin = false;
                                _editingProfile = null;
                              });
                            },
                            onShowMenu: _onShowMenu,
                            onHoverIndexChanged: _onHoverIndexChanged,
                            onSelectionConfirmed: _onSelectionConfirmed,
                            isIsolated: _isIsolated,
                            onSwipeDelta: (delta) {
                              setState(() => _swipeDelta = delta);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Selection Overlay
          if (_showMenu)
            ProfileSelectionOverlay(
              profiles: _profiles,
              hoveredIndex: _hoveredIndex,
              vibrationController: _vibrationController,
              buttonTopY: _buttonTopY,
              swipeDelta: _swipeDelta,
              onIsolationChanged: (isIsolated, index) {
                setState(() {
                  _isIsolated = isIsolated;
                  _swipeDelta = 0.0;
                });
              },
              onSwipeActionComplete: () {
                setState(() {
                  _showMenu = false;
                  _swipeDelta = 0.0;
                  _isIsolated = false;
                });
              },
              onProfileSelected: (index) {
                _loginWithProfile(index);
                setState(() {
                  _showMenu = false;
                  _swipeDelta = 0.0;
                });
              },
              onDelete: (index) async {
                final p = _profiles[index];
                await _storage.removeProfile(p['username']!);
                await _loadProfiles();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profil Silindi"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              onEdit: (index) {
                final p = _profiles[index];
                setState(() {
                  _showMenu = false;
                  _showManualLogin = true;
                  _editingProfile = p;
                  _swipeDelta = 0.0;
                  _isIsolated = false;
                });
                context.read<LoginViewModel>().loadCaptcha();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Düzenleme Modu"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
