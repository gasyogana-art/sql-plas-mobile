import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:verilog_plas/models/problem.dart';
import 'package:verilog_plas/services/plas_evaluator_service.dart';

void main() {
  group('Comprehensive One-by-One Problem & English Language Audit', () {
    late List<Problem> problems;
    final cjkRegex = RegExp(r'[\u3000-\u303f\u3040-\u309f\u30a0-\u30ff\uff00-\uffef\u4e00-\u9faf]');
    final indonesianKeywords = [
      'jawaban',
      'soal',
      'pilihlah',
      'pilihan',
      'benar',
      'salah',
      'simpan',
      'rekam',
      'selesai',
      'masukkan',
      'isi',
      'tutup',
      'kode',
      'berikut',
      'adalah',
      'untuk',
      'dengan',
      'pada',
      'yang',
      'dari',
    ];

    setUpAll(() {
      final file = File('assets/data/problems.json');
      expect(file.existsSync(), isTrue);
      problems = Problem.listFromJson(file.readAsStringSync());
    });

    test('Total problems count is 22', () {
      expect(problems.length, 22);
    });

    for (int pIdx = 0; pIdx < 22; pIdx++) {
      final expectedId = pIdx + 1;
      test('Audit Problem #$expectedId in detail', () {
        final prob = problems[pIdx];

        expect(prob.id, expectedId, reason: 'Problem index matches ID');
        expect(prob.statement, '$expectedId', reason: 'Statement matches ID');
        expect(prob.name.trim().isNotEmpty, isTrue, reason: 'Problem name must not be empty');

        // Check CJK characters in Problem
        final questionsStr = prob.questions.map((q) => '${q.text} ${q.options.join(" ")}').join(' ');
        final inputsStr = prob.inputs.map((b) => b.options.join(' ')).join(' ');
        final fullProblemText = '${prob.name} ${prob.knowledgePoint} ${prob.codeTemplate} $questionsStr $inputsStr';

        final cjkMatches = cjkRegex.allMatches(fullProblemText).toList();
        expect(
          cjkMatches.isEmpty,
          isTrue,
          reason: 'Problem #$expectedId must NOT contain Japanese/CJK characters: ${cjkMatches.map((m) => m.group(0)).toList()}',
        );

        // Check Indonesian words in question texts and knowledge points
        final qTextStr = prob.questions.map((q) => q.text).join(' ');
        final checkText = '${prob.knowledgePoint} $qTextStr';
        final lowerCheckText = ' $checkText '.toLowerCase();
        for (final word in indonesianKeywords) {
          final wordRegex = RegExp('\\b$word\\b', caseSensitive: false);
          expect(
            wordRegex.hasMatch(lowerCheckText),
            isFalse,
            reason: 'Problem #$expectedId must be in English, but contains Indonesian word: "$word" in: "$checkText"',
          );
        }

        // Verify all referenced images exist
        for (final img in prob.images) {
          expect(File(img).existsSync(), isTrue, reason: 'Image $img for Problem #$expectedId must exist');
        }

        // Verify code template has corresponding blank placeholders
        expect(prob.inputs.isNotEmpty, isTrue, reason: 'Problem #$expectedId must have blanks');

        // Audit each blank input
        for (final blank in prob.inputs) {
          expect(blank.index > 0, isTrue);
          expect(blank.placeholder.isNotEmpty, isTrue);
          expect(blank.ansHash.length, 64, reason: 'Blank ${blank.placeholder} must have valid 64-char SHA256 hash');
          expect(blank.options.length >= 2, isTrue, reason: 'Blank ${blank.placeholder} must have at least 2 options');

          // Verify options are distinct
          final uniqueOptions = blank.options.toSet();
          expect(
            uniqueOptions.length,
            blank.options.length,
            reason: 'Blank ${blank.placeholder} in Problem #$expectedId should not have duplicate options: ${blank.options}',
          );

          // Verify exact SHA-256 match exists in options
          int correctMatches = 0;
          String? correctOpt;
          for (final opt in blank.options) {
            final hash = PlasEvaluatorService.computeHash('$opt${prob.statement}${blank.index}');
            if (hash == blank.ansHash) {
              correctMatches++;
              correctOpt = opt;
            }
          }

          expect(
            correctMatches,
            1,
            reason: 'Problem #$expectedId Blank [${blank.placeholder}] must have EXACTLY 1 correct option (found: $correctMatches, correct: $correctOpt) among ${blank.options}',
          );
        }

        // Audit questions
        for (final q in prob.questions) {
          expect(q.text.trim().isNotEmpty, isTrue);
          expect(q.placeholder.trim().isNotEmpty, isTrue);
          expect(q.options.isNotEmpty, isTrue);

          // Map to blank
          final blank = prob.inputs.firstWhere(
            (b) => b.placeholder == q.placeholder || b.index == q.blankIndex,
            orElse: () => throw Exception('Question placeholder ${q.placeholder} not found in blanks'),
          );
          expect(blank, isNotNull);
        }
      });
    }
  });
}
