import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../models/evaluation_result.dart';

class PlasEvaluatorService {
  /// Computes SHA256 hex string matching hex_sha256 in JavaScript
  static String computeHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase();
  }

  /// Evaluates a single blank input
  static bool verifyAnswer({
    required String userAnswer,
    required String statementId,
    required int inputIndex,
    required String expectedHash,
  }) {
    if (expectedHash.isEmpty) return false;

    // Direct check: val + stm + idx
    final hashExact = computeHash('$userAnswer$statementId$inputIndex');
    if (hashExact == expectedHash.toLowerCase()) {
      return true;
    }

    // Mobile-friendly check for accidental leading/trailing spaces
    final trimmed = userAnswer.trim();
    if (trimmed != userAnswer) {
      final hashTrimmed = computeHash('$trimmed$statementId$inputIndex');
      if (hashTrimmed == expectedHash.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /// Evaluates all inputs of a problem
  static EvaluationResult evaluateProblem({
    required Problem problem,
    required Map<int, String> userAnswers,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    int correctCount = 0;
    final totalCount = problem.inputs.length;
    final blankResults = <BlankResult>[];

    for (final blank in problem.inputs) {
      final answer = userAnswers[blank.index] ?? '';
      final isCorrect = verifyAnswer(
        userAnswer: answer,
        statementId: problem.statement,
        inputIndex: blank.index,
        expectedHash: blank.ansHash,
      );

      if (isCorrect) {
        correctCount++;
      }

      blankResults.add(BlankResult(
        index: blank.index,
        userAnswer: answer,
        isCorrect: isCorrect,
        placeholder: blank.placeholder,
      ));
    }

    final double accuracyRate =
        totalCount > 0 ? (correctCount / totalCount) * 100 : 0.0;
    final accuracyString = '${accuracyRate.toStringAsFixed(2)}%';

    return EvaluationResult(
      statementId: problem.statement,
      totalQuestions: totalCount,
      correctAnswers: correctCount,
      accuracyRate: accuracyRate,
      accuracyRateString: accuracyString,
      blankResults: blankResults,
      timestamp: timestamp,
    );
  }

  /// Accurate PLAS color rule:
  /// < 60% -> Red
  /// 60% <= rate < 100% -> Black/Dark neutral
  /// == 100% -> #1BBC9B (Teal Green)
  static Color getAccuracyColor(double accuracyRate, {bool isDarkMode = false}) {
    if (accuracyRate < 60) {
      return const Color(0xFFE53935); // Red
    } else if (accuracyRate < 100) {
      return isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
    } else {
      return const Color(0xFF1BBC9B); // Original PLAS #1BBC9B green
    }
  }
}
