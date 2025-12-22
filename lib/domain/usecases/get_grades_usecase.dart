import '../repositories/grades_repository.dart';

class GetGradesUseCase {
  final IGradesRepository _repository;

  GetGradesUseCase(this._repository);

  Future<GradesResult> execute({String? termId}) {
    return _repository.getGrades(termId: termId);
  }
}
