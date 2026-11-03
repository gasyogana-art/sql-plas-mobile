import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verilog_plas/models/problem.dart';
import 'package:verilog_plas/services/plas_evaluator_service.dart';
import 'package:verilog_plas/services/plas_storage_service.dart';
import 'package:verilog_plas/services/problem_repository.dart';
import 'package:verilog_plas/services/txt_submission_service.dart';
import 'package:verilog_plas/widgets/submission_export_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Problem> allProblems;

  setUpAll(() {
    final file = File('assets/data/problems.json');
    expect(file.existsSync(), isTrue);
    allProblems = Problem.listFromJson(file.readAsStringSync());
    ProblemRepository.setCachedProblems(allProblems);
  });

  group('TxtSubmissionService Unit Tests', () {
    test('generateUniqueFilename creates clean, unique, sanitized filenames', () {
      final fixedDate = DateTime(2026, 11, 3, 10, 15, 30);
      final filename = TxtSubmissionService.generateUniqueFilename(
        studentId: '1301204012 / AB',
        courseCode: 'Verilog HDL 101',
        timestamp: fixedDate,
      );

      expect(filename, 'Submission_1301204012___AB_Verilog_HDL_101_20261103_101530.txt');
      expect(filename.endsWith('.txt'), isTrue);
      expect(filename.contains('/'), isFalse);
      expect(filename.contains(' '), isFalse);
    });

    test('calculateGrade returns expected academic grading tiers', () {
      expect(TxtSubmissionService.calculateGrade(100.0), 'EXCELLENT (A)');
      expect(TxtSubmissionService.calculateGrade(90.0), 'EXCELLENT (A)');
      expect(TxtSubmissionService.calculateGrade(89.9), 'VERY GOOD (B+)');
      expect(TxtSubmissionService.calculateGrade(80.0), 'VERY GOOD (B+)');
      expect(TxtSubmissionService.calculateGrade(75.0), 'GOOD (B)');
      expect(TxtSubmissionService.calculateGrade(65.0), 'SATISFACTORY (C)');
      expect(TxtSubmissionService.calculateGrade(50.0), 'NEEDS IMPROVEMENT (D)');
      expect(TxtSubmissionService.calculateGrade(0.0), 'NEEDS IMPROVEMENT (D)');
    });

    test('parseStorageValueAnswers correctly parses answers and correctness flags', () {
      const rawVal =
          '\tsimple_wire[o],module[o],endmodule[o],a[x],b[o],assign[x], Accuracy:66.67%';
      final parsed = TxtSubmissionService.parseStorageValueAnswers(rawVal);

      expect(parsed.length, 6);
      expect(parsed[0].answer, 'simple_wire');
      expect(parsed[0].isCorrect, isTrue);
      expect(parsed[1].answer, 'module');
      expect(parsed[1].isCorrect, isTrue);
      expect(parsed[2].answer, 'endmodule');
      expect(parsed[2].isCorrect, isTrue);
      expect(parsed[3].answer, 'a');
      expect(parsed[3].isCorrect, isFalse);
      expect(parsed[4].answer, 'b');
      expect(parsed[4].isCorrect, isTrue);
      expect(parsed[5].answer, 'assign');
      expect(parsed[5].isCorrect, isFalse);
    });

    test('parseTimestamp parses standard format correctly', () {
      final dt = TxtSubmissionService.parseTimestamp('2026-11-03 14:25:30');
      expect(dt.year, 2026);
      expect(dt.month, 11);
      expect(dt.day, 3);
      expect(dt.hour, 14);
      expect(dt.minute, 25);
      expect(dt.second, 30);
    });
  });

  group('Full Submission Generation & Formatting Flow', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PlasStorageService.clearRecords();
      ProblemRepository.setCachedProblems(allProblems);
    });

    test('buildSubmissionData and formatAsText contain all required student, problem, and grade info', () async {
      // Setup student info in storage
      await PlasStorageService.setStudentId('1301204012');
      await PlasStorageService.setStudentName('Budi Santoso');
      await PlasStorageService.setCourseName('Hardware Description Language (Verilog HDL)');

      // Solve Problem 1
      final p1 = await ProblemRepository.getProblemById(1);
      expect(p1, isNotNull);

      final p1Answers = {
        1: 'start',
        2: 'module',
        3: 'endmodule',
        4: 'a',
        5: 'b',
        6: 'assign',
      };
      final res1 = PlasEvaluatorService.evaluateProblem(
        problem: p1!,
        userAnswers: p1Answers,
        now: DateTime(2026, 11, 3, 9, 30, 0),
      );
      await PlasStorageService.saveAttempt(res1);

      // Solve Problem 2
      final p2 = await ProblemRepository.getProblemById(2);
      expect(p2, isNotNull);

      final p2Answers = {
        1: 'output',
        2: 'assign',
        3: 'endmodule',
        4: 'module',
        5: 'input',
        6: 'wire',
      };
      final res2 = PlasEvaluatorService.evaluateProblem(
        problem: p2!,
        userAnswers: p2Answers,
        now: DateTime(2026, 11, 3, 9, 35, 0),
      );
      await PlasStorageService.saveAttempt(res2);

      // Build submission data
      final submission = await TxtSubmissionService.buildSubmissionData(
        studentId: '1301204012',
        studentName: 'Budi Santoso',
        courseName: 'Hardware Description Language (Verilog HDL)',
        now: DateTime(2026, 11, 3, 10, 0, 0),
      );

      expect(submission.studentInfo.studentId, '1301204012');
      expect(submission.studentInfo.studentName, 'Budi Santoso');
      expect(submission.studentInfo.courseName, 'Hardware Description Language (Verilog HDL)');
      expect(submission.problemsAttempted, 2);
      expect(submission.problemsCompleted, 2);
      expect(submission.totalQuestionsAnswered, 8);
      expect(submission.totalCorrectAnswers, 8);
      expect(submission.overallAccuracyRate, 100.0);
      expect(submission.finalGrade, 'EXCELLENT (A)');
      expect(submission.sessionHash.length, 64);

      // Format as text
      final text = TxtSubmissionService.formatAsText(submission);

      // Verify all required elements are present in the text
      expect(text.contains('1301204012'), isTrue);
      expect(text.contains('Budi Santoso'), isTrue);
      expect(text.contains('Hardware Description Language (Verilog HDL)'), isTrue);
      expect(text.contains('1. STUDENT & COURSE INFORMATION'), isTrue);
      expect(text.contains('2. FINAL EVALUATION & GRADE SUMMARY'), isTrue);
      expect(text.contains('3. PROBLEM PERFORMANCE OVERVIEW'), isTrue);
      expect(text.contains('4. DETAILED QUESTIONS & ANSWERS BREAKDOWN'), isTrue);
      expect(text.contains('PROBLEM #01: Start'), isTrue);
      expect(text.contains('PROBLEM #02: Simple Wire'), isTrue);
      expect(text.contains('[✓] CORRECT'), isTrue);
      expect(text.contains('100.00%'), isTrue);
      expect(text.contains('EXCELLENT (A)'), isTrue);
      expect(text.contains(submission.sessionHash), isTrue);

      // Test saving to file
      final filename = TxtSubmissionService.generateUniqueFilename(
        studentId: '1301204012',
        timestamp: DateTime(2026, 11, 3, 10, 0, 0),
      );
      final file = await TxtSubmissionService.saveSubmissionToFile(
        filename: filename,
        content: text,
      );

      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), text);

      // Cleanup test file
      try {
        file.deleteSync();
      } catch (_) {}
    });
  });

  group('SubmissionExportModal Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PlasStorageService.clearRecords();
      ProblemRepository.setCachedProblems(allProblems);
    });

    testWidgets('SubmissionExportModal renders cleanly without overflow and allows generation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Save student ID and a problem attempt
      await PlasStorageService.setStudentId('2023001');
      await PlasStorageService.setStudentName('Andi Pratama');

      final p1 = await ProblemRepository.getProblemById(1);
      final res1 = PlasEvaluatorService.evaluateProblem(
        problem: p1!,
        userAnswers: {1: 'start', 2: 'module', 3: 'endmodule', 4: 'a', 5: 'b', 6: 'assign'},
      );
      await PlasStorageService.saveAttempt(res1);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SubmissionExportModal(),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify fields exist
      expect(find.text('Generate TXT Submission'), findsOneWidget);
      expect(find.text('Student ID *'), findsOneWidget);
      expect(find.text('Save to Device'), findsOneWidget);
      expect(find.text('Email / Teams'), findsOneWidget);

      // Scroll to preview card
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      expect(find.text('TXT File Preview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
