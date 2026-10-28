import 'package:flutter/services.dart';
import '../models/problem.dart';

class ProblemRepository {
  static List<Problem>? _cachedProblems;

  /// Allows setting cached problems directly (e.g. for testing or offline prep)
  static void setCachedProblems(List<Problem> problems) {
    _cachedProblems = problems;
  }

  /// Loads problems from assets/data/problems.json
  static Future<List<Problem>> getProblems() async {
    if (_cachedProblems != null) {
      return _cachedProblems!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/data/problems.json');
      _cachedProblems = Problem.listFromJson(jsonString);
      return _cachedProblems!;
    } catch (e) {
      // Fallback in case of error
      return [];
    }
  }

  /// Get problem by 1-based ID (1..22)
  static Future<Problem?> getProblemById(int id) async {
    final list = await getProblems();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
