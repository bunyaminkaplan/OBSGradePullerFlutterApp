/// Grades Repository Interface - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import '../entities/grade.dart';
import '../entities/grades_result.dart';

/// Notları çekme ve yönetme işlemleri için repository sözleşmesi
/// Data katmanı bu interface'i implement eder
abstract interface class GradesRepository {
  /// Notları çek
  /// [termId] belirtilirse o döneme ait notları getirir
  Future<GradesResult> getGrades({String? termId});

  /// Belirli bir dersin istatistik detaylarını çek
  Future<Grade> getGradeDetails(Grade grade);
}
