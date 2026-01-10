import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import '../../features/grades/domain/entities/grade.dart';
import '../../core/services/logger_service.dart';
import 'auth_remote_data_source.dart'; // For baseUrl sync

/// ---------------------------------------------------------------------------
/// GRADES REMOTE DATA SOURCE
/// ---------------------------------------------------------------------------
/// Bu sınıf, notları çekme ve dönem değiştirme işlemlerini yönetir.
/// 'AuthRemoteDataSource' ile aynı 'Dio' instance'ını (ve CookieJar'ı)
/// paylaşmak zorundadır, yoksa oturum bilgisi kaybolur.
/// ---------------------------------------------------------------------------
class GradesRemoteDataSource {
  final Dio _dio;
  final LoggerService _logger;
  final AuthRemoteDataSource _authDataSource; // For baseUrl sync

  // ViewState paylaşımı için Auth kaynağına erişim gerekebilir veya
  // Dio cookie'leri yönettiği için sadece URL ve Input bilgisi yeterlidir.
  // Inputlar sayfadan sayfaya değişir, o yüzden her istekte yeniden parse edilir.
  Map<String, String> _hiddenInputs = {};

  // Use AuthRemoteDataSource's baseUrl for consistency
  String get _baseUrl => _authDataSource.baseUrl;

  GradesRemoteDataSource(
    this._dio,
    this._authDataSource, [
    LoggerService? logger,
  ]) : _logger = logger ?? LoggerService();

  void setBaseUrl(String url) {
    // Deprecated - now synced with AuthRemoteDataSource
    // Kept for compatibility but does nothing
  }

  // AuthDataSource'dan gelen hidden inputları alabiliriz (Opsiyonel Optimization)
  void updateHiddenInputs(Map<String, String> inputs) {
    _hiddenInputs.addAll(inputs);
  }

