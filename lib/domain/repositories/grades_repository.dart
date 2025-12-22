import '../entities/grade_entity.dart';
import '../entities/term_entity.dart';

class GradesResult {
  final List<GradeEntity> grades;
  final List<TermEntity> terms;
  final String currentTermId;

  GradesResult({
    required this.grades,
    required this.terms,
    required this.currentTermId,
  });
}

abstract class IGradesRepository {
  Future<GradesResult> getGrades({String? termId});
  Future<GradeEntity> getGradeDetails(GradeEntity grade);
}
