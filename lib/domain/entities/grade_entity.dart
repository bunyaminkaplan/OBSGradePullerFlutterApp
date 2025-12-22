class GradeEntity {
  final String courseCode;
  final String courseName;
  final String midterm;
  final String finalGrade;
  final String resit;
  final String letterGrade;
  final String average;
  final String status;
  final String termId;

  // Class Averages
  final String? midtermAvg;
  final String? finalAvg;
  final String? resitAvg;

  GradeEntity({
    required this.courseCode,
    required this.courseName,
    this.midterm = "-",
    this.finalGrade = "-",
    this.resit = "-",
    this.average = "-",
    this.letterGrade = "-",
    this.status = "-",
    this.termId = "",
    this.midtermAvg,
    this.finalAvg,
    this.resitAvg,
  });
}
