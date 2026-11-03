import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/problem.dart';
import 'plas_storage_service.dart';
import 'problem_repository.dart';

class SubmissionStudentInfo {
  final String studentId;
  final String studentName;
  final String courseName;
  final DateTime submissionDate;

  SubmissionStudentInfo({
    required this.studentId,
    required this.studentName,
    required this.courseName,
    required this.submissionDate,
  });
}

class QuestionSubmissionItem {
  final int questionIndex;
  final String questionText;
  final String studentAnswer;
  final bool isCorrect;

  QuestionSubmissionItem({
    required this.questionIndex,
    required this.questionText,
    required this.studentAnswer,
    required this.isCorrect,
  });
}

class ProblemSubmissionSummary {
  final int problemId;
  final String statementId;
  final String problemName;
  final DateTime timestamp;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracyRate;
  final bool isCompleted;
  final int attemptCount;
  final List<QuestionSubmissionItem> items;

  ProblemSubmissionSummary({
    required this.problemId,
    required this.statementId,
    required this.problemName,
    required this.timestamp,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracyRate,
    required this.isCompleted,
    required this.attemptCount,
    required this.items,
  });
}

class OverallSubmissionData {
  final SubmissionStudentInfo studentInfo;
  final int totalProblemsAvailable;
  final int problemsAttempted;
  final int problemsCompleted;
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final double overallAccuracyRate;
  final String finalGrade;
  final String sessionHash;
  final List<ProblemSubmissionSummary> problemSummaries;

  OverallSubmissionData({
    required this.studentInfo,
    required this.totalProblemsAvailable,
    required this.problemsAttempted,
    required this.problemsCompleted,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.overallAccuracyRate,
    required this.finalGrade,
    required this.sessionHash,
    required this.problemSummaries,
  });
}

class TxtSubmissionService {
  /// Extracts answers and validity marks [o] / [x] from PLAS storage value
  static List<({String answer, bool isCorrect})> parseStorageValueAnswers(String rawValue) {
    final trimmedVal = rawValue.trim();
    final commaAccIdx = trimmedVal.lastIndexOf(', Accuracy:');
    final itemsStr = commaAccIdx != -1 ? trimmedVal.substring(0, commaAccIdx) : trimmedVal;

    final regex = RegExp(r'(.*?)(?:\[([ox])\])(?:,\s*|$)');
    final results = <({String answer, bool isCorrect})>[];

    for (final match in regex.allMatches(itemsStr)) {
      final ansText = (match.group(1) ?? '').trim();
      final mark = (match.group(2) ?? 'x').toLowerCase();
      results.add((answer: ansText, isCorrect: mark == 'o'));
    }

    return results;
  }

