import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/login/animated_jitter_button.dart';

class ProfileTriggerButton extends StatefulWidget {
  final VoidCallback onShowMenu;
  final VoidCallback onManualLogin;
  final Function(int) onHoverIndexChanged; // For haptic feedback logic
  final Function(int) onSelectionConfirmed; // Returns index
  final bool showHint;
  final List<Map<String, String>> profiles;

  const ProfileTriggerButton({
    super.key,
    required this.onShowMenu,
    required this.onManualLogin,
    required this.onHoverIndexChanged,
    required this.onSelectionConfirmed,
    required this.showHint,
    required this.profiles,
  });

  @override
  State<ProfileTriggerButton> createState() => _ProfileTriggerButtonState();
}

class _ProfileTriggerButtonState extends State<ProfileTriggerButton>
    with SingleTickerProviderStateMixin {
  // Vibration logic moved here or kept in parent?
  // Parent needs to coordinate vibration with overlay, so keeping simple.
  // Actually, gesture detector logic is complex here.

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
          onPointerDown: (_) => widget.onShowMenu(),
          onPointerMove: (event) {
            final screenHeight = MediaQuery.of(context).size.height;
            final menuHeight = widget.profiles.length * 70.0;
            final menuTop = (screenHeight - menuHeight) / 2;
            double localY = event.position.dy - menuTop;
            int idx = (localY / 70.0).floor();
            widget.onHoverIndexChanged(idx);
          },
          onPointerUp: (_) => widget.onSelectionConfirmed(
            -1,
          ), // -1 means logic handled by parent state check
          onPointerCancel: (_) => widget.onSelectionConfirmed(-2), // Cancel

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

class ProfileSelectionOverlay extends StatelessWidget {
  final List<Map<String, String>> profiles;
  final int? hoveredIndex;
  final AnimationController vibrationController;

  const ProfileSelectionOverlay({
    super.key,
    required this.profiles,
    required this.hoveredIndex,
    required this.vibrationController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 5.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, sigma, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Container(
              color: Colors.black12.withValues(alpha: sigma / 5 * 0.12),
              alignment: Alignment.center,
              child: _buildLinearMenuVisual(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLinearMenuVisual(BuildContext context) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]!.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(profiles.length, (index) {
          bool isHovered = (hoveredIndex == index);
          final p = profiles[index];
          return AnimatedBuilder(
            animation: vibrationController,
            builder: (ctx, child) {
              double offset =
                  vibrationController.value * (isHovered ? 2.0 : 0.3);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isHovered
                    ? Colors.blueAccent.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: index < profiles.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(p['alias']!.substring(0, 1).toUpperCase()),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['alias']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        p['username']!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (isHovered)
                    const Icon(Icons.check_circle, color: Colors.blueAccent),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
