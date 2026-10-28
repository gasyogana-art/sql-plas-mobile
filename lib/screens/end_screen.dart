import 'package:flutter/material.dart';
import '../services/plas_storage_service.dart';
import '../services/problem_repository.dart';
import '../theme/app_theme.dart';

class EndScreen extends StatefulWidget {
  final VoidCallback onBackToProblems;

  const EndScreen({super.key, required this.onBackToProblems});

  @override
  State<EndScreen> createState() => _EndScreenState();
}

class _EndScreenState extends State<EndScreen> {
  int _completed = 0;
  int _tried = 0;
  int _total = 22;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final problems = await ProblemRepository.getProblems();
    final statusMap = await PlasStorageService.getProblemsStatus();

    int completed = 0;
    int tried = 0;
    for (final p in problems) {
      final s = statusMap[p.statement] ?? ProblemStatus.notAttempted;
      if (s == ProblemStatus.completed) {
        completed++;
      } else if (s == ProblemStatus.tried) {
        tried++;
      }
    }

    if (mounted) {
      setState(() {
        _total = problems.length;
        _completed = completed;
        _tried = tried;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Records?'),
        content: const Text(
          'This will permanently delete all your stored attempt records and reset problem statuses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PlasStorageService.clearRecords();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All records cleared successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: const [
            Icon(Icons.flag_outlined, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'End & Session Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Session Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'CH1 Verilog Introduction Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('$_completed', 'Completed', const Color(0xFF1BBC9B)),
                    _buildStatColumn('$_tried', 'Tried', const Color(0xFFD39E00)),
                    _buildStatColumn('${(_total - _completed - _tried).clamp(0, _total)}', 'Pending', Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _total > 0 ? (_completed / _total) : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Navigation back button
        ElevatedButton.icon(
          icon: const Icon(Icons.menu_book, color: Colors.white),
          label: const Text(
            'Continue Solving Problems',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: widget.onBackToProblems,
        ),

        const SizedBox(height: 12),

        // Reset records button
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Reset All Local Records', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _handleReset,
        ),

        const SizedBox(height: 24),

        // System info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'About PLAS (Verilog)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                'Programming Learning Assistant System (PLAS) for Verilog HDL.\nBased on Okayama University Funabiki Lab offline VPLAS system.\nAdapted for mobile smartphones with Flutter.',
                style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
