import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/auth/presentation/viewmodels/login_view_model.dart';
import '../viewmodels/grades_view_model.dart';
import '../widgets/grade_card.dart';
import '../widgets/term_selector.dart';
import '../widgets/grades_shimmer_list.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  @override
  void initState() {
    super.initState();
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GradesViewModel>().loadGrades();
    });
  }

  Future<void> _performLogout() async {
    await context.read<LoginViewModel>().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GradesViewModel>(
      builder: (context, viewModel, child) {
        final grades = viewModel.grades;
        final terms = viewModel.terms;
        final currentTermId = viewModel.currentTermId;
        final isLoading = viewModel.state == GradesState.loading;

        // Ensure initial load if empty and not loading (optional safety)
        if (grades.isEmpty &&
            !isLoading &&
            terms.isEmpty &&
            viewModel.state == GradesState.initial) {
          // Maybe trigger load? But handled in initState.
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              "Notlar",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => viewModel.loadGrades(termId: currentTermId),
                icon: const Icon(Icons.refresh, color: Colors.blueAccent),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: _performLogout,
              ),
            ],
          ),
          body: Column(
            children: [
              // Term Selector
              TermSelector(
                terms: terms,
                currentTermId: currentTermId,
                onChanged: (val) {
                  if (val != null && val != currentTermId) {
                    viewModel.loadGrades(termId: val);
                  }
                },
              ),

              // Content
              Expanded(
                child: isLoading
                    ? const GradesShimmerList()
                    : grades.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.class_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Bu dönem için not bulunamadı.",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: grades.length,
                        itemBuilder: (context, index) {
                          return GradeCard(grade: grades[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
