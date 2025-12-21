import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:html/parser.dart' show parse;
import '../../core/constants.dart';
import '../../core/exceptions/server_exception.dart';

/// ---------------------------------------------------------------------------
/// AUTH REMOTE DATA SOURCE
/// ---------------------------------------------------------------------------
class AuthRemoteDataSource {
  final Dio _dio;
  final CookieJar _cookieJar;

  final Map<String, String> _hiddenInputs = {};
  String _baseUrl = "https://obs.ozal.edu.tr";

  AuthRemoteDataSource(this._dio, this._cookieJar);

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  String get baseUrl => _baseUrl;
  Map<String, String> get hiddenInputs => _hiddenInputs;

  /// 1. Login Sayfasını ve Captcha'yı Getir
  Future<Uint8List?> fetchLoginPage({bool isRetry = false}) async {
    try {
      String loginUrl = "$_baseUrl${AppConstants.loginEndpoint}";
      print(
        "MİMARİ LOG: Login Sayfası İsteniyor (Retry: $isRetry) -> $loginUrl",
      );

      Response response = await _dio.get(loginUrl);
      print(
        "MİMARİ LOG: Sayfa Yanıtı: ${response.statusCode} (Length: ${response.data.length})",
      );

      _parseAndCacheHiddenInputs(response.data);
      print("MİMARİ LOG: Hidden Inputs Sayısı: ${_hiddenInputs.length}");

      var document = parse(response.data);
      var img = document.querySelector('#imgCaptchaImg');

      if (img != null) {
        String? src = img.attributes['src'];
        print("MİMARİ LOG: Captcha Resim Src: $src");

        if (src != null) {
          String fullUrl = "$_baseUrl/oibs/captcha/CaptchaImg.aspx";
          if (!src.startsWith("..")) {
            fullUrl = "$_baseUrl/oibs/" + src.replaceAll("../", "");
          }
          print("MİMARİ LOG: Captcha Full URL: $fullUrl");

          Response<List<int>> imgResponse = await _dio.get<List<int>>(
            fullUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          print(
            "MİMARİ LOG: Captcha İndirildi (${imgResponse.data?.length} bytes)",
          );

          return Uint8List.fromList(imgResponse.data!);
        }
      } else {
        print("MİMARİ LOG: HATA - #imgCaptchaImg bulunamadı!");

        // Critical Fix: Session stuck on Error Page logic
        if (!isRetry) {
          print(
            "MİMARİ LOG: ⚠️ Session bozulmuş olabilir. Cookie temizlenip tekrar deneniyor...",
          );
          await _cookieJar.deleteAll();
          return await fetchLoginPage(isRetry: true);
        } else {
          throw ServerException(
            message:
                "Captcha resmi bulunamadı. Sayfa yapısı değişmiş olabilir.",
          );
        }
      }
    } catch (e) {
      print("Kritik Hata (FetchLogin): $e");
      throw ServerException(
        message: "Login sayfası yüklenirken hata oluştu: $e",
      );
    }
    throw ServerException(message: "Login sayfası alınamadı (Bilinmeyen Hata)");
  }

  /// 2. Login İşlemi
  Future<bool> login(String user, String pass, String captchaCode) async {
    if (_hiddenInputs.isEmpty) return false;

    try {
      Map<String, dynamic> payload = Map.from(_hiddenInputs);
      payload['txtParamT01'] = user;
      payload['txtParamT02'] = pass;
      payload['txtParamT1'] = pass;
      payload['txtSecCode'] = captchaCode;

      payload['__EVENTTARGET'] = 'btnLogin';
      payload['__EVENTARGUMENT'] = '';
      payload['txt_scrWidth'] = '1920';
      payload['txt_scrHeight'] = '1080';
      payload.remove('btnLogin');

      Response response = await _dio.post(
        "$_baseUrl${AppConstants.loginEndpoint}",
        data: FormData.fromMap(payload),
        options: Options(
          followRedirects: false,
          validateStatus: (status) => true,
        ),
      );

      print("Login Yanıt Kodu: ${response.statusCode}");

      if (response.statusCode == 302) {
        String? location = response.headers.value('location');
        if (location != null) {
          String fullUrl = location.startsWith("http")
              ? location
              : _baseUrl + location;
          Response nextResponse = await _dio.get(fullUrl);

          if (!nextResponse.realUri.toString().contains("login.aspx")) {
            _parseAndCacheHiddenInputs(nextResponse.data);
            return true;
          }
        }
      } else if (response.statusCode == 200) {
        if (!response.realUri.toString().contains("login.aspx")) return true;
      }

      return false;
    } catch (e) {
      print("Login Exception: $e");
      throw ServerException(message: "Giriş işlemi sırasında hata: $e");
    }
  }

  void _parseAndCacheHiddenInputs(dynamic htmlContent) {
    var document = parse(htmlContent);
    _hiddenInputs.clear();
    var inputs = document.querySelectorAll('input[type="hidden"]');
    for (var input in inputs) {
      var name = input.attributes['name'];
      var value = input.attributes['value'];
      if (name != null) _hiddenInputs[name] = value ?? "";
    }
  }

  Future<void> logout() async {
    // Basic logout logic handled by clearing cookies where needed or relying on session expiry
    await _cookieJar.deleteAll();
  }
}
