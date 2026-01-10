import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:get_it/get_it.dart';

// Core
import '../../core/services/logger_service.dart';
import '../../core/services/theme_service.dart';

// Features - Auth
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_captcha_usecase.dart';
import '../../features/auth/domain/usecases/auto_login_usecase.dart';
import '../../features/auth/presentation/viewmodels/login_view_model.dart';

// Features - Grades
import '../../features/grades/data/datasources/grades_remote_data_source.dart';
import '../../features/grades/data/repositories/grades_repository_impl.dart';
import '../../features/grades/domain/repositories/grades_repository.dart';
import '../../features/grades/domain/usecases/get_grades_usecase.dart';
import '../../features/grades/domain/usecases/get_grade_details_usecase.dart';
import '../../features/grades/presentation/viewmodels/grades_view_model.dart';

// Features - Settings & Common
import '../../infrastructure/storage/secure_storage_service.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/toggle_university_usecase.dart';
import '../../features/captcha/data/services/tflite_captcha_solver.dart';
import '../../features/captcha/domain/services/captcha_solver.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // ViewModel
  sl.registerFactory(
    () => LoginViewModel(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCaptchaUseCase: sl(),
      autoLoginUseCase: sl(),
      toggleUniversityUseCase: sl(),
      captchaService: sl(),
      storageService: sl(),
      logger: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCaptchaUseCase(sl()));
  sl.registerLazySingleton(() => AutoLoginUseCase(sl(), sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // Data Sources
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl(), sl(), sl()));

  //! Features - Grades
  // ViewModel
  sl.registerFactory(
    () => GradesViewModel(getGradesUseCase: sl(), getGradeDetailsUseCase: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetGradesUseCase(sl()));
  sl.registerLazySingleton(() => GetGradeDetailsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<GradesRepository>(() => GradesRepositoryImpl(sl()));

  // Data Sources
  sl.registerLazySingleton(() => GradesRemoteDataSource(sl(), sl(), sl()));

  //! Features - Settings
  // Use Cases
  sl.registerLazySingleton(() => ToggleUniversityUseCase(sl(), sl()));

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );

  // Data Source (Storage)
  sl.registerLazySingleton(() => SecureStorageService(null, sl()));

  //! Features - Captcha
  sl.registerLazySingleton<CaptchaSolver>(() => TFLiteCaptchaSolver(sl()));

  //! Core
  sl.registerLazySingleton(() => LoggerService());
  sl.registerLazySingleton(() => ThemeService());

  //! External
  sl.registerLazySingleton(() => CookieJar());
  sl.registerLazySingleton(() {
    final dio = Dio();
    dio.options.followRedirects = true;
    dio.options.validateStatus = (status) => status != null && status < 500;

    // Cookie Management
    dio.interceptors.add(CookieManager(sl<CookieJar>()));

    // Default Headers
    const defaultBaseUrl = "https://obs.ozal.edu.tr";
    dio.options.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    dio.options.headers['Referer'] = "$defaultBaseUrl/oibs/std/login.aspx";
    dio.options.headers['Origin'] = defaultBaseUrl;
    dio.options.headers['Cache-Control'] = 'no-cache';

    return dio;
  });
}
