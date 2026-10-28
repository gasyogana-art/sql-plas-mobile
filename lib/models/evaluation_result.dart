class BlankResult {
  final int index;
  final String userAnswer;
  final bool isCorrect;
  final String placeholder;

  BlankResult({
    required this.index,
    required this.userAnswer,
    required this.isCorrect,
    required this.placeholder,
  });
}

class EvaluationResult {
  final String statementId;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracyRate;
  final String accuracyRateString;
  final List<BlankResult> blankResults;
  final DateTime timestamp;

  EvaluationResult({
    required this.statementId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracyRate,
    required this.accuracyRateString,
    required this.blankResults,
    required this.timestamp,
  });

  /// Format key matching PLAS scoring.js:
  /// qid.innerHTML + "\t" + YYYY-MM-DD HH:mm:ss
  String get storageKey {
    final y = timestamp.year.toString().padLeft(4, '0');
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    final h = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$statementId\t$y-$m-$d $h:$min:$s';
  }

  /// Format value matching PLAS scoring.js:
  /// `\t`ans1[o],ans2[x], Accuracy:XX.XX%
  String get storageValue {
    final items = blankResults.map((r) {
      final mark = r.isCorrect ? '[o]' : '[x]';
      return '${r.userAnswer}$mark';
    }).join(',');
    return '\t$items, Accuracy:$accuracyRateString';
  }

  bool get isAllCorrect => correctAnswers == totalQuestions && totalQuestions > 0;
}
