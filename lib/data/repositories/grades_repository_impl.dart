import '../../domain/repositories/grades_repository.dart';
import '../../domain/entities/grade_entity.dart';
import '../../domain/entities/term_entity.dart';
import '../datasources/grades_remote_data_source.dart';
import '../../models/grade.dart'; // Data Model

class GradesRepositoryImpl implements IGradesRepository {
  final GradesRemoteDataSource _remoteDataSource;

  GradesRepositoryImpl(this._remoteDataSource);

  @override
  Future<GradesResult> getGrades({String? termId}) async {
    final result = await _remoteDataSource.fetchGrades(termId: termId);

    // Parse Data Models -> Domain Entities
    List<Grade> dataGrades = result['grades'] as List<Grade>;
    List<Map<String, String>> dataTerms =
        result['terms'] as List<Map<String, String>>;
    String currentTerm = result['currentTerm'] as String;

    List<GradeEntity> grades = dataGrades.map((g) => _toEntity(g)).toList();
    List<TermEntity> terms = dataTerms
        .map((t) => TermEntity(id: t['id']!, name: t['name']!))
        .toList();

    return GradesResult(
      grades: grades,
      terms: terms,
      currentTermId: currentTerm,
    );
  }

  @override
  Future<GradeEntity> getGradeDetails(GradeEntity entity) async {
    // Convert Entity -> Model for DataSource
    Grade model = _toModel(entity);

    // Fetch
    Grade updatedModel = await _remoteDataSource.fetchStatsForGrade(model);

    // Convert Model -> Entity
    return _toEntity(updatedModel);
  }

  // Mapper: Model -> Entity
  GradeEntity _toEntity(Grade model) {
    return GradeEntity(
      courseCode: model.courseCode,
      courseName: model.courseName,
      midterm: model.midterm,
      finalGrade: model.finalGrade,
      resit: model.resit,
      average: model.average,
      letterGrade: model.letterGrade,
      status: model.status,
      termId: model.termId,
      midtermAvg: model.midtermAvg,
      finalAvg: model.finalAvg,
      resitAvg: model.resitAvg,
    );
  }

  // Mapper: Entity -> Model
  Grade _toModel(GradeEntity entity) {
    return Grade(
      courseCode: entity.courseCode,
      courseName: entity.courseName,
      midterm: entity.midterm,
      finalGrade: entity.finalGrade,
      resit: entity.resit,
      average: entity.average,
      letterGrade: entity.letterGrade,
      status: entity.status,
      termId: entity.termId,
      midtermAvg: entity.midtermAvg,
      finalAvg: entity.finalAvg,
      resitAvg: entity.resitAvg,
    );
  }
}
