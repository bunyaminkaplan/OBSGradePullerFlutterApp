/// Grades Repository Interface - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import 'grade.dart';
import 'term.dart';

/// Notları çekme ve yönetme işlemleri için sonuç sınıfı
class GradesResult {
  final List<Grade> grades;
  final List<Term> terms;
  final String currentTermId;

  const GradesResult({
    required this.grades,
    required this.terms,
    required this.currentTermId,
  });
}
