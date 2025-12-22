import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../painters/ripple_painter.dart'; // Fixed import path
import '../../../viewmodels/login_view_model.dart';

class EasterEggLogo extends StatefulWidget {
  const EasterEggLogo({super.key});

  @override
  State<EasterEggLogo> createState() => _EasterEggLogoState();
}

class _EasterEggLogoState extends State<EasterEggLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  Timer? _easterEggTimer;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _easterEggTimer?.cancel();
    super.dispose();
  }

  void _handlePointerDown() {
    _easterEggTimer?.cancel();
    _easterEggTimer = Timer(const Duration(seconds: 5), () async {
      final viewModel = context.read<LoginViewModel>();
      final uniName = await viewModel.toggleUniversity();
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$uniName Moduna Geçildi"),
            backgroundColor: Colors.blueAccent,
          ),
        );
        // context.read<LoginViewModel>().loadCaptcha(); // Done in toggleUniversity
      }
    });
  }

  void _cancelTimer() => _easterEggTimer?.cancel();

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handlePointerDown(),
      onPointerUp: (_) => _cancelTimer(),
      onPointerCancel: (_) => _cancelTimer(),
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _rippleController,
              builder: (ctx, child) => CustomPaint(
                painter: RipplePainter(
                  _rippleController.value,
                  Colors.blueAccent,
                ),
                child: Container(width: 180, height: 180),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 64,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
