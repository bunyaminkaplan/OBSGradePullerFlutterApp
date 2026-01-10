import 'dart:ui';
import 'package:flutter/material.dart';

/// Modern giriş loading overlay'i
/// Giriş işlemi sırasında tüm ekranı kaplar ve blur efekti ile gösterilir
/// [username] ve [alias] kullanıcı bilgisini gösterir
class LoginLoadingOverlay extends StatelessWidget {
  /// Kullanıcı numarası (öğrenci no)
  final String? username;

  /// Kullanıcı takma adı (varsa)
  final String? alias;

  /// Overlay görünür mü?
  final bool isVisible;

  const LoginLoadingOverlay({
    super.key,
    this.username,
    this.alias,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Container(
          color: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isVisible ? 8.0 : 0.0,
              sigmaY: isVisible ? 8.0 : 0.0,
            ),
            child: Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Loading Spinner Container
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "Giriş yapılıyor..." text
                    Text(
                      "Giriş yapılıyor...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // User info
                    if (alias != null || username != null) ...[
                      // Alias (büyük)
                      if (alias != null && alias!.isNotEmpty)
                        Text(
                          alias!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),

                      // Username (küçük, soluk)
                      if (username != null && username!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            username!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
