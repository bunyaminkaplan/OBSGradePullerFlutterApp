import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import '../../models/grade.dart';

/// ---------------------------------------------------------------------------
/// GRADES REMOTE DATA SOURCE
/// ---------------------------------------------------------------------------
/// Bu sınıf, notları çekme ve dönem değiştirme işlemlerini yönetir.
/// 'AuthRemoteDataSource' ile aynı 'Dio' instance'ını (ve CookieJar'ı)
/// paylaşmak zorundadır, yoksa oturum bilgisi kaybolur.
/// ---------------------------------------------------------------------------
class GradesRemoteDataSource {
  final Dio _dio;

  // ViewState paylaşımı için Auth kaynağına erişim gerekebilir veya
  // Dio cookie'leri yönettiği için sadece URL ve Input bilgisi yeterlidir.
  // Inputlar sayfadan sayfaya değişir, o yüzden her istekte yeniden parse edilir.
  Map<String, String> _hiddenInputs = {};

  String _baseUrl = "https://obs.ozal.edu.tr";

  GradesRemoteDataSource(this._dio);

  void setBaseUrl(String url) {
    _baseUrl = url;
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
        print("MİMARİ LOG: Dönem Değiştiriliyor -> $termId");

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

      if (table != null) {
        var rows = table.querySelectorAll('tr');
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
        }
      }

      return {'grades': grades, 'terms': terms, 'currentTerm': currentTermId};
    } catch (e) {
      print("Not Çekme Hatası: $e");
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
}
