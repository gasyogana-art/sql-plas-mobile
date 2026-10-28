import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verilog_plas/models/problem.dart';
import 'package:verilog_plas/services/plas_evaluator_service.dart';

void main() {
  group('PLAS Evaluator Tests', () {
    test('SHA256 hash matches PLAS JS hex_sha256 exactly', () {
      // Q1 blank 1: input="start", stm="1", idx=1 -> "start11"
      final hash = PlasEvaluatorService.computeHash('start11');
      expect(
        hash,
        '86b5568cb58d41689d03df36b51171b4318d755179a55d16410ff67ee6cd5b92',
      );
    });

    test('verifyAnswer returns true for correct answer', () {
      final isValid = PlasEvaluatorService.verifyAnswer(
        userAnswer: 'start',
        statementId: '1',
        inputIndex: 1,
        expectedHash: '86b5568cb58d41689d03df36b51171b4318d755179a55d16410ff67ee6cd5b92',
      );
      expect(isValid, isTrue);
    });

    test('verifyAnswer handles trailing whitespace gracefully', () {
      final isValid = PlasEvaluatorService.verifyAnswer(
        userAnswer: 'start ',
        statementId: '1',
        inputIndex: 1,
        expectedHash: '86b5568cb58d41689d03df36b51171b4318d755179a55d16410ff67ee6cd5b92',
      );
      expect(isValid, isTrue);
    });

    test('verifyAnswer returns false for wrong answer', () {
      final isValid = PlasEvaluatorService.verifyAnswer(
        userAnswer: 'wrong_ans',
        statementId: '1',
        inputIndex: 1,
        expectedHash: '86b5568cb58d41689d03df36b51171b4318d755179a55d16410ff67ee6cd5b92',
      );
      expect(isValid, isFalse);
    });

    test('evaluateProblem produces accurate statistics and storage format', () {
      final problem = Problem(
        id: 1,
        statement: '1',
        name: 'Start',
        knowledgePoint: '',
        images: [],
        codeTemplate: 'module start();',
        questions: [],
        inputs: [
          BlankInput(
            index: 1,
            placeholder: '1',
            ansHash: '86b5568cb58d41689d03df36b51171b4318d755179a55d16410ff67ee6cd5b92',
            size: 2,
          ),
          BlankInput(
            index: 2,
            placeholder: '2',
            ansHash: 'd6edb796f76ed7419e6d8455699f0295f7ac8e2b4b3aeae2c321127381a8e9cf',
            size: 2,
          ),
        ],
        totalInputs: 2,
      );

      final fixedDate = DateTime(2026, 10, 1, 14, 30, 0);

      // Answer 1 correct ("start"), Answer 2 wrong ("foo")
      final result = PlasEvaluatorService.evaluateProblem(
        problem: problem,
        userAnswers: {1: 'start', 2: 'foo'},
        now: fixedDate,
      );

      expect(result.totalQuestions, 2);
      expect(result.correctAnswers, 1);
      expect(result.accuracyRate, 50.0);
      expect(result.accuracyRateString, '50.00%');
      expect(result.storageKey, '1\t2026-10-01 14:30:00');
      expect(result.storageValue, '\tstart[o],foo[x], Accuracy:50.00%');
      expect(result.isAllCorrect, isFalse);
    });

    test('getAccuracyColor conforms to PLAS specification', () {
      // < 60% -> Red
      expect(PlasEvaluatorService.getAccuracyColor(59.9), const Color(0xFFE53935));
      expect(PlasEvaluatorService.getAccuracyColor(0.0), const Color(0xFFE53935));

      // 60% <= rate < 100% -> dark neutral
      expect(PlasEvaluatorService.getAccuracyColor(60.0), const Color(0xFF212121));
      expect(PlasEvaluatorService.getAccuracyColor(85.5), const Color(0xFF212121));

      // 100% -> #1BBC9B (0xFF1BBC9B)
      expect(PlasEvaluatorService.getAccuracyColor(100.0), const Color(0xFF1BBC9B));
    });

    test('verifyAnswer returns false for empty string', () {
      final isValid = PlasEvaluatorService.verifyAnswer(
        userAnswer: '',
        statementId: '1',
        inputIndex: 1,
        expectedHash: '86b5568cb58d41689d03df36b51171b4318d755179a55d16410ff67ee6cd5b92',
      );
      expect(isValid, isFalse);
    });
  });
}
