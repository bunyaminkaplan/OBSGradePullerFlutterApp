import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/login/animated_jitter_button.dart';

class ProfileTriggerButton extends StatefulWidget {
  final VoidCallback onShowMenu;
  final VoidCallback onManualLogin;
  final Function(int) onHoverIndexChanged; // For haptic feedback logic
  final Function(int) onSelectionConfirmed; // Returns index
  final bool showHint;
  final List<Map<String, String>> profiles;
  final bool isIsolated; // Whether an item is currently isolated
  final Function(double)?
  onSwipeDelta; // Callback for swipe delta when isolated

  const ProfileTriggerButton({
    super.key,
    required this.onShowMenu,
    required this.onManualLogin,
    required this.onHoverIndexChanged,
    required this.onSelectionConfirmed,
    required this.showHint,
    required this.profiles,
    this.isIsolated = false,
    this.onSwipeDelta,
  });

  @override
  State<ProfileTriggerButton> createState() => _ProfileTriggerButtonState();
}

class _ProfileTriggerButtonState extends State<ProfileTriggerButton>
    with SingleTickerProviderStateMixin {
  // Swipe tracking
  double? _startX;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showHint)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Hesap seçmek için basılı tutun",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

        Listener(
          onPointerDown: (event) {
            _startX = event.position.dx; // Store initial X for swipe tracking
            widget.onShowMenu();
          },
          onPointerMove: (event) {
            // If isolated, track horizontal swipe
            if (widget.isIsolated && _startX != null) {
              final delta = event.position.dx - _startX!;
              widget.onSwipeDelta?.call(delta);
              return; // Don't update hover index when isolated
            }

            // Normal hover tracking
            final RenderBox? box = context.findRenderObject() as RenderBox?;
            if (box == null) return;

            final buttonPosition = box.localToGlobal(Offset.zero);
            final buttonTopY = buttonPosition.dy;
            final menuHeight = widget.profiles.length * 70.0;

            final menuTop = buttonTopY - menuHeight - 24;

            double localY = event.position.dy - menuTop;
            int idx = (localY / 70.0).floor();
            widget.onHoverIndexChanged(idx);
          },
          onPointerUp: (_) {
            _startX = null;
            widget.onSelectionConfirmed(-1);
          },
          onPointerCancel: (_) {
            _startX = null;
            widget.onSelectionConfirmed(-2);
          },

          child: AnimatedJitterButton(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.people_alt_rounded, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text(
                  "Kayıtlı Kullanıcılar",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),
        TextButton.icon(
          onPressed: widget.onManualLogin,
          icon: const Icon(Icons.person_add),
          label: const Text("Farklı Hesapla Giriş"),
        ),
      ],
    );
  }
}

class ProfileSelectionOverlay extends StatefulWidget {
  final List<Map<String, String>> profiles;
  final int? hoveredIndex;
  final AnimationController vibrationController;
  final Function(int) onProfileSelected; // Callback for tap
  final Function(int) onDelete;
  final Function(int) onEdit;
  final double buttonTopY; // Y position of trigger button for alignment
  final double swipeDelta; // Horizontal swipe delta from parent
  final VoidCallback onSwipeActionComplete; // Called after swipe action
  final Function(bool, int?)
  onIsolationChanged; // Notifies parent of isolation state

  const ProfileSelectionOverlay({
    super.key,
    required this.profiles,
    required this.hoveredIndex,
    required this.vibrationController,
    required this.onProfileSelected,
    required this.onDelete,
    required this.onEdit,
    required this.buttonTopY,
    this.swipeDelta = 0.0,
    required this.onSwipeActionComplete,
    required this.onIsolationChanged,
  });

  @override
  State<ProfileSelectionOverlay> createState() =>
      _ProfileSelectionOverlayState();
}

class _ProfileSelectionOverlayState extends State<ProfileSelectionOverlay> {
  // NEW: Hover-based isolation state
  int? _isolatedIndex; // Currently isolated item index
  Timer? _isolationTimer; // 2s hover timer
  int? _lastHoveredIndex; // Track previous hover for comparison
  double _swipeOffset = 0.0; // Horizontal swipe offset for isolated item
  bool _actionTriggered = false; // Prevent multiple action triggers

  static const double _swipeThreshold = 100.0; // Swipe threshold in pixels

