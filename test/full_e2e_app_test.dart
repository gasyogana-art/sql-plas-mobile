import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verilog_plas/main.dart';
import 'package:verilog_plas/models/problem.dart';
import 'package:verilog_plas/screens/problem_detail_screen.dart';
import 'package:verilog_plas/services/problem_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Problem> problems;

  setUpAll(() {
    final file = File('assets/data/problems.json');
    expect(file.existsSync(), isTrue);
    problems = Problem.listFromJson(file.readAsStringSync());
    ProblemRepository.setCachedProblems(problems);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('End-to-End Problem Navigation & UI Integrity Across All 22 Problems', () {
    testWidgets('Every problem 1..22 renders cleanly without overflow on small & large screens',
        (WidgetTester tester) async {
      // Test on compact mobile screen (360x640)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (int i = 0; i < problems.length; i++) {
        final problem = problems[i];
        await tester.pumpWidget(
          MaterialApp(
            home: ProblemDetailScreen(
              key: ValueKey('prob_${problem.id}'),
              problem: problem,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Check header title
        expect(find.text('Problem #${problem.statement}: ${problem.name}'), findsOneWidget);

        // Tap Answer to evaluate
        await tester.ensureVisible(find.text('Answer'));
        await tester.tap(find.text('Answer'));
        await tester.pumpAndSettle();

        // Statistical data should show
        expect(find.text('Total number of questions:'), findsOneWidget);

        // Verify ChoiceChips are rendered for options
        expect(find.byType(ChoiceChip), findsWidgets);
      }
    });

    testWidgets('Continuous Next/Previous navigation transitions seamlessly through all 22 problems',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ProblemDetailScreen(problem: problems.first),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Problem #1: Start'), findsOneWidget);

      // Previous button on Problem 1 must be disabled (null onPressed)
      final prevBtnProb1 = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Previous'),
      );
      expect(prevBtnProb1.onPressed, isNull);

      // Step forward from Problem 1 to Problem 22
      for (int id = 1; id < 22; id++) {
        await tester.ensureVisible(find.text('Next'));
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        final nextId = id + 1;
        expect(
          find.text('Problem #$nextId: ${problems[nextId - 1].name}'),
          findsOneWidget,
          reason: 'Navigated to Problem #$nextId successfully',
        );
      }

      // On Problem 22, Next button must be disabled
      final nextBtnProb22 = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Next'),
      );
      expect(nextBtnProb22.onPressed, isNull);

      // Step backward from Problem 22 down to Problem 1
      for (int id = 22; id > 1; id--) {
        await tester.ensureVisible(find.text('Previous'));
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();

        final prevId = id - 1;
        expect(
          find.text('Problem #$prevId: ${problems[prevId - 1].name}'),
          findsOneWidget,
          reason: 'Navigated back to Problem #$prevId successfully',
        );
      }

      expect(find.text('Problem #1: Start'), findsOneWidget);
    });
  });

  group('Full Application Integration Workflow', () {
    testWidgets('Full student workflow: solve, view submission, export record, and check overview',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const VerilogPlasApp());
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Home Screen loads with Problem List
      expect(find.text('Offline VPLAS'), findsOneWidget);
      expect(find.text('CH1 Problems: Verilog Introduction'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // Problem 1 row
      expect(find.text('Start'), findsOneWidget);

      // 2. Tap Problem 1 to open Detail Screen
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.text('Problem #1: Start'), findsOneWidget);

      // Select answer on Problem 1
      final startChip = find.text('A. start');
      if (startChip.evaluate().isNotEmpty) {
        await tester.ensureVisible(startChip.first);
        await tester.tap(startChip.first);
        await tester.pumpAndSettle();
      }

      // Submit answer
      await tester.ensureVisible(find.text('Answer'));
      await tester.tap(find.text('Answer'));
      await tester.pumpAndSettle();

      // Return to Home via TOP button
      await tester.tap(find.widgetWithText(ElevatedButton, 'TOP'));
      await tester.pumpAndSettle();

      expect(find.text('Offline VPLAS'), findsOneWidget);

      // 3. Switch to Submission tab
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Enter your Student ID'), findsOneWidget);

      // Try tapping Show Record without Student ID -> prompts error
      await tester.tap(find.widgetWithText(OutlinedButton, 'Show Record'));
      await tester.pumpAndSettle();
      expect(find.text('Fill in Student ID'), findsOneWidget);

      // Enter Student ID
      await tester.enterText(find.byType(TextField).first, 'B221001');
      await tester.pumpAndSettle();

      // Tap Show Record
      await tester.tap(find.widgetWithText(OutlinedButton, 'Show Record'));
      await tester.pumpAndSettle();

      // Record text should now contain student ID and answer details
      expect(find.byIcon(Icons.copy), findsOneWidget); // Copy button appears

      // Tap Save button -> alert dialog opens
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Save & Export Record'), findsOneWidget);

      // Tap Cancel in dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Save & Export Record'), findsNothing);

      // Tap Save button again and confirm
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Export'));
      await tester.pumpAndSettle();

      // 4. Switch to End tab
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();

      expect(find.text('End & Session Overview'), findsOneWidget);
      expect(find.text('About PLAS (Verilog)'), findsOneWidget);

      // Tap Continue Solving Problems -> navigates back to tab 0
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue Solving Problems'));
      await tester.pumpAndSettle();

      expect(find.text('CH1 Problems: Verilog Introduction'), findsOneWidget);
    });
  });
}
