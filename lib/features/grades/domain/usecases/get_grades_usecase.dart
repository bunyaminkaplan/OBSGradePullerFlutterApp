/// Get Grades UseCase - Domain Layer
/// Bu dosya SAF DART'tır - Flutter import'u YASAKTIR!
library;

import '../entities/grades_result.dart';
import '../repositories/grades_repository.dart';

/// Notları çekme işlemi için UseCase
class GetGradesUseCase {
  final GradesRepository _repository;

  const GetGradesUseCase(this._repository);

  /// Notları çek
  /// [termId] belirtilirse o dönemin notlarını getirir
  Future<GradesResult> call({String? termId}) {
    return _repository.getGrades(termId: termId);
  }
}
