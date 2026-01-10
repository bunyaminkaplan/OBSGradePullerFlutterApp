import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import 'core/services/logger_service.dart';
import 'core/services/theme_service.dart';
import 'infrastructure/storage/secure_storage_service.dart';

// Presentation
import 'features/auth/presentation/viewmodels/login_view_model.dart';
import 'features/grades/presentation/viewmodels/grades_view_model.dart';
import 'features/settings/presentation/viewmodels/settings_view_model.dart';
import 'features/auth/presentation/pages/login_page.dart';

// Infrastructure
import 'infrastructure/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection
  await di.init();

  // Kaydedilmiş tema modunu yükle
  await di.sl<ThemeService>().loadSavedTheme();

  runApp(
    MultiProvider(
      providers: [
        // ViewModels (State Management)
        // Note: Dependencies are injected via GetIt (di.sl())
        ChangeNotifierProvider(create: (_) => di.sl<LoginViewModel>()),
        ChangeNotifierProvider(create: (_) => di.sl<GradesViewModel>()),
        ChangeNotifierProvider(create: (_) => di.sl<SettingsViewModel>()),

        // UI Services (Theme)
        ChangeNotifierProvider(create: (_) => di.sl<ThemeService>()),

        // Logger Service needed for provider access in some widgets if direct usage exists
        // (Though direct usage via di.sl<LoggerService>() is preferred in non-widget classes)
        Provider(create: (_) => di.sl<LoggerService>()),
        Provider(
          create: (_) => di.sl<SecureStorageService>(),
        ), // For any direct UI access if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'OBS Grade Puller',
      debugShowCheckedModeBanner: false,
      themeMode: themeService.mode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const LoginPage(),
    );
  }
}