  /// Parses timestamp string formatted as 'YYYY-MM-DD HH:mm:ss'
  static DateTime parseTimestamp(String timestampStr) {
    try {
      final parts = timestampStr.trim().split(' ');
      if (parts.length == 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length >= 2) {
          return DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
          );
        }
      }
    } catch (_) {}
    return DateTime.now();
  }

  /// Calculates final letter grade and descriptive status
  static String calculateGrade(double accuracyRate) {
    if (accuracyRate >= 90.0) {
      return 'EXCELLENT (A)';
    } else if (accuracyRate >= 80.0) {
      return 'VERY GOOD (B+)';
    } else if (accuracyRate >= 70.0) {
      return 'GOOD (B)';
    } else if (accuracyRate >= 60.0) {
      return 'SATISFACTORY (C)';
    } else {
      return 'NEEDS IMPROVEMENT (D)';
    }
  }

  /// Aggregates all student attempts into structured OverallSubmissionData
  static Future<OverallSubmissionData> buildSubmissionData({
    required String studentId,
    String? studentName,
    String? courseName,
    DateTime? now,
  }) async {
    final uid = studentId.trim();
    final name = (studentName ?? '').trim();
    final course = (courseName == null || courseName.trim().isEmpty)
        ? PlasStorageService.defaultCourseName
        : courseName.trim();
    final submissionDate = now ?? DateTime.now();

    final allProblems = await ProblemRepository.getProblems();
    final records = await PlasStorageService.getAllRecords();

    // Calculate authenticity hash
    String sessionHash = 'NO_ATTEMPT_HASH';
    if (records.isNotEmpty) {
      final firstKey = records.first.key;
      final hashInput = '$uid\t$firstKey';
      sessionHash = sha256.convert(utf8.encode(hashInput)).toString().toLowerCase();
    }

    // Map problems by statement string ('1', '2', etc.)
    final problemMap = <String, Problem>{};
    for (final p in allProblems) {
      problemMap[p.statement] = p;
    }

    // Group records by statementId
    final groupedAttempts = <String, List<RecordEntry>>{};
    for (final rec in records) {
      final keyParts = rec.key.split('\t');
      final statementId = keyParts[0].trim();
      groupedAttempts.putIfAbsent(statementId, () => []).add(rec);
    }

    final problemSummaries = <ProblemSubmissionSummary>[];
    int totalQuestionsAnswered = 0;
    int totalCorrectAnswers = 0;
    int problemsCompleted = 0;

    // Process each problem in sequential order
    for (final problem in allProblems) {
      final attempts = groupedAttempts[problem.statement];
      if (attempts == null || attempts.isEmpty) {
        continue; // Unattempted
      }

      // Latest attempt is the last in insertion order
      final latestRecord = attempts.last;
      final keyParts = latestRecord.key.split('\t');
      final attemptTime = keyParts.length > 1
          ? parseTimestamp(keyParts[1])
          : submissionDate;

      final parsedAnswers = parseStorageValueAnswers(latestRecord.value);

      // Build question-level items
      final items = <QuestionSubmissionItem>[];
      int problemCorrect = 0;
      final totalProblemQuestions = problem.questions.isNotEmpty
          ? problem.questions.length
          : problem.inputs.length;

      for (int i = 0; i < totalProblemQuestions; i++) {
        final qText = (i < problem.questions.length)
            ? problem.questions[i].text
            : 'Question #${i + 1}';

        String userAnswer = '[Not Answered]';
        bool isCorrect = false;

        if (i < parsedAnswers.length) {
          userAnswer = parsedAnswers[i].answer;
          isCorrect = parsedAnswers[i].isCorrect;
        }

        if (isCorrect) {
          problemCorrect++;
        }

        items.add(QuestionSubmissionItem(
          questionIndex: i + 1,
          questionText: qText,
          studentAnswer: userAnswer,
          isCorrect: isCorrect,
        ));
      }

      totalQuestionsAnswered += totalProblemQuestions;
      totalCorrectAnswers += problemCorrect;

      final double accRate = totalProblemQuestions > 0
          ? (problemCorrect / totalProblemQuestions) * 100.0
          : 0.0;
      final bool isComp = (problemCorrect == totalProblemQuestions) && totalProblemQuestions > 0;
      if (isComp) {
        problemsCompleted++;
      }

      problemSummaries.add(ProblemSubmissionSummary(
        problemId: problem.id,
        statementId: problem.statement,
        problemName: problem.name,
        timestamp: attemptTime,
        totalQuestions: totalProblemQuestions,
        correctAnswers: problemCorrect,
        accuracyRate: accRate,
        isCompleted: isComp,
        attemptCount: attempts.length,
        items: items,
      ));
    }

    final int problemsAttempted = problemSummaries.length;
    final double overallAccRate = totalQuestionsAnswered > 0
        ? (totalCorrectAnswers / totalQuestionsAnswered) * 100.0
        : 0.0;
    final String finalGrade = calculateGrade(overallAccRate);

    return OverallSubmissionData(
      studentInfo: SubmissionStudentInfo(
        studentId: uid,
        studentName: name.isNotEmpty ? name : 'Student',
        courseName: course,
        submissionDate: submissionDate,
      ),
      totalProblemsAvailable: allProblems.length,
      problemsAttempted: problemsAttempted,
      problemsCompleted: problemsCompleted,
      totalQuestionsAnswered: totalQuestionsAnswered,
      totalCorrectAnswers: totalCorrectAnswers,
      overallAccuracyRate: overallAccRate,
      finalGrade: finalGrade,
      sessionHash: sessionHash,
      problemSummaries: problemSummaries,
    );
  }

  /// Formats date cleanly as "YYYY-MM-DD HH:mm:ss"
  static String formatDateTimeStandard(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  /// Formats human-friendly date with day and month names
  static String formatDateTimeHuman(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');

    return '$dayName, $d $monthName $y, $h:$min:$s';
  }

  /// Generates the human-readable formatted TXT content
  static String formatAsText(OverallSubmissionData data) {
    final buf = StringBuffer();
    final border = '=' * 80;
    final subBorder = '-' * 80;

    buf.writeln(border);
    buf.writeln('                 MOBILE PLAS - VERILOG HDL SUBMISSION REPORT');
    buf.writeln(border);
    buf.writeln();

    // 1. Student & Course Information
    buf.writeln('1. STUDENT & COURSE INFORMATION');
    buf.writeln(subBorder);
    buf.writeln('• Student ID        : ${data.studentInfo.studentId}');
    buf.writeln('• Student Name      : ${data.studentInfo.studentName}');
    buf.writeln('• Course Name       : ${data.studentInfo.courseName}');
    buf.writeln('• Curriculum Chapter: Chapter 1 - Verilog Introduction (22 Problems)');
    buf.writeln('• Submission Date   : ${formatDateTimeHuman(data.studentInfo.submissionDate)}');
    buf.writeln('• Target Platform   : Mobile PLAS (Flutter iOS & Android)');
    buf.writeln();

    // 2. Final Evaluation & Grade Summary
    buf.writeln('2. FINAL EVALUATION & GRADE SUMMARY');
    buf.writeln(subBorder);
    final completionPct = (data.totalProblemsAvailable > 0)
        ? (data.problemsCompleted / data.totalProblemsAvailable * 100.0)
            .toStringAsFixed(1)
        : '0.0';
    buf.writeln('• Total Problems in Chapter : ${data.totalProblemsAvailable} Problems');
    buf.writeln('• Problems Attempted        : ${data.problemsAttempted} / ${data.totalProblemsAvailable}');
    buf.writeln('• Problems Mastered (100%)  : ${data.problemsCompleted} / ${data.totalProblemsAvailable} ($completionPct%)');
    buf.writeln('• Total Questions Answered  : ${data.totalQuestionsAnswered} Questions');
    buf.writeln('• Total Correct Answers     : ${data.totalCorrectAnswers} / ${data.totalQuestionsAnswered}');
    buf.writeln('• Overall Accuracy Score    : ${data.overallAccuracyRate.toStringAsFixed(2)}%');
    buf.writeln('• Final Academic Grade      : ${data.finalGrade}');
    buf.writeln('• Digital Verification Hash : ${data.sessionHash}');
    buf.writeln();

    // 3. Problem Performance Overview Table
    buf.writeln('3. PROBLEM PERFORMANCE OVERVIEW');
    buf.writeln(subBorder);
    buf.writeln(
      'ID   Problem Name               Score    Status       Accuracy  Timestamp',
    );
    buf.writeln(subBorder);

    if (data.problemSummaries.isEmpty) {
      buf.writeln('No problem attempts recorded yet.');
    } else {
      for (final p in data.problemSummaries) {
        final idStr = '#${p.problemId.toString().padLeft(2, '0')}';
        final nameStr = p.problemName.length > 25
            ? '${p.problemName.substring(0, 22)}...'
            : p.problemName.padRight(25, ' ');
        final scoreStr = '${p.correctAnswers}/${p.totalQuestions}'.padRight(8, ' ');
        final statusStr = p.isCompleted ? 'COMPLETED ' : 'TRIED     ';
        final accStr = '${p.accuracyRate.toStringAsFixed(1)}%'.padRight(9, ' ');
        final timeStr = formatDateTimeStandard(p.timestamp);

        buf.writeln('$idStr  $nameStr  $scoreStr $statusStr  $accStr $timeStr');
      }
    }
    buf.writeln(subBorder);
    buf.writeln();

    // 4. Detailed Questions & Answers Breakdown
    buf.writeln('4. DETAILED QUESTIONS & ANSWERS BREAKDOWN');
    buf.writeln(subBorder);

    if (data.problemSummaries.isEmpty) {
      buf.writeln('No detailed records available.');
    } else {
      for (final p in data.problemSummaries) {
        buf.writeln();
        buf.writeln('--------------------------------------------------------------------------------');
        buf.writeln('PROBLEM #${p.problemId.toString().padLeft(2, '0')}: ${p.problemName}');
        buf.writeln('• Latest Attempt  : ${formatDateTimeStandard(p.timestamp)}');
        buf.writeln('• Attempt Count   : ${p.attemptCount} attempt(s)');
        buf.writeln('• Problem Score   : ${p.correctAnswers} / ${p.totalQuestions} Correct (${p.accuracyRate.toStringAsFixed(2)}%)');
        buf.writeln('• Mastery Status  : ${p.isCompleted ? 'PASSED [COMPLETED]' : 'IN PROGRESS [TRIED]'}');
        buf.writeln('Questions & Student Responses:');

        for (final item in p.items) {
          final mark = item.isCorrect ? '[✓] CORRECT' : '[✗] INCORRECT';
          buf.writeln('  [Q${item.questionIndex}] ${item.questionText}');
          buf.writeln('       Student Answer : ${item.studentAnswer}');
          buf.writeln('       Evaluation     : $mark');
        }
      }
    }

    buf.writeln();
    buf.writeln(border);
    buf.writeln('                    END OF SUBMISSION REPORT - MOBILE PLAS');
    buf.writeln('         Generated via Okayama University PLAS Architecture for Verilog');
    buf.writeln(border);

    return buf.toString();
  }

  /// Generates a clean, system-safe, unique filename
  static String generateUniqueFilename({
    required String studentId,
    String courseCode = 'VerilogHDL',
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final sanitizedId = studentId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final sanitizedCourse = courseCode.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');

    final id = sanitizedId.isNotEmpty ? sanitizedId : 'Student';
    final course = sanitizedCourse.isNotEmpty ? sanitizedCourse : 'Verilog';

    final datePart = '$y$m$d';
    final timePart = '$h$min$s';
    return 'Submission_${id}_${course}_${datePart}_$timePart.txt';
  }

  /// Saves the submission TXT to disk and attempts to also save to Downloads
  static Future<File> saveSubmissionToFile({
    required String filename,
    required String content,
  }) async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = Directory.systemTemp;
      }
    }

    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, flush: true);

    // If on Android, try copying to public Downloads directory for easy user access
    try {
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (downloadDir.existsSync()) {
          final downloadFile = File('${downloadDir.path}/$filename');
          await downloadFile.writeAsString(content, flush: true);
        }
      }
    } catch (_) {
      // Ignored if external storage is inaccessible
    }

    return file;
  }

  /// Shares the submission TXT file via Email, Microsoft Teams, WhatsApp, etc.
  static Future<void> shareSubmissionFile({
    required File file,
    required SubmissionStudentInfo studentInfo,
    Rect? sharePositionOrigin,
  }) async {
    final filename = file.path.split(Platform.pathSeparator).last;
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      subject: 'Submission ${studentInfo.courseName} - ${studentInfo.studentName} (${studentInfo.studentId})',
      text: 'PLAS Verilog HDL Submission File\nStudent: ${studentInfo.studentName} (${studentInfo.studentId})\nCourse: ${studentInfo.courseName}\nFile: $filename',
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
