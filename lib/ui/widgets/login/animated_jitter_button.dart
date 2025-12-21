import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedJitterButton extends StatefulWidget {
  final Widget child;
  const AnimatedJitterButton({super.key, required this.child});

  @override
  State<AnimatedJitterButton> createState() => _AnimatedJitterButtonState();
}

class _AnimatedJitterButtonState extends State<AnimatedJitterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (ctx, child) {
                double offX = (math.Random().nextDouble() - 0.5) * 2.0;
                double offY = (math.Random().nextDouble() - 0.5) * 2.0;
                return Transform.translate(
                  offset: Offset(offX, offY),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (ctx, child) {
                double skew = (math.Random().nextDouble() - 0.5) * 0.2;
                return Transform(
                  transform: Matrix4.skewX(skew),
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
