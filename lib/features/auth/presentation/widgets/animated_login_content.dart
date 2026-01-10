import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_view_model.dart';
import 'login_manual_form.dart';
import 'profile_selection_widget.dart';

/// Animasyonlu içerik geçişi widget'ı.
/// ProfileTriggerButton ve LoginManualForm arasında yumuşak geçiş sağlar.
/// Stack yerine AnimatedSize kullanarak boyut sorunlarını önler.
class AnimatedLoginContent extends StatefulWidget {
  final bool showManualForm;
  final List<Map<String, String>> profiles;
  final bool showHint;
  final bool isLoadingProfiles; // Profiller yüklenirken true
  final String? editingUsername;
  final String? editingPassword;

  final VoidCallback onManualLoginRequested;
  final VoidCallback onCancelRequested;
  final VoidCallback onShowMenu;
  final ValueChanged<int> onHoverIndexChanged;
  final ValueChanged<int> onSelectionConfirmed;
  final bool isIsolated; // For swipe tracking
  final Function(double)? onSwipeDelta; // Swipe delta callback

  const AnimatedLoginContent({
    super.key,
    required this.showManualForm,
    required this.profiles,
    required this.showHint,
    this.isLoadingProfiles = true,
    this.editingUsername,
    this.editingPassword,
    required this.onManualLoginRequested,
    required this.onCancelRequested,
    required this.onShowMenu,
    required this.onHoverIndexChanged,
    required this.onSelectionConfirmed,
    this.isIsolated = false,
    this.onSwipeDelta,
  });

  @override
  State<AnimatedLoginContent> createState() => _AnimatedLoginContentState();
}

class _AnimatedLoginContentState extends State<AnimatedLoginContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeOut;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideOut;
  late Animation<Offset> _slideIn;
  bool _isFirstBuild = true; // Skip animation on initial render

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Profile fades out and slides up
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.3))
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
          ),
        );

    // Form fades in and slides up from below
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

    // Sync with initial state (no animation on first build)
    if (widget.showManualForm) {
      _controller.value = 1.0;
    }
    // Mark first build is done after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isFirstBuild = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedLoginContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showManualForm != oldWidget.showManualForm) {
      if (widget.showManualForm) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasProfiles = widget.profiles.isNotEmpty;

    // On first build, show content immediately without animation
    // Profiller yüklenirken loading göster (flash sorunu çözümü)
    if (_isFirstBuild && !widget.showManualForm) {
      if (widget.isLoadingProfiles) {
        // Profiller yüklenene kadar loading indicator
        return const SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      return hasProfiles
          ? ProfileTriggerButton(
              onShowMenu: widget.onShowMenu,
              onManualLogin: () {
                widget.onManualLoginRequested();
                context.read<LoginViewModel>().loadCaptcha();
              },
              onHoverIndexChanged: widget.onHoverIndexChanged,
              onSelectionConfirmed: widget.onSelectionConfirmed,
              showHint: widget.showHint,
              profiles: widget.profiles,
              isIsolated: widget.isIsolated,
              onSwipeDelta: widget.onSwipeDelta,
            )
          : const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Decide which widget to show based on animation progress
          final showingForm = _controller.value > 0.5;

          if (showingForm) {
            // Show Manual Form
            return FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: LoginManualForm(
                  showCancelButton: hasProfiles,
                  initialUsername: widget.editingUsername,
                  initialPassword: widget.editingPassword,
                  onCancel: widget.onCancelRequested,
                ),
              ),
            );
          } else {
            // Show Profile Trigger Button
            return FadeTransition(
              opacity: _fadeOut,
              child: SlideTransition(
                position: _slideOut,
                child: hasProfiles
                    ? ProfileTriggerButton(
                        onShowMenu: widget.onShowMenu,
                        onManualLogin: () {
                          widget.onManualLoginRequested();
                          context.read<LoginViewModel>().loadCaptcha();
                        },
                        onHoverIndexChanged: widget.onHoverIndexChanged,
                        onSelectionConfirmed: widget.onSelectionConfirmed,
                        showHint: widget.showHint,
                        profiles: widget.profiles,
                        isIsolated: widget.isIsolated,
                        onSwipeDelta: widget.onSwipeDelta,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
        },
      ),
    );
  }
}
