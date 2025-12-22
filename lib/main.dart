import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

// Services
import 'services/captcha_service.dart';

import 'services/theme_service.dart';
import 'core/services/logger_service.dart';

// Data Layer
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/grades_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';

// Domain Layer
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/grades_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/get_captcha_usecase.dart';
import 'domain/usecases/auto_login_usecase.dart';
import 'domain/usecases/toggle_university_usecase.dart';
import 'domain/usecases/get_grades_usecase.dart';
import 'domain/usecases/get_grade_details_usecase.dart';
import 'services/storage_service.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/grades_repository_impl.dart';

// Presentation Layer
import 'viewmodels/login_view_model.dart';
import 'viewmodels/grades_view_model.dart';

import 'ui/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Core Dependencies (Singletons)
  final cookieJar = CookieJar(); // Shared CookieJar
  final dio = Dio();
  dio.options.followRedirects = true;
  dio.options.validateStatus = (status) => status != null && status < 500;
  dio.interceptors.add(CookieManager(cookieJar)); // Use shared instance

  // Custom headers default (Matching old ObsService exactly)
  const defaultBaseUrl = "https://obs.ozal.edu.tr";
  dio.options.headers['User-Agent'] =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  dio.options.headers['Referer'] = "$defaultBaseUrl/oibs/std/login.aspx";
  dio.options.headers['Origin'] = defaultBaseUrl;
  dio.options.headers['Cache-Control'] = 'no-cache';

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<CaptchaService>(create: (_) => CaptchaService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        Provider<LoggerService>(create: (_) => LoggerService()),

        // Data Sources
        Provider<AuthRemoteDataSource>(
          create: (context) => AuthRemoteDataSource(
            dio,
            cookieJar, // Injected CookieJar
            context.read<LoggerService>(),
          ),
        ),
        Provider<GradesRemoteDataSource>(
          create: (context) => GradesRemoteDataSource(
            dio,
            context.read<AuthRemoteDataSource>(),
            context.read<LoggerService>(),
          ),
        ),

        // Repositories
        ProxyProvider<AuthRemoteDataSource, AuthRepository>(
          update: (_, dataSource, __) => AuthRepositoryImpl(dataSource),
        ),
        ProxyProvider<GradesRemoteDataSource, IGradesRepository>(
          update: (_, dataSource, __) => GradesRepositoryImpl(dataSource),
        ),

        // UseCases
        ProxyProvider<AuthRepository, LoginUseCase>(
          update: (_, repo, __) => LoginUseCase(repo),
        ),
        ProxyProvider<AuthRepository, GetCaptchaUseCase>(
          update: (_, repo, __) => GetCaptchaUseCase(repo),
        ),
        ProxyProvider2<AuthRepository, CaptchaService, AutoLoginUseCase>(
          update: (context, repo, captchaService, __) => AutoLoginUseCase(
            repo,
            captchaService,
            context.read<LoggerService>(),
          ),
        ),

        // Settings & Storage
        Provider<StorageService>(create: (_) => StorageService()),
        ProxyProvider<StorageService, ISettingsRepository>(
          update: (_, storage, __) => SettingsRepositoryImpl(storage),
        ),
        ProxyProvider2<
          ISettingsRepository,
          AuthRepository,
          ToggleUniversityUseCase
        >(
          update: (_, settingsRepo, authRepo, __) =>
              ToggleUniversityUseCase(settingsRepo, authRepo),
        ),

        ProxyProvider<IGradesRepository, GetGradesUseCase>(
          update: (_, repo, __) => GetGradesUseCase(repo),
        ),
        ProxyProvider<IGradesRepository, GetGradeDetailsUseCase>(
          update: (_, repo, __) => GetGradeDetailsUseCase(repo),
        ),

        // ViewModels
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(
            loginUseCase: context.read<LoginUseCase>(),
            getCaptchaUseCase: context.read<GetCaptchaUseCase>(),
            autoLoginUseCase: context.read<AutoLoginUseCase>(),
            toggleUniversityUseCase: context.read<ToggleUniversityUseCase>(),
            captchaService: context.read<CaptchaService>(),
            logger: context.read<LoggerService>(),
          ),
        ),
        ChangeNotifierProvider<GradesViewModel>(
          create: (context) => GradesViewModel(
            getGradesUseCase: context.read<GetGradesUseCase>(),
            getGradeDetailsUseCase: context.read<GetGradeDetailsUseCase>(),
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
