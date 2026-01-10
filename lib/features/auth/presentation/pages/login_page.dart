import 'dart:ui'; // For clamp
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';

import '../viewmodels/login_view_model.dart';
import '../../../grades/presentation/pages/grades_page.dart';

// Widgets
import '../widgets/easter_egg_logo.dart';
import '../widgets/animated_login_content.dart';
import '../widgets/profile_selection_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _vibrationController;

  // UI State (Transients)
  bool _showManualLogin = false;
  bool _showMenu = false;
  int _hoveredIndex = -1;
  double _buttonTopY = 0;
  double _swipeDelta = 0.0;
  bool _isIsolated = false;
  final GlobalKey _contentKey = GlobalKey();

  // Edit State
  Map<String, String>? _editingProfile;

  @override
  void initState() {
    super.initState();
    // Start Data Loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginViewModel>().loadInitialData();
    });

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

  // --- UI Action Handlers ---

  Future<void> _loginWithProfile(int index) async {
    final viewModel = context.read<LoginViewModel>();
    if (index < 0 || index >= viewModel.profiles.length) return;

    final p = viewModel.profiles[index];
    final success = await viewModel.login(p['username']!, p['password']!);

    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GradesPage()),
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
    final RenderBox? box =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final position = box.localToGlobal(Offset.zero);
      _buttonTopY = position.dy;
    }

    setState(() {
      _showMenu = true;
      _hoveredIndex = -1;
    });
    _startVibration();
  }

  void _onHoverIndexChanged(int index) {
    final viewModel = context.read<LoginViewModel>();
    int validIndex = index;
    if (index < 0 || index >= viewModel.profiles.length) validIndex = -1;
    if (_hoveredIndex != validIndex) {
      setState(() => _hoveredIndex = validIndex);
    }
  }

  void _onSelectionConfirmed(int index) {
    _stopVibration();
    if (_showMenu) {
      if (index == -1) {
        final viewModel = context.read<LoginViewModel>();
        if (_hoveredIndex >= 0 && _hoveredIndex < viewModel.profiles.length) {
          viewModel.setHintShown();
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

    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        final profiles = viewModel.profiles;
        final showHint = viewModel.showHint;

        // Auto-switch to manual if no profiles
        if (profiles.isEmpty && !_showManualLogin) {
          // We can't setState during build, but AnimatedLoginContent handles initial state via showManualForm param
          // If profiles is empty, showManualForm should be true based on logic
        }

        final effectiveShowManual = _showManualLogin || profiles.isEmpty;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            mini: true,
            backgroundColor: isDark ? Colors.grey[800] : Colors.black,
            onPressed: () => context.read<ThemeService>().toggleTheme(),
            child: Icon(
              context.watch<ThemeService>().mode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
            ),
          ),
          body: Stack(
            children: [
              // Main Content
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

                              AnimatedLoginContent(
                                key: _contentKey,
                                showManualForm: effectiveShowManual,
                                profiles: profiles,
                                showHint: showHint,
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

              // Overlay
              if (_showMenu)
                ProfileSelectionOverlay(
                  profiles: profiles,
                  hoveredIndex: _hoveredIndex,
                  vibrationController: _vibrationController,
                  buttonTopY: _buttonTopY,
                  swipeDelta: _swipeDelta,
                  onIsolationChanged: (isIsolated, index) {
                    setState(() {
                      _isIsolated = isIsolated;
                      if (!isIsolated) _swipeDelta = 0.0;
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
                    final p = profiles[index];
                    await viewModel.removeProfile(p['username']!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profil Silindi"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  onEdit: (index) {
                    final p = profiles[index];
                    setState(() {
                      _showMenu = false;
                      _showManualLogin = true;
                      _editingProfile = p;
                      _swipeDelta = 0.0;
                      _isIsolated = false;
                    });
                    viewModel.loadCaptcha();
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
      },
    );
  }
}
