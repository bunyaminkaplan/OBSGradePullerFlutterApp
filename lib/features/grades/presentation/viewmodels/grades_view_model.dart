import 'package:flutter/material.dart';
import '../../domain/usecases/get_grades_usecase.dart';
import '../../domain/usecases/get_grade_details_usecase.dart';
import '../../domain/entities/grade.dart';
import '../../domain/entities/term.dart';

enum GradesState { initial, loading, success, failure }

class GradesViewModel extends ChangeNotifier {
  final GetGradesUseCase _getGradesUseCase;
  final GetGradeDetailsUseCase _getGradeDetailsUseCase;

  GradesState _state = GradesState.initial;
  String _errorMessage = '';

  List<Grade> _grades = [];
  List<Term> _terms = [];
  String _currentTermId = '';

  GradesViewModel({
    required GetGradesUseCase getGradesUseCase,
    required GetGradeDetailsUseCase getGradeDetailsUseCase,
  }) : _getGradesUseCase = getGradesUseCase,
       _getGradeDetailsUseCase = getGradeDetailsUseCase;

  GradesState get state => _state;
  String get errorMessage => _errorMessage;
  List<Grade> get grades => _grades;
  List<Term> get terms => _terms;
  String get currentTermId => _currentTermId;

  Future<void> loadGrades({String? termId}) async {
    _state = GradesState.loading;
    notifyListeners();

    try {
      final result = await _getGradesUseCase(termId: termId);
      _grades = result.grades;
      _terms = result.terms;
      _currentTermId = result.currentTermId;
      _state = GradesState.success;
      debugPrint("📚 Grades loaded: ${_grades.length} items");
      notifyListeners();

      // Auto-fetch all stats after grades load successfully
      await _fetchAllStats();
    } catch (e) {
      _errorMessage = "Notlar alınamadı: $e";
      _state = GradesState.failure;
      debugPrint("❌ Grades load error: $e");
      notifyListeners();
    }
  }

  /// Fetches statistics for ALL grades that have a valid status target.
  /// This is called automatically after loadGrades() completes.
  Future<void> _fetchAllStats() async {
    debugPrint("🔄 Starting fetchAllStats for ${_grades.length} grades...");
    for (int i = 0; i < _grades.length; i++) {
      final grade = _grades[i];
      debugPrint("   [$i] ${grade.courseName} -> status: '${grade.status}'");
      // Only fetch if status is valid (contains btnIstatistik)
      if (grade.status.isNotEmpty && grade.status.contains("btnIstatistik")) {
        debugPrint("   ✅ Fetching stats for: ${grade.courseName}");
        try {
          Grade detailed = await _getGradeDetailsUseCase(grade);
          _grades[i] = detailed;
          debugPrint(
            "   📊 Got: midtermAvg=${detailed.midtermAvg}, finalAvg=${detailed.finalAvg}",
          );
          notifyListeners(); // Update UI incrementally
        } catch (e) {
          debugPrint("   ❌ Error fetching stats for ${grade.courseName}: $e");
        }
      } else {
        debugPrint("   ⏭️ Skipping (no valid status)");
      }
    }
    debugPrint("✅ fetchAllStats completed.");
  }

  Future<void> expandGradeDetails(int index) async {
    if (index < 0 || index >= _grades.length) return;

    // Optimistic update or loading indicator could be handled here
    // For now, we just fetch and update the single item
    try {
      Grade grade = _grades[index];
      // Check if already loaded? (optional)
      if (grade.midtermAvg != null && grade.midtermAvg != "-")
        return; // Already fetched

      Grade detailed = await _getGradeDetailsUseCase(grade);
      _grades[index] = detailed;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching details: $e");
    }
  }
}
