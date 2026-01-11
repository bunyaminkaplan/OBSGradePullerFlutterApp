import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/presentation/painters/ripple_painter.dart';
import '../viewmodels/login_view_model.dart';

class EasterEggLogo extends StatefulWidget {
  const EasterEggLogo({super.key});

  @override
  State<EasterEggLogo> createState() => _EasterEggLogoState();
}

class _EasterEggLogoState extends State<EasterEggLogo>
    with SingleTickerProviderStateMixin {
  // Ticker for ripple animation
  late Ticker _ticker;
  final List<double> _ripples = [];
  final List<double> _intensities = []; // Intensity for each ripple
  Duration _lastElapsed = Duration.zero;
  static const Duration _rippleDuration = Duration(milliseconds: 2000);

  // Hold tracking for intensity calculation
  DateTime? _holdStartTime;
  Timer? _easterEggTimer;
  Timer? _intensityTimer;
  double _currentHoldIntensity = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final double dt =
        (elapsed - _lastElapsed).inMilliseconds /
        _rippleDuration.inMilliseconds;
    _lastElapsed = elapsed;

    setState(() {
      for (int i = 0; i < _ripples.length; i++) {
        _ripples[i] += dt;
      }
      // Remove completed ripples and their intensities
      while (_ripples.isNotEmpty && _ripples.first >= 1.0) {
        _ripples.removeAt(0);
        if (_intensities.isNotEmpty) _intensities.removeAt(0);
      }

      if (_ripples.isEmpty) {
        _ticker.stop();
        _lastElapsed = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _easterEggTimer?.cancel();
    _intensityTimer?.cancel();
    super.dispose();
  }

  void _handlePointerDown() {
    _holdStartTime = DateTime.now();
    _currentHoldIntensity = 0.0;

    // Add initial ripple with low intensity
    _addRipple(0.1);

    // Start intensity tracking - emit ripples at intervals with increasing intensity
    _intensityTimer?.cancel();
    _intensityTimer = Timer.periodic(const Duration(milliseconds: 400), (
      timer,
    ) {
      if (_holdStartTime == null) {
        timer.cancel();
        return;
      }

      final holdDuration = DateTime.now().difference(_holdStartTime!);
      // Intensity increases over 3 seconds (0 to 1)
      _currentHoldIntensity = (holdDuration.inMilliseconds / 3000).clamp(
        0.0,
        1.0,
      );

      // Add ripple with current intensity
      _addRipple(_currentHoldIntensity);
      HapticFeedback.selectionClick(); // Light haptic feedback
    });

    // Easter egg timer (5 seconds hold)
    _easterEggTimer?.cancel();
    _easterEggTimer = Timer(const Duration(seconds: 5), () async {
      // STOP creating new ripples - easter egg is triggered!
      _intensityTimer?.cancel();
      _holdStartTime = null; // Prevent further ripple creation

      final viewModel = context.read<LoginViewModel>();
      final uniName = await viewModel.toggleUniversity();
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎓 $uniName Moduna Geçildi"),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _addRipple(double intensity) {
    setState(() {
      _ripples.add(0.0);
      _intensities.add(intensity);
      if (!_ticker.isActive) {
        _lastElapsed = Duration.zero;
        _ticker.start();
      }
    });
  }

  void _handlePointerUp() {
    if (_holdStartTime != null) {
      final holdDuration = DateTime.now().difference(_holdStartTime!);
      // Final ripple with intensity based on total hold time
      final finalIntensity = (holdDuration.inMilliseconds / 2000).clamp(
        0.0,
        1.0,
      );
      _addRipple(finalIntensity);

      // Heavy haptic for long holds
      if (holdDuration.inSeconds >= 2) {
        HapticFeedback.mediumImpact();
      }
    }

    _holdStartTime = null;
    _intensityTimer?.cancel();
    _easterEggTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handlePointerDown(),
      onPointerUp: (_) => _handlePointerUp(),
      onPointerCancel: (_) => _handlePointerUp(),
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: RipplePainter(
                List.from(_ripples),
                Colors.blueAccent,
                List.from(_intensities),
              ),
              child: const SizedBox(width: 180, height: 180),
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