  /// Notları ve Dönemleri Çek
  Future<Map<String, dynamic>> fetchGrades({String? termId}) async {
    try {
      String gradesUrl = "$_baseUrl/oibs/std/not_listesi_op.aspx";

      // Referer Header set et (ASP.NET bazen kontrol eder)
      _dio.options.headers['Referer'] = gradesUrl;

      // 1. Sayfayı GET ile çek
      Response response = await _dio.get(
        gradesUrl,
        options: Options(responseType: ResponseType.plain),
      );

      _parseHiddenInputs(response.data);
      var document = parse(response.data);

      // 🔄 CHECK FOR REDIRECT PAGE ("Yönlendirme Yapılıyor")
      // OBS shows an intermediate redirect page before the actual content
      // We may need to retry multiple times
      for (int retryCount = 0; retryCount < 3; retryCount++) {
        var title = document.querySelector('title');
        if (title != null && title.text.contains("Yönlendirme")) {
          _logger.warning(
            "Redirect page detected (Attempt ${retryCount + 1}/3), retrying...",
          );

          // Wait a bit (the page might set cookies) then re-request the same URL
          await Future.delayed(const Duration(milliseconds: 1000));

          response = await _dio.get(
            gradesUrl,
            options: Options(responseType: ResponseType.plain),
          );

          _parseHiddenInputs(response.data);
          document = parse(response.data);
        } else {
          // No redirect page, proceed
          break;
        }
      }

      // 🔄 CHECK FOR INTERMEDIATE FORM PAGE (btnKaydet)
      // OBS sometimes shows a "student info update" form that needs to be submitted first
      var btnKaydet = document.querySelector('#btnKaydet');
      if (btnKaydet != null) {
        _logger.warning(
          "Intermediate form detected, clicking btnKaydet to bypass...",
        );

        // Submit the form to bypass
        Map<String, dynamic> bypassPayload = Map.from(_hiddenInputs);
        bypassPayload['__EVENTTARGET'] = 'btnKaydet';
        bypassPayload['__EVENTARGUMENT'] = '';

        response = await _dio.post(
          gradesUrl, // Same URL or might redirect
          data: FormData.fromMap(bypassPayload),
          options: Options(responseType: ResponseType.plain),
        );

        // Re-parse the new page
        _parseHiddenInputs(response.data);
        document = parse(response.data);
        _logger.info("Bypassed intermediate form, re-checking page...");
      }

      // Dönem (Term) Kontrolü
      String currentTermId = "";
      var termSelect = document.querySelector('#cmbDonemler');
      List<Map<String, String>> terms = [];

      if (termSelect != null) {
        // Dropdown içindeki dönemleri oku
        for (var opt in termSelect.querySelectorAll('option')) {
          String val = opt.attributes['value'] ?? "";
          String text = opt.text.trim();
          if (val.isNotEmpty) {
            terms.add({'id': val, 'name': text});
            if (opt.attributes.containsKey('selected')) currentTermId = val;
          }
        }
      }

      // Varsayılan dönem
      if (currentTermId.isEmpty && terms.isNotEmpty) {
        currentTermId = terms.first['id']!;
      }

      // Eğer istenen dönem farklıysa, POST ile değiştir
      if (termId != null && termId.isNotEmpty && termId != currentTermId) {
        _logger.info("MİMARİ LOG: Dönem Değiştiriliyor -> $termId");

        Map<String, dynamic> payload = Map.from(_hiddenInputs);
        payload['__EVENTTARGET'] = 'cmbDonemler'; // Dropdown change event
        payload['__EVENTARGUMENT'] = '';
        payload['cmbDonemler'] = termId;

        // Dönem değişimi için POST at
        response = await _dio.post(
          gradesUrl,
          data: FormData.fromMap(payload),
          options: Options(responseType: ResponseType.plain),
        );

        // Yeni sayfa geldi, tekrar parse et
        _parseHiddenInputs(response.data);
        document = parse(response.data);
        currentTermId = termId;
      }

      // Not Tablosunu Parse Et
      var table = document.querySelector('#grd_not_listesi');
      List<Grade> grades = [];

      _logger.debug("Grades Table found: ${table != null}");
      _logger.debug(
        "Terms found: ${terms.length}, currentTermId: $currentTermId",
      );

      if (table != null) {
        var rows = table.querySelectorAll('tr');
        _logger.debug("Table rows: ${rows.length}");
        if (rows.length > 1) rows = rows.sublist(1); // Başlık satırını atla

        for (var row in rows) {
          var cells = row.querySelectorAll('td');
          if (cells.length < 7) continue;

          // HTML Hücrelerinden veriyi çek
          String courseCode = cells[1].text.trim();
          String courseName = cells[2].text.trim();
          String letterGrade = cells[6].text.trim();
          String detailsText = cells[4].text.trim();

          if (courseName.isEmpty) continue;

          // Vize/Final notlarını Regex ile ayıkla
          String midterm = "-", finalG = "-", resit = "-";

          RegExp vizeReg = RegExp(
            r"(?:Ara Sınav|Vize)\s*:\s*([\d\w-]+)",
            caseSensitive: false,
          );
          RegExp finalReg = RegExp(
            r"(?:Yarıyıl Sonu|Final)\s*:\s*([\d\w-]+)",
            caseSensitive: false,
          );
          RegExp butReg = RegExp(
            r"(?:Bütünleme|Büt)\s*:\s*([\d\w-]+)",
            caseSensitive: false,
          );

          var vMatch = vizeReg.firstMatch(detailsText);
          if (vMatch != null) midterm = vMatch.group(1) ?? "-";

          var fMatch = finalReg.firstMatch(detailsText);
          if (fMatch != null) finalG = fMatch.group(1) ?? "-";

          var bMatch = butReg.firstMatch(detailsText);
          if (bMatch != null) resit = bMatch.group(1) ?? "-";

          // İstatistik butonu var mı? (AJAX Target ID'sini al)
          String? statsTarget;
          var statsBtn = row.querySelector("a[id*='btnIstatistik']");
          if (statsBtn != null) {
            String? href = statsBtn.attributes['href'];
            if (href != null) {
              // __doPostBack('ctl00$ContentPlaceHolder1$grd_not_listesi$ctl02$btnIstatistik','')
              RegExp pbReg = RegExp(r"__doPostBack\('([^']*)'");
              var match = pbReg.firstMatch(href);
              if (match != null) statsTarget = match.group(1);
            }
          }

          grades.add(
            Grade(
              courseCode: courseCode,
              courseName: courseName,
              midterm: midterm,
              finalGrade: finalG,
              resit: resit,
              average: "",
              letterGrade: letterGrade,
              status: statsTarget ?? "", // İstatistik için hedef ID
              termId: currentTermId,
            ),
          );
          _logger.debug(
            "Parsed grade: $courseName, statsTarget: $statsTarget",
          ); // DEBUG LOG
        }
      }

      return {'grades': grades, 'terms': terms, 'currentTerm': currentTermId};
    } catch (e) {
      _logger.error("Not Çekme Hatası: $e", error: e);
      return {
        'grades': <Grade>[],
        'terms': <Map<String, String>>[],
        'currentTerm': '',
      };
    }
  }

