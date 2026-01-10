import '../../features/grades/domain/repositories/grades_repository.dart';
import '../../features/grades/domain/entities/grade.dart';
import '../../features/grades/domain/entities/term.dart';
import '../../features/grades/domain/entities/grades_result.dart';
import '../datasources/grades_remote_data_source.dart';

class GradesRepositoryImpl implements GradesRepository {
  final GradesRemoteDataSource _remoteDataSource;

  GradesRepositoryImpl(this._remoteDataSource);

  @override
  Future<GradesResult> getGrades({String? termId}) async {
    final result = await _remoteDataSource.fetchGrades(termId: termId);

    // DataSource artık doğrudan Grade dönüyor
    List<Grade> grades = result['grades'] as List<Grade>;
    List<Map<String, String>> dataTerms =
        result['terms'] as List<Map<String, String>>;
    String currentTerm = result['currentTerm'] as String;

    List<Term> terms = dataTerms
        .map((t) => Term(id: t['id']!, name: t['name']!))
        .toList();

    return GradesResult(
      grades: grades,
      terms: terms,
      currentTermId: currentTerm,
    );
  }

  @override
  Future<Grade> getGradeDetails(Grade entity) async {
    // DataSource artık doğrudan Grade alıp Grade dönüyor
    return await _remoteDataSource.fetchStatsForGrade(entity);
  }
}
