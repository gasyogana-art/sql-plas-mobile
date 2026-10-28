import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verilog_plas/main.dart';
import 'package:verilog_plas/models/problem.dart';
import 'package:verilog_plas/screens/problem_detail_screen.dart';
import 'package:verilog_plas/services/plas_evaluator_service.dart';
import 'package:verilog_plas/services/problem_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final file = File('assets/data/problems.json');
    if (file.existsSync()) {
      ProblemRepository.setCachedProblems(
        Problem.listFromJson(file.readAsStringSync()),
      );
    }
  });

  group('Deep Problem Dataset & Model Tests', () {
    test('All 22 problems parse cleanly from json with zero nulls', () {
      final file = File('assets/data/problems.json');
      expect(file.existsSync(), isTrue, reason: 'problems.json must exist');

      final content = file.readAsStringSync();
      final list = json.decode(content) as List<dynamic>;
      expect(list.length, 22, reason: 'Must have all 22 problems');

      for (var i = 0; i < list.length; i++) {
        final raw = list[i] as Map<String, dynamic>;
        final prob = Problem.fromJson(raw);

        expect(prob.id, i + 1);
        expect(prob.statement.isNotEmpty, isTrue);
        expect(prob.name.isNotEmpty, isTrue);
        expect(prob.inputs.isNotEmpty, isTrue);
        expect(prob.totalInputs, prob.inputs.length);

        // Every blank input must have valid properties
        for (final input in prob.inputs) {
          expect(input.index > 0, isTrue);
          expect(input.placeholder.isNotEmpty, isTrue);
          expect(input.ansHash.length, 64);
          expect(input.options.isNotEmpty, isTrue);
        }

        // All questions must have text and options
        for (final q in prob.questions) {
          expect(q.text.isNotEmpty, isTrue);
          expect(q.placeholder.isNotEmpty, isTrue);
          expect(q.options.isNotEmpty, isTrue);
        }
      }
    });
  });

  group('Widget Navigation & Screen Tests', () {
    testWidgets('App renders Home, tabs, and navigation items exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const VerilogPlasApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Offline VPLAS'), findsOneWidget);
      expect(find.text('TOP'), findsOneWidget);

      // Verify bottom navigation items exist
      expect(find.text('Problems'), findsWidgets);
      expect(find.text('Submission'), findsWidgets);
      expect(find.text('End'), findsWidgets);

      // Switch to Submission tab via bottom navigation
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Show Record'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Switch to End tab via bottom navigation
      await tester.tap(find.text('End').last);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('End & Session Overview'), findsOneWidget);
    });

    testWidgets('ProblemDetailScreen renders image at the top, code, questions, and handles answer submission',
        (WidgetTester tester) async {
      final problem = Problem(
        id: 1,
        statement: '1',
        name: 'Start',
        knowledgePoint: 'This is a test knowledge point',
        images: ['assets/images/VPLAS_CH1_fig1.png'],
        codeTemplate: 'module start();\n[[BLANK_1]]\nendmodule',
        questions: [
          QuestionItem(
            text: 'Test question 1',
            placeholder: '2',
            blankIndex: 2,
            options: ['foo', 'bar', 'baz', 'qux'],
          ),
        ],
        inputs: [
          BlankInput(
            index: 1,
            placeholder: '1',
            ansHash: PlasEvaluatorService.computeHash('start11'),
            size: 5,
            options: ['start', 'wire', 'reg', 'module'],
          ),
          BlankInput(
            index: 2,
            placeholder: '2',
            ansHash: PlasEvaluatorService.computeHash('foo12'),
            size: 5,
            options: ['foo', 'bar', 'baz', 'qux'],
          ),
        ],
        totalInputs: 2,
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ProblemDetailScreen(problem: problem),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Check title
      expect(find.text('Problem #1: Start'), findsOneWidget);

      // Check image section exists at the top
      expect(find.text('Circuit Diagrams / Waveforms (1)'), findsOneWidget);

      // Check Knowledge Point card
      expect(find.text('This is a test knowledge point'), findsOneWidget);

      // Ensure Answer button is visible and tap it
      await tester.ensureVisible(find.text('Answer'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Answer'));
      await tester.pumpAndSettle();

      // Statistical data should now reflect evaluation
      expect(find.text('0.00%'), findsOneWidget);
      expect(find.text('Total number of questions:'), findsOneWidget);

      // Verify choice chips exist for options
      expect(find.byType(ChoiceChip), findsWidgets);

      // Select correct option 'start' for Blank 1
      await tester.ensureVisible(find.text('A. start').first);
      await tester.tap(find.text('A. start').first);
      await tester.pumpAndSettle();

      // Submit answer again
      await tester.ensureVisible(find.text('Answer'));
      await tester.tap(find.text('Answer'));
      await tester.pumpAndSettle();

      // Accuracy should be 50.00% (1 of 2 correct)
      expect(find.text('50.00%'), findsOneWidget);

      // Tap Clear Answers button in AppBar
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      expect(find.text('Answers cleared'), findsOneWidget);
    });
  });
}
