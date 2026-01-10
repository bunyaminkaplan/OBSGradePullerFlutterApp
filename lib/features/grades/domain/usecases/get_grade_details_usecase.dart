/// Get Grade Details UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import '../entities/grade.dart';
import '../repositories/grades_repository.dart';

/// Ders istatistik detaylarını çekme işlemi için UseCase
class GetGradeDetailsUseCase {
  final GradesRepository _repository;

  const GetGradeDetailsUseCase(this._repository);

  /// Dersin istatistik detaylarını çek
  Future<Grade> call(Grade grade) {
    return _repository.getGradeDetails(grade);
  }
}
