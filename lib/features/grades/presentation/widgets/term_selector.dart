import 'package:flutter/material.dart';
import '../../domain/entities/term.dart';

class TermSelector extends StatelessWidget {
  final List<Term> terms;
  final String? currentTermId;
  final ValueChanged<String?> onChanged;

  const TermSelector({
    super.key,
    required this.terms,
    required this.currentTermId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (terms.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (currentTermId != null && currentTermId!.isNotEmpty)
              ? currentTermId
              : null,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.blueAccent,
          ),
          isExpanded: true,
          dropdownColor: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          elevation: 4,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          items: terms.map((t) {
            return DropdownMenuItem<String>(
              value: t.id,
              child: Text(t.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
