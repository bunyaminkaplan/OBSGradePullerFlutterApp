import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/entities/grade.dart';

class GradeCard extends StatelessWidget {
  final Grade grade;
  const GradeCard({super.key, required this.grade});

  Color _getStatusColor(String letter) {
    if (letter.startsWith('A')) return const Color(0xFF43A047);
    if (letter.startsWith('B')) return const Color(0xFF7CB342);
    if (letter.startsWith('C')) return const Color(0xFFFDD835);
    if (letter.startsWith('D')) return const Color(0xFFFB8C00);
    if (letter.startsWith('F')) return const Color(0xFFE53935);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(grade.letterGrade);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    bool hasResit = grade.resit != "-" && grade.resit.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[100]!,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          grade.courseName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "- ${grade.courseCode}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    grade.letterGrade,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GradeItem(
                  label: "Ara Sınav",
                  value: grade.midterm,
                  avg: grade.midtermAvg,
                  showAvg: true,
                ),
                _GradeContainer(
                  label: "Final",
                  value: grade.finalGrade,
                  avg: grade.finalAvg,
                  isMain: !hasResit,
                ),
                hasResit
                    ? _GradeContainer(
                        label: "Bütünleme",
                        value: grade.resit,
                        avg: grade.resitAvg,
                        isMain: true,
                      )
                    : _GradeItem(
                        label: "Bütünleme",
                        value: grade.resit,
                        avg: grade.resitAvg,
                        showAvg: true,
                      ),
              ],
            ),
          ),
          // Footer
          if (grade.average.isNotEmpty && grade.average != "-")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    "Ortalama:",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    grade.average,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 16,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    grade.status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(grade.letterGrade),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GradeContainer extends StatelessWidget {
  final String label;
  final String value;
  final String? avg;
  final bool isMain;

  const _GradeContainer({
    required this.label,
    required this.value,
    this.avg,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return _GradeItem(
      label: label,
      value: value,
      avg: avg,
      isMain: isMain,
      showAvg: true,
    );
  }
}

class _GradeItem extends StatelessWidget {
  final String label;
  final String value;
  final String? avg;
  final bool isMain;
  final bool showAvg;

  const _GradeItem({
    required this.label,
    required this.value,
    this.avg,
    this.isMain = false,
    this.showAvg = false,
  });

  double? _parse(String s) {
    if (s.isEmpty || s == "-") return null;
    s = s.replaceAll(',', '.');
    s = s.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    double? myVal = _parse(value);
    double? avgVal = (avg != null && avg != "?" && avg != "-")
        ? _parse(avg!)
        : null;

    IconData? comparisonIcon;
    Color? comparisonColor;

    if (myVal != null && avgVal != null) {
      if (myVal > avgVal) {
        comparisonIcon = Icons.arrow_upward_rounded;
        comparisonColor = Colors.green;
      } else if (myVal < avgVal) {
        comparisonIcon = Icons.arrow_downward_rounded;
        comparisonColor = Colors.red;
      }
    }

    bool hasGrade = (value.isNotEmpty && value != "-" && value != "Girilmedi");

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: isMain ? 80 : 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isMain
                ? (isDark
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.blue[50])
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isMain
                ? Border.all(
                    color: isDark
                        ? Colors.blueAccent.withValues(alpha: 0.5)
                        : Colors.blue[100]!,
                  )
                : null,
          ),
          child: Column(
            children: [
              Text(
                value.isEmpty ? "-" : value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMain ? 18 : 16,
                  color: isMain ? Colors.blueAccent : textColor,
                ),
              ),
              if (showAvg && hasGrade) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 16,
                  child: avg == null
                      ? Shimmer.fromColors(
                          baseColor: isDark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          highlightColor: isDark
                              ? Colors.grey[600]!
                              : Colors.grey[100]!,
                          child: Container(
                            width: 40,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (avg == "?" || avg == "-") ? "-" : avg!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (comparisonIcon != null) ...[
                              const SizedBox(width: 2),
                              Icon(
                                comparisonIcon,
                                size: 12,
                                color: comparisonColor,
                              ),
                            ],
                          ],
                        ),
                ),
              ] else if (showAvg && !hasGrade) ...[
                const SizedBox(height: 0),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