  @override
  void didUpdateWidget(covariant ProfileSelectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Process swipe delta when in isolation mode
    if (_isolatedIndex != null && !_actionTriggered) {
      if (widget.swipeDelta != oldWidget.swipeDelta) {
        setState(() {
          // Damped swipe: lerp instead of direct follow (0.2 = slow, 1.0 = instant)
          _swipeOffset = lerpDouble(_swipeOffset, widget.swipeDelta, 0.2)!;
        });

        // Check if threshold exceeded
        if (widget.swipeDelta.abs() >= _swipeThreshold) {
          _actionTriggered = true;
          HapticFeedback.heavyImpact();

          if (widget.swipeDelta < 0) {
            // Left swipe -> Delete
            widget.onDelete(_isolatedIndex!);
          } else {
            // Right swipe -> Edit
            widget.onEdit(_isolatedIndex!);
          }
          widget.onSwipeActionComplete();
        }
      }
    }

    // Check if hoveredIndex changed
    if (widget.hoveredIndex != _lastHoveredIndex) {
      _lastHoveredIndex = widget.hoveredIndex;

      // Cancel existing timer
      _isolationTimer?.cancel();

      // If we're already isolated, exit isolation when hover changes
      if (_isolatedIndex != null && widget.hoveredIndex != _isolatedIndex) {
        widget.onIsolationChanged(false, null);
        setState(() {
          _isolatedIndex = null;
          _swipeOffset = 0.0;
          _actionTriggered = false;
        });
      }

      // Start new timer only if hovering a valid index and not already isolated
      if (widget.hoveredIndex != null &&
          widget.hoveredIndex! >= 0 &&
          widget.hoveredIndex! < widget.profiles.length &&
          _isolatedIndex == null) {
        _isolationTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && widget.hoveredIndex == _lastHoveredIndex) {
            setState(() {
              _isolatedIndex = widget.hoveredIndex;
              _actionTriggered = false;
            });
            widget.onIsolationChanged(true, _isolatedIndex);
            HapticFeedback.heavyImpact();
          }
        });
      }
    }
  }

  void _exitIsolation() {
    _isolationTimer?.cancel();
    setState(() {
      _isolatedIndex = null;
      _swipeOffset = 0.0;
      _actionTriggered = false;
    });
  }

  @override
  void dispose() {
    _isolationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Position menu so its bottom aligns with button top
    final bottomPadding = screenHeight - widget.buttonTopY;

    // Dynamic blur based on isolation state
    final targetBlur = _isolatedIndex != null ? 12.0 : 5.0;

    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_isolatedIndex != null),
        tween: Tween<double>(begin: 0.0, end: targetBlur),
        duration: const Duration(milliseconds: 200),
        builder: (context, sigma, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Container(
              color: Colors.black.withValues(alpha: sigma / 12 * 0.4),
              alignment: _isolatedIndex != null
                  ? Alignment
                        .center // Center when isolated
                  : Alignment.bottomCenter,
              padding: _isolatedIndex != null
                  ? EdgeInsets.zero
                  : EdgeInsets.only(bottom: bottomPadding),
              child: _isolatedIndex != null
                  ? _buildIsolatedItemView(context)
                  : _buildLinearMenuVisual(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIsolatedItemView(BuildContext context) {
    final p = widget.profiles[_isolatedIndex!];

    // Determine card color based on swipe direction
    Color cardColor;
    Color borderColor;
    if (_swipeOffset < -50) {
      cardColor = Colors.red.withValues(alpha: 0.2);
      borderColor = Colors.red;
    } else if (_swipeOffset > 50) {
      cardColor = Colors.green.withValues(alpha: 0.2);
      borderColor = Colors.green;
    } else {
      cardColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]!
          : Colors.white;
      borderColor = Colors.orange;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swipe direction indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_ios,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'Sil',
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 40),
            Text(
              'Düzenle',
              style: TextStyle(
                color: Colors.green.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.green.withValues(alpha: 0.7),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Isolated item card with swipe animation
        Transform.translate(
          offset: Offset(_swipeOffset, 0),
          child: Transform.scale(
            scale: 1.1,
            child: Container(
              width: 300,
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      p['alias']!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['alias']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          p['username']!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.swipe, color: Colors.orange),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Hint text
        Text(
          'Parmağınızı kaldırın veya sağa/sola kaydırın',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLinearMenuVisual(BuildContext context) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 400),
      // Use Clip.none to allow overflow if needed, but here we contain it.
      // Overflow issue mentioned might be due to vibration shifting out of bounds.
      // Adding padding ensures vibration doesn't clip.
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]!.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.profiles.length, (index) {
            bool isHovered = (widget.hoveredIndex == index);
            bool isIsolated = (_isolatedIndex == index);
            final p = widget.profiles[index];

            Widget content = AnimatedBuilder(
              animation: widget.vibrationController,
              builder: (ctx, child) {
                double offset =
                    widget.vibrationController.value * (isHovered ? 2.0 : 0.3);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: TweenAnimationBuilder<double>(
                key: ValueKey('hover_$index\_$isHovered'),
                tween: Tween<double>(begin: 0.0, end: isHovered ? 1.0 : 0.0),
                duration: isHovered
                    ? const Duration(seconds: 3) // Slow build-up during hover
                    : const Duration(milliseconds: 200), // Fast reset
                curve: Curves.easeInOut,
                builder: (context, hoverProgress, child) {
                  // Gradient colors based on hover progress
                  // 0.0 = transparent, 1.0 = red-green gradient hint
                  final leftColor = Color.lerp(
                    Colors.transparent,
                    Colors.red.withValues(alpha: 0.15),
                    hoverProgress,
                  )!;
                  final rightColor = Color.lerp(
                    Colors.transparent,
                    Colors.green.withValues(alpha: 0.15),
                    hoverProgress,
                  )!;

                  return Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: isHovered && hoverProgress > 0.1
                          ? LinearGradient(
                              colors: [leftColor, rightColor],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: isIsolated
                          ? Colors.orange.withValues(alpha: 0.15)
                          : (!isHovered ? Colors.transparent : null),
                      border: index < widget.profiles.length - 1
                          ? Border(
                              bottom: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            )
                          : null,
                    ),
                    child: child,
                  );
                },
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          child: Text(
                            p['alias']!.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        if (isIsolated)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_open,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['alias']!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            p['username']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isHovered && !isIsolated)
                      const Icon(Icons.check_circle, color: Colors.blueAccent),
                    if (isIsolated)
                      const Icon(Icons.swipe, color: Colors.orangeAccent),
                  ],
                ),
              ),
            );

            // Faz 1: Just return content, no GestureDetector/Dismissible yet
            return content;
          }),
        ),
      ),
    );
  }
}
