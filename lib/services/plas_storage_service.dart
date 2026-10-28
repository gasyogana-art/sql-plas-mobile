import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/evaluation_result.dart';

enum ProblemStatus {
  notAttempted,
  tried,
  completed,
}

class RecordEntry {
  final String key;
  final String value;

  RecordEntry({required this.key, required this.value});
}

class PlasStorageService {
  static const String _recordPrefix = 'plas_rec:';
  static const String _keysOrderKey = 'plas_rec_keys_order';
  static const String _studentIdKey = 'plas_student_id';

  /// Save an evaluation attempt
  static Future<void> saveAttempt(EvaluationResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = result.storageKey;
    final value = result.storageValue;

    // Save record with prefix
    await prefs.setString('$_recordPrefix$key', value);

    // Maintain insertion order of keys
    final keys = prefs.getStringList(_keysOrderKey) ?? [];
    if (!keys.contains(key)) {
      keys.add(key);
      await prefs.setStringList(_keysOrderKey, keys);
    }
  }

  /// Get all stored record entries in order
  static Future<List<RecordEntry>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList(_keysOrderKey) ?? [];
    final List<RecordEntry> records = [];

    for (final k in keys) {
      final val = prefs.getString('$_recordPrefix$k');
      if (val != null) {
        records.add(RecordEntry(key: k, value: val));
      }
    }
    return records;
  }

  /// Replicates distinction.js statusConfirm()
  /// Returns a map of statement_id -> ProblemStatus
  static Future<Map<String, ProblemStatus>> getProblemsStatus() async {
    final records = await getAllRecords();
    final Map<String, ProblemStatus> statusMap = {};

    for (final record in records) {
      final problemId = record.key.split('\t')[0].trim();
      final hasError = record.value.contains('[x]');

      if (!hasError) {
        statusMap[problemId] = ProblemStatus.completed;
      } else {
        if (statusMap[problemId] != ProblemStatus.completed) {
          statusMap[problemId] = ProblemStatus.tried;
        }
      }
    }

    return statusMap;
  }

  /// Get saved student ID
  static Future<String> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_studentIdKey) ?? '';
  }

  /// Set saved student ID
  static Future<void> setStudentId(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_studentIdKey, studentId.trim());
  }

  /// Replicates expression() from storage.js
  static Future<String> generateRecordText(String studentId) async {
    final uid = studentId.trim();
    if (uid.isEmpty) {
      return 'Fill in Student ID';
    }

    if (uid.toLowerCase() == 'r207clear') {
      await clearRecords();
      return 'Records cleared via r207clear';
    }

    final records = await getAllRecords();
    if (records.isEmpty) {
      return 'No records found. Please answer some problems first.';
    }

    // hash = uid + "\t" + storage.key(0)
    final firstKey = records.first.key;
    final hashInput = '$uid\t$firstKey';
    final hashid = sha256.convert(utf8.encode(hashInput)).toString().toLowerCase();

    // result += uid + "\t" + arr + "" + localStorage.getItem(arr) + "\n"
    final buffer = StringBuffer();
    buffer.writeln(hashid);

    for (final record in records) {
      buffer.writeln('$uid\t${record.key}${record.value}');
    }

    return buffer.toString().trimRight();
  }

  /// Replicates TextSave() from storage.js
  /// Saves `V_CH1_<uid>.txt`, exports/shares it, and clears storage.
  static Future<File> saveRecordToFile({
    required String studentId,
    required String recordContent,
    bool clearAfterSave = false,
  }) async {
    final uid = studentId.trim();
    final filename = 'V_CH1_$uid.txt';

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
    await file.writeAsString(recordContent, flush: true);

    if (clearAfterSave) {
      await clearRecords();
    }

    return file;
  }

  /// Share file via system share dialog (WhatsApp, Email, Drive, Save to Files, etc.)
  /// [sharePositionOrigin] is required on iOS / iPadOS to anchor the share popover sheet and prevent crashes.
  static Future<File> shareRecordFile({
    required String studentId,
    required String recordContent,
    bool clearAfterShare = false,
    Rect? sharePositionOrigin,
  }) async {
    final file = await saveRecordToFile(
      studentId: studentId,
      recordContent: recordContent,
      clearAfterSave: clearAfterShare,
    );

    try {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/plain')],
        subject: '$studentId:PLAS Verilog Record',
        text: 'VPLAS Verilog Record for Student ID: $studentId',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (_) {
      // If sharing dialog is not available on emulator, file is still safely saved
    }

    return file;
  }

  /// Replicates cle() from storage.js
  static Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList(_keysOrderKey) ?? [];

    for (final k in keys) {
      await prefs.remove('$_recordPrefix$k');
    }
    await prefs.remove(_keysOrderKey);
  }
}
