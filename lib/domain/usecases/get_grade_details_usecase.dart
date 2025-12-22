import '../repositories/grades_repository.dart';
import '../entities/grade_entity.dart';

class GetGradeDetailsUseCase {
  final IGradesRepository _repository;

  GetGradeDetailsUseCase(this._repository);

  Future<GradeEntity> execute(GradeEntity grade) {
    return _repository.getGradeDetails(grade);
  }
}
