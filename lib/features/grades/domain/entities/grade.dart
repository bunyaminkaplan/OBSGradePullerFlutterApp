/// Grade Entity - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

/// Ders notu domain entity
/// Immutable ve pure Dart
class Grade {
  final String courseCode;
  final String courseName;
  final String midterm;
  final String finalGrade;
  final String resit;
  final String letterGrade;
  final String average;
  final String status;
  final String termId;

  // Sınıf ortalamaları (istatistik)
  final String? midtermAvg;
  final String? finalAvg;
  final String? resitAvg;

  const Grade({
    required this.courseCode,
    required this.courseName,
    this.midterm = '-',
    this.finalGrade = '-',
    this.resit = '-',
    this.average = '-',
    this.letterGrade = '-',
    this.status = '',
    this.termId = '',
    this.midtermAvg,
    this.finalAvg,
    this.resitAvg,
  });

  /// İstatistik verisi yüklü mü?
  bool get hasStats =>
      midtermAvg != null || finalAvg != null || resitAvg != null;

  /// Vize notu var mı?
  bool get hasMidterm => midterm != '-' && midterm.isNotEmpty;

  /// Final notu var mı?
  bool get hasFinal => finalGrade != '-' && finalGrade.isNotEmpty;

  /// Bütünleme notu var mı?
  bool get hasResit => resit != '-' && resit.isNotEmpty;

  /// Harf notu geçerli mi?
  bool get hasLetterGrade => letterGrade != '-' && letterGrade.isNotEmpty;

  /// İstatistik butonu hedefi var mı?
  bool get hasStatsTarget =>
      status.isNotEmpty && status.contains('btnIstatistik');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Grade &&
          runtimeType == other.runtimeType &&
          courseCode == other.courseCode &&
          termId == other.termId;

  @override
  int get hashCode => Object.hash(courseCode, termId);

  @override
  String toString() => 'Grade($courseCode: $courseName)';

  /// Yeni değerlerle kopyala
  Grade copyWith({
    String? courseCode,
    String? courseName,
    String? midterm,
    String? finalGrade,
    String? resit,
    String? letterGrade,
    String? average,
    String? status,
    String? termId,
    String? midtermAvg,
    String? finalAvg,
    String? resitAvg,
  }) {
    return Grade(
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      midterm: midterm ?? this.midterm,
      finalGrade: finalGrade ?? this.finalGrade,
      resit: resit ?? this.resit,
      letterGrade: letterGrade ?? this.letterGrade,
      average: average ?? this.average,
      status: status ?? this.status,
      termId: termId ?? this.termId,
      midtermAvg: midtermAvg ?? this.midtermAvg,
      finalAvg: finalAvg ?? this.finalAvg,
      resitAvg: resitAvg ?? this.resitAvg,
    );
  }
}
