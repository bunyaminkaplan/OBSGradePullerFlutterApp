/// Auth Remote DataSource - Data Layer
library;

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:html/parser.dart' show parse;

import '../../../../core/constants.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/utils/logger.dart';

/// OBS sistemi ile iletişim kuran DataSource
/// Web scraping ile login ve captcha işlemleri yapar
class AuthRemoteDataSource {
  final Dio _dio;
  final CookieJar _cookieJar;
  final Logger _logger;

  final Map<String, String> _hiddenInputs = {};
  String _baseUrl = UniversityConstants.ozalUrl;

  AuthRemoteDataSource(this._dio, this._cookieJar, [Logger? logger])
    : _logger = logger ?? const Logger(tag: 'AuthDS');

  /// URL değiştir (üniversite değişimi)
  void setBaseUrl(String url) => _baseUrl = url;

  /// Mevcut base URL
  String get baseUrl => _baseUrl;

  /// Hidden inputs (form state)
  Map<String, String> get hiddenInputs => _hiddenInputs;

  /// Login sayfasını ve captcha görselini çek
  Future<Uint8List?> fetchLoginPage({bool isRetry = false}) async {
    try {
      final loginUrl = '$_baseUrl${ApiConstants.loginEndpoint}';
      _logger.info('Login sayfası isteniyor (retry: $isRetry)');

      final response = await _dio.get(loginUrl);
      _logger.debug('Yanıt: ${response.statusCode}');

      _parseAndCacheHiddenInputs(response.data);

      final document = parse(response.data);
      final img = document.querySelector('#imgCaptchaImg');

      if (img != null) {
        final src = img.attributes['src'];

        if (src != null) {
          String fullUrl = '$_baseUrl${ApiConstants.captchaEndpoint}';
          if (!src.startsWith('..')) {
            fullUrl = '$_baseUrl/oibs/${src.replaceAll('../', '')}';
          }

          final imgResponse = await _dio.get<List<int>>(
            fullUrl,
            options: Options(responseType: ResponseType.bytes),
          );

          _logger.info('Captcha indirildi (${imgResponse.data?.length} bytes)');
          return Uint8List.fromList(imgResponse.data!);
        }
      }

      // Captcha bulunamadı - session bozulmuş olabilir
      if (!isRetry) {
        _logger.warning(
          'Captcha bulunamadı, cookie temizlenip yeniden deneniyor',
        );
        await _cookieJar.deleteAll();
        return fetchLoginPage(isRetry: true);
      }

      throw const ParseException(message: 'Captcha resmi bulunamadı');
    } catch (e) {
      if (e is AppException) rethrow;

      _logger.error('Login sayfası hatası: $e', error: e);
      throw ServerException(message: 'Login sayfası yüklenemedi: $e');
    }
  }

  /// Login işlemi
  Future<bool> login(String user, String pass, String captchaCode) async {
    if (_hiddenInputs.isEmpty) return false;

    try {
      final payload = Map<String, dynamic>.from(_hiddenInputs);
      payload['txtParamT01'] = user;
      payload['txtParamT02'] = pass;
      payload['txtParamT1'] = pass;
      payload['txtSecCode'] = captchaCode;
      payload['__EVENTTARGET'] = 'btnLogin';
      payload['__EVENTARGUMENT'] = '';
      payload['txt_scrWidth'] = '1920';
      payload['txt_scrHeight'] = '1080';
      payload.remove('btnLogin');

      final response = await _dio.post(
        '$_baseUrl${ApiConstants.loginEndpoint}',
        data: payload,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) => true,
        ),
      );

      _logger.info('Login yanıt kodu: ${response.statusCode}');

      if (response.statusCode == 302) {
        final location = response.headers.value('location');
        if (location != null) {
          final fullUrl = location.startsWith('http')
              ? location
              : _baseUrl + location;
          final nextResponse = await _dio.get(fullUrl);

          if (!nextResponse.realUri.toString().contains('login.aspx')) {
            _parseAndCacheHiddenInputs(nextResponse.data);
            return true;
          }
        }
      } else if (response.statusCode == 200) {
        if (!response.realUri.toString().contains('login.aspx')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      _logger.error('Login hatası: $e', error: e);
      throw ServerException(message: 'Giriş işlemi sırasında hata: $e');
    }
  }

  /// Çıkış işlemi
  Future<void> logout() async {
    await _cookieJar.deleteAll();
    _hiddenInputs.clear();
  }

  /// HTML'den hidden inputları çıkar ve cache'le
  void _parseAndCacheHiddenInputs(dynamic htmlContent) {
    final document = parse(htmlContent);
    _hiddenInputs.clear();

    for (final input in document.querySelectorAll('input[type="hidden"]')) {
      final name = input.attributes['name'];
      final value = input.attributes['value'];
      if (name != null) {
        _hiddenInputs[name] = value ?? '';
      }
    }

    _logger.debug('Hidden inputs: ${_hiddenInputs.length} adet');
  }
}
