import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verilog_plas/models/evaluation_result.dart';
import 'package:verilog_plas/models/problem.dart';
import 'package:verilog_plas/services/plas_evaluator_service.dart';
import 'package:verilog_plas/services/plas_storage_service.dart';
import 'package:verilog_plas/services/problem_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Comprehensive Dataset & Option Integrity Tests', () {
    late List<Problem> problems;

    setUpAll(() {
      final file = File('assets/data/problems.json');
      expect(file.existsSync(), isTrue);
      problems = Problem.listFromJson(file.readAsStringSync());
      ProblemRepository.setCachedProblems(problems);
    });

    test('All 22 problems exist and have sequential IDs', () {
      expect(problems.length, 22);
      for (var i = 0; i < problems.length; i++) {
        expect(problems[i].id, i + 1);
        expect(problems[i].statement, '${i + 1}');
      }
    });

    test('Every referenced image file exists on disk', () {
      int totalImages = 0;
      for (final p in problems) {
        for (final imgPath in p.images) {
          totalImages++;
          final f = File(imgPath);
          expect(
            f.existsSync(),
            isTrue,
            reason: 'Image $imgPath for Problem #${p.id} must exist on disk',
          );
        }
      }
      expect(totalImages > 0, isTrue);
    });

    test('Every blank across all 22 problems has at least one option matching the SHA-256 answer hash', () {
      int totalBlanksChecked = 0;
      int blanksWithMatchingOption = 0;

      for (final prob in problems) {
        final stm = prob.statement;
        for (final blank in prob.inputs) {
          totalBlanksChecked++;
          bool hasMatch = false;
          for (final opt in blank.options) {
            final testHash = PlasEvaluatorService.computeHash('$opt$stm${blank.index}');
            if (testHash == blank.ansHash) {
              hasMatch = true;
              break;
            }
          }
          if (hasMatch) blanksWithMatchingOption++;
        }
      }

      expect(totalBlanksChecked, 132);
      expect(blanksWithMatchingOption, totalBlanksChecked,
          reason: 'Every single blank must have a valid correct option among its choices');
    });

    test('Questions in each problem properly map to valid blank indices', () {
      for (final prob in problems) {
        final validIndices = prob.inputs.map((e) => e.index).toSet();
        for (final q in prob.questions) {
          expect(validIndices.contains(q.blankIndex), isTrue,
              reason: 'Problem ${prob.id} question maps to blank ${q.blankIndex} which must exist');
          expect(q.options.isNotEmpty, isTrue);
        }
      }
    });
  });

  group('Comprehensive Storage & Record Service Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Student ID persistence works', () async {
      expect(await PlasStorageService.getStudentId(), '');
      await PlasStorageService.setStudentId('B1234567');
      expect(await PlasStorageService.getStudentId(), 'B1234567');
    });

    test('Empty student ID returns prompt in generateRecordText', () async {
      final res = await PlasStorageService.generateRecordText('');
      expect(res, 'Fill in Student ID');
    });

    test('Empty records return no records message', () async {
      final res = await PlasStorageService.generateRecordText('B1234567');
      expect(res, contains('No records found'));
    });

    test('r207clear clears records', () async {
      // Save dummy attempt
      final result = EvaluationResult(
        statementId: '1',
        timestamp: DateTime(2026, 1, 1),
        blankResults: [
          BlankResult(index: 1, userAnswer: 'start', isCorrect: true, placeholder: '1'),
          BlankResult(index: 2, userAnswer: 'foo', isCorrect: false, placeholder: '2'),
        ],
        totalQuestions: 2,
        correctAnswers: 1,
        accuracyRate: 50.0,
        accuracyRateString: '50.00%',
      );
      await PlasStorageService.saveAttempt(result);
      expect((await PlasStorageService.getAllRecords()).length, 1);

      final res = await PlasStorageService.generateRecordText('r207clear');
      expect(res, contains('Records cleared via r207clear'));
      expect((await PlasStorageService.getAllRecords()).isEmpty, isTrue);
    });

    test('Attempt save, retrieval, status calculation, and export file work end-to-end', () async {
      final attempt1 = EvaluationResult(
        statementId: '1',
        timestamp: DateTime(2026, 10, 1, 10, 0, 0),
        blankResults: [
          BlankResult(index: 1, userAnswer: 'start', isCorrect: true, placeholder: '1'),
          BlankResult(index: 2, userAnswer: 'wire', isCorrect: true, placeholder: '2'),
        ],
        totalQuestions: 2,
        correctAnswers: 2,
        accuracyRate: 100.0,
        accuracyRateString: '100.00%',
      );

      final attempt2 = EvaluationResult(
        statementId: '2',
        timestamp: DateTime(2026, 10, 1, 10, 5, 0),
        blankResults: [
          BlankResult(index: 1, userAnswer: 'assign', isCorrect: true, placeholder: '1'),
          BlankResult(index: 2, userAnswer: 'wrong', isCorrect: false, placeholder: '2'),
        ],
        totalQuestions: 2,
        correctAnswers: 1,
        accuracyRate: 50.0,
        accuracyRateString: '50.00%',
      );

      await PlasStorageService.saveAttempt(attempt1);
      await PlasStorageService.saveAttempt(attempt2);

      final statusMap = await PlasStorageService.getProblemsStatus();
      expect(statusMap['1'], ProblemStatus.completed);
      expect(statusMap['2'], ProblemStatus.tried);
      expect(statusMap['3'], isNull);

      final recordText = await PlasStorageService.generateRecordText('B1234567');
      expect(recordText.contains('B1234567'), isTrue);
      expect(recordText.contains('start[o]'), isTrue);
      expect(recordText.contains('wrong[x]'), isTrue);

      final file = await PlasStorageService.saveRecordToFile(
        studentId: 'B1234567',
        recordContent: recordText,
        clearAfterSave: true,
      );

      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), recordText);

      // Verify clearAfterSave
      expect((await PlasStorageService.getAllRecords()).isEmpty, isTrue);

      // Clean up file
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
  });
}
