import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../services/problem_repository.dart';
import '../services/plas_storage_service.dart';
import '../theme/app_theme.dart';
import 'problem_detail_screen.dart';

class ProblemListScreen extends StatefulWidget {
  const ProblemListScreen({super.key});

  @override
  State<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends State<ProblemListScreen> {
  List<Problem> _problems = [];
  Map<String, ProblemStatus> _statusMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final problems = await ProblemRepository.getProblems();
    final statusMap = await PlasStorageService.getProblemsStatus();

    if (mounted) {
      setState(() {
        _problems = problems;
        _statusMap = statusMap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_problems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No problems found. Tap to reload.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: const Text('Reload')),
          ],
        ),
      );
    }

    // Compute stats
    int completedCount = 0;
    int triedCount = 0;
    for (final p in _problems) {
      final status = _statusMap[p.statement] ?? ProblemStatus.notAttempted;
      if (status == ProblemStatus.completed) {
        completedCount++;
      } else if (status == ProblemStatus.tried) {
        triedCount++;
      }
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header title matching PLAS web
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CH1 Problems: Verilog Introduction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Overview progress card
          _buildProgressCard(completedCount, triedCount),

          const SizedBox(height: 12),

          // Table header info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF343A40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    'No',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Problem Name',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'Remark',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Problem rows
          ..._problems.map((prob) => _buildProblemRow(prob)),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, int tried) {
    final total = _problems.length;
    final progress = total > 0 ? (completed / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progress: $completed / $total Completed',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              if (tried > 0)
                Text(
                  '($tried Tried)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF856404),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemRow(Problem problem) {
    final status = _statusMap[problem.statement] ?? ProblemStatus.notAttempted;

    Color rowBg = Colors.white;
    Color rowBorder = const Color(0xFFE9ECEF);
    Widget remarkBadge = const SizedBox.shrink();

    if (status == ProblemStatus.completed) {
      rowBg = AppTheme.statusCompletedBg.withValues(alpha: 0.4);
      rowBorder = AppTheme.statusCompletedBorder;
      remarkBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.statusCompletedBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.statusCompletedBorder),
        ),
        child: const Text(
          'Completed',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.statusCompletedText,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (status == ProblemStatus.tried) {
      rowBg = AppTheme.statusTriedBg.withValues(alpha: 0.4);
      rowBorder = AppTheme.statusTriedBorder;
      remarkBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.statusTriedBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.statusTriedBorder),
        ),
        child: const Text(
          'Tried',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.statusTriedText,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: rowBg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProblemDetailScreen(problem: problem),
              ),
            );
            if (mounted) {
              _loadData();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: rowBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '${problem.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    problem.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212529),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Center(child: remarkBadge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
