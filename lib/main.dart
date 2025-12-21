import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

// Services
import 'services/captcha_service.dart';
import 'services/obs_service.dart'; // Legacy, kept for non-refactored parts
import 'services/theme_service.dart';

// Data Layer
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/grades_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';

// Domain Layer
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/get_captcha_usecase.dart';
import 'domain/usecases/auto_login_usecase.dart';

// Presentation Layer
import 'viewmodels/login_view_model.dart';
import 'ui/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Core Dependencies (Singletons)
  final cookieJar = CookieJar(); // Shared CookieJar
  final dio = Dio();
  dio.options.followRedirects = true;
  dio.options.validateStatus = (status) => status != null && status < 500;
  dio.interceptors.add(CookieManager(cookieJar)); // Use shared instance

  // Custom headers default
  dio.options.headers['User-Agent'] =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<CaptchaService>(create: (_) => CaptchaService()),
        Provider<ObsService>(
          create: (_) => ObsService(dio),
        ), // Legacy Service with Shared Session
        ChangeNotifierProvider(create: (_) => ThemeService()),

        // Data Sources
        Provider<AuthRemoteDataSource>(
          create: (context) => AuthRemoteDataSource(
            dio,
            cookieJar, // Injected CookieJar
          ),
        ),
        Provider<GradesRemoteDataSource>(
          create: (_) => GradesRemoteDataSource(dio),
        ),

        // Repositories
        ProxyProvider<AuthRemoteDataSource, AuthRepository>(
          update: (_, dataSource, __) => AuthRepositoryImpl(dataSource),
        ),

        // UseCases
        ProxyProvider<AuthRepository, LoginUseCase>(
          update: (_, repo, __) => LoginUseCase(repo),
        ),
        ProxyProvider<AuthRepository, GetCaptchaUseCase>(
          update: (_, repo, __) => GetCaptchaUseCase(repo),
        ),
        ProxyProvider2<AuthRepository, CaptchaService, AutoLoginUseCase>(
          update: (_, repo, captchaService, __) =>
              AutoLoginUseCase(repo, captchaService),
        ),

        // ViewModels
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(
            loginUseCase: context.read<LoginUseCase>(),
            getCaptchaUseCase: context.read<GetCaptchaUseCase>(),
            autoLoginUseCase: context.read<AutoLoginUseCase>(),
            captchaService: context.read<CaptchaService>(),
          ),
        ),
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
      home: const LoginScreen(),
    );
  }
}