  void _parseHiddenInputs(dynamic html) {
    var doc = parse(html);
    _hiddenInputs.clear();
    for (var inp in doc.querySelectorAll('input[type="hidden"]')) {
      var n = inp.attributes['name'];
      if (n != null) _hiddenInputs[n] = inp.attributes['value'] ?? "";
    }
  }

  /// 3b. Fetch Stats for a single Grade
  Future<Grade> fetchStatsForGrade(Grade grade) async {
    // Shimmer Fix: If no status (target), return with "-" averages so UI stops shimmering.
    if (grade.status.isEmpty || !grade.status.contains("btnIstatistik")) {
      _logger.warning(
        "Stats target empty or invalid for course: ${grade.courseName} (Status: ${grade.status})",
      );
      return Grade(
        courseCode: grade.courseCode,
        courseName: grade.courseName,
        midterm: grade.midterm,
        finalGrade: grade.finalGrade,
        resit: grade.resit,
        average: grade.average,
        letterGrade: grade.letterGrade,
        status: "",
        termId: grade.termId,
        midtermAvg: "-", // Mark as empty/done
        finalAvg: "-",
        resitAvg: "-",
      );
    }

    String target = grade.status;
    String termId = grade.termId;

    try {
      // 1. Trigger AJAX
      String gradesUrl = "$_baseUrl/oibs/std/not_listesi_op.aspx";

      // Update Inputs might be risky if we haven't visited the page recently
      // But assuming flow: Grades Screen Loaded -> User taps -> We have inputs.
      if (_hiddenInputs.isEmpty) {
        // Must fetch grades page first? For now assume it's there.
      }

      Map<String, dynamic> payload = Map.from(_hiddenInputs);
      payload['ScriptManager1'] = "UpdatePanel1|$target";
      payload['__EVENTTARGET'] = target;
      payload['__EVENTARGUMENT'] = '';
      payload['__ASYNCPOST'] = 'true';
      payload['cmbDonemler'] = termId;

      Map<String, dynamic> headers = Map.from(_dio.options.headers);
      headers['X-MicrosoftAjax'] = 'Delta=true';

      await _dio.post(
        gradesUrl,
        data: FormData.fromMap(payload),
        options: Options(headers: headers, responseType: ResponseType.plain),
      );

      // 2. Fetch Stats Page
      String statsUrl = "$_baseUrl/oibs/acd/new_not_giris_istatistik.aspx";
      Response statRes = await _dio.get(statsUrl);
      var soup = parse(statRes.data);
      var allRows = soup.querySelectorAll('tr');

      String? midtermAvg, finalAvg, resitAvg;
      String currentContext = ""; // Vize, Final, or But

      for (var row in allRows) {
        String t = row.text.trim();
        _logger.debug("Stats Row Text: $t"); // DEBUG LOG

        // Detect Context headers
        if (t.contains("Ara Sınav") || t.contains("Vize"))
          currentContext = "Vize";
        if (t.contains("Yarıyıl Sonu") || t.contains("Final"))
          currentContext = "Final";
        if (t.contains("Bütünleme") || t.contains("Büt"))
          currentContext = "Büt";

        // Check for Average Row
        if (t.toLowerCase().contains("not ortalaması")) {
          var cols = row.querySelectorAll('td');
          if (cols.length >= 2) {
            String val = cols[1].text.trim();
            _logger.debug("Found Avg: $val for $currentContext"); // DEBUG LOG
            if (val.isNotEmpty && val != "-") {
              if (currentContext == "Vize") midtermAvg = val;
              if (currentContext == "Final") finalAvg = val;
              if (currentContext == "Büt") resitAvg = val;
            }
          }
        }
      }

      return Grade(
        courseCode: grade.courseCode,
        courseName: grade.courseName,
        midterm: grade.midterm,
        finalGrade: grade.finalGrade,
        resit: grade.resit,
        average: grade.average,
        letterGrade: grade.letterGrade,
        status: "", // Clear the target
        midtermAvg: midtermAvg ?? "-",
        finalAvg: finalAvg ?? "-",
        resitAvg: resitAvg ?? "-",
        termId: termId,
      );
    } catch (e) {
      _logger.error("MİMARİ LOG: Stats Fetch Error: $e", error: e);
      // Return with "-" so it stops loading
      return Grade(
        courseCode: grade.courseCode,
        courseName: grade.courseName,
        midterm: grade.midterm,
        finalGrade: grade.finalGrade,
        resit: grade.resit,
        average: grade.average,
        letterGrade: grade.letterGrade,
        status: "",
        midtermAvg: "-",
        finalAvg: "-",
        resitAvg: "-",
        termId: grade.termId,
      );
    }
  }
}
