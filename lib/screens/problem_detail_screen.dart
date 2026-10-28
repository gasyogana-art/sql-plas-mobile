import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../models/evaluation_result.dart';
import '../services/plas_evaluator_service.dart';
import '../services/plas_storage_service.dart';
import '../services/problem_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/verilog_code_view.dart';
import '../widgets/circuit_diagram_viewer.dart';

class ProblemDetailScreen extends StatefulWidget {
  final Problem problem;

  const ProblemDetailScreen({super.key, required this.problem});

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  late Problem _currentProblem;
  final Map<int, TextEditingController> _controllers = {};
  final ScrollController _scrollController = ScrollController();
  EvaluationResult? _lastEvaluation;
  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    _loadProblem(widget.problem);
  }

  @override
  void didUpdateWidget(ProblemDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problem.id != widget.problem.id) {
      _loadProblem(widget.problem);
    }
  }

  void _loadProblem(Problem problem) {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _currentProblem = problem;
    _lastEvaluation = null;
    for (final blank in problem.inputs) {
      final ctrl = TextEditingController();
      ctrl.addListener(() {
        if (mounted) setState(() {});
      });
      _controllers[blank.index] = ctrl;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleAnswer() async {
    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() => _isEvaluating = true);
    }

    // Extract answers
    final answers = <int, String>{};
    for (final entry in _controllers.entries) {
      answers[entry.key] = entry.value.text;
    }

    // Evaluate using SHA-256
    final result = PlasEvaluatorService.evaluateProblem(
      problem: _currentProblem,
      userAnswers: answers,
    );

    // Persist attempt to storage
    await PlasStorageService.saveAttempt(result);

    if (mounted) {
      setState(() {
        _lastEvaluation = result;
        _isEvaluating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isAllCorrect
                ? 'All correct! Accuracy: ${result.accuracyRateString}'
                : 'Scored: ${result.correctAnswers}/${result.totalQuestions} correct (${result.accuracyRateString})',
          ),
          backgroundColor: result.isAllCorrect
              ? const Color(0xFF1BBC9B)
              : (result.accuracyRate >= 60 ? Colors.orange.shade800 : Colors.red.shade700),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToProblem(int targetId) async {
    if (targetId < 1 || targetId > 22) return;
    final nextProb = await ProblemRepository.getProblemById(targetId);
    if (nextProb != null && mounted) {
      setState(() {
        _loadProblem(nextProb);
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Problem #${_currentProblem.statement}: ${_currentProblem.name}'),
        actions: [
          IconButton(
            tooltip: 'Clear Answers',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() {
                for (final c in _controllers.values) {
                  c.clear();
                }
                _lastEvaluation = null;
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Answers cleared'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
              label: const Text('TOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.topButtonColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 36),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Circuit diagrams at the very top
              if (_currentProblem.images.isNotEmpty) ...[
                CircuitDiagramViewer(images: _currentProblem.images),
                const SizedBox(height: 16),
              ],

              // Knowledge point box if available
              if (_currentProblem.knowledgePoint.isNotEmpty) ...[
                _buildKnowledgePointCard(),
                const SizedBox(height: 16),
              ],

              // Verilog code view with inline blanks
              VerilogCodeView(
                problem: _currentProblem,
                controllers: _controllers,
                lastEvaluation: _lastEvaluation,
              ),

              const SizedBox(height: 16),

              // Code blanks options card if there are blanks with options in code
              if (_currentProblem.inputs.any((i) =>
                  i.options.isNotEmpty &&
                  _currentProblem.codeTemplate.contains('[[BLANK_${i.placeholder}]]'))) ...[
                _buildCodeBlanksOptionsCard(),
                const SizedBox(height: 16),
              ],

              // Questions list (if there are sub-questions)
              if (_currentProblem.questions.isNotEmpty) ...[
                _buildQuestionsSection(),
                const SizedBox(height: 16),
              ],

              // Statistical Data card
              _buildStatisticalDataCard(),

              const SizedBox(height: 16),

              // Answer Button
              _buildAnswerButton(),

              const SizedBox(height: 24),

              // Navigation row (Previous & Next Problem)
              _buildNavigationRow(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKnowledgePointCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBEE5EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFF0C5460), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Knowledge Point',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C5460),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _currentProblem.knowledgePoint,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0C5460),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Questions (${_currentProblem.questions.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...List.generate(_currentProblem.questions.length, (idx) {
              final q = _currentProblem.questions[idx];
              final blankIndex = q.blankIndex ?? (idx + 1);
              return _buildQuestionItem(q, blankIndex);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBlanksOptionsCard() {
    final codeBlanks = _currentProblem.inputs.where((inp) {
      return _currentProblem.codeTemplate.contains('[[BLANK_${inp.placeholder}]]') &&
          inp.options.isNotEmpty;
    }).toList();

    if (codeBlanks.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.fact_check_outlined, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Multiple Choice: Code Blanks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          ...codeBlanks.map((blank) {
            final controller = _controllers[blank.index];
            final currentVal = controller?.text.trim() ?? '';
            BlankResult? evalResult;
            if (_lastEvaluation != null) {
              evalResult = _lastEvaluation!.blankResults.firstWhere(
                (r) => r.index == blank.index,
                orElse: () => BlankResult(
                  index: blank.index,
                  userAnswer: '',
                  isCorrect: false,
                  placeholder: blank.placeholder,
                ),
              );
            }

            Color statusBg = Colors.grey.shade100;
            Color statusBorder = Colors.grey.shade300;
            Color statusTextColor = AppTheme.primary;
            if (evalResult != null) {
              statusBg = evalResult.isCorrect ? AppTheme.inputCorrectBg : AppTheme.inputIncorrectBg;
              statusBorder = evalResult.isCorrect ? AppTheme.inputCorrectBorder : AppTheme.inputIncorrectBorder;
              statusTextColor = evalResult.isCorrect ? const Color(0xFF0F5132) : const Color(0xFF842029);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Blank [${blank.placeholder}]',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      if (currentVal.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            border: Border.all(color: statusBorder),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentVal,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        if (evalResult != null)
                          Icon(
                            evalResult.isCorrect ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: evalResult.isCorrect ? const Color(0xFF1BBC9B) : Colors.red,
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: List.generate(blank.options.length, (optIdx) {
                      final opt = blank.options[optIdx];
                      final isSelected = currentVal == opt;
                      final labelPrefix = String.fromCharCode(65 + optIdx);
                      Color chipSelectedColor = AppTheme.primary;
                      if (isSelected && evalResult != null) {
                        chipSelectedColor = evalResult.isCorrect
                            ? const Color(0xFF1BBC9B)
                            : const Color(0xFFE53935);
                      }
                      return ChoiceChip(
                        label: Text(
                          '$labelPrefix. $opt',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: chipSelectedColor,
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (_) {
                          setState(() {
                            controller?.text = opt;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(QuestionItem q, int blankIndex) {
    final controller = _controllers[blankIndex];
    final currentVal = controller?.text.trim() ?? '';

    BlankResult? evalResult;
    if (_lastEvaluation != null) {
      evalResult = _lastEvaluation!.blankResults.firstWhere(
        (r) => r.index == blankIndex,
        orElse: () => BlankResult(
          index: blankIndex,
          userAnswer: '',
          isCorrect: false,
          placeholder: q.placeholder,
        ),
      );
    }

    Color statusBg = Colors.grey.shade100;
    Color statusBorder = Colors.grey.shade300;
    Color statusTextColor = AppTheme.primary;
    if (evalResult != null) {
      statusBg = evalResult.isCorrect ? AppTheme.inputCorrectBg : AppTheme.inputIncorrectBg;
      statusBorder = evalResult.isCorrect ? AppTheme.inputCorrectBorder : AppTheme.inputIncorrectBorder;
      statusTextColor = evalResult.isCorrect ? const Color(0xFF0F5132) : const Color(0xFF842029);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B2B2B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Blank [${q.placeholder}]',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (currentVal.isNotEmpty) ...[
                Text(
                  'Selected: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    border: Border.all(color: statusBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    currentVal,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: statusTextColor,
                    ),
                  ),
                ),
                if (evalResult != null)
                  Icon(
                    evalResult.isCorrect ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: evalResult.isCorrect ? const Color(0xFF1BBC9B) : Colors.red,
                  ),
              ] else ...[
                Text(
                  'Select an option below:',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
          if (q.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(q.options.length, (optIdx) {
                final opt = q.options[optIdx];
                final isSelected = currentVal == opt;
                final labelPrefix = String.fromCharCode(65 + optIdx);
                Color chipSelectedColor = AppTheme.primary;
                if (isSelected && evalResult != null) {
                  chipSelectedColor = evalResult.isCorrect
                      ? const Color(0xFF1BBC9B)
                      : const Color(0xFFE53935);
                }

                return ChoiceChip(
                  label: Text(
                    '$labelPrefix. $opt',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12.5,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: chipSelectedColor,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) {
                    setState(() {
                      controller?.text = opt;
                    });
                  },
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticalDataCard() {
    final eval = _lastEvaluation;
    final accuracyRate = eval?.accuracyRate ?? 0.0;
    final color = eval != null
        ? PlasEvaluatorService.getAccuracyColor(accuracyRate)
        : Colors.grey.shade700;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Statistical Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Total number of questions:', style: TextStyle(fontSize: 13)),
              ),
              Text(
                '${_currentProblem.totalInputs}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text('Number of correct answers:', style: TextStyle(fontSize: 13)),
              ),
              Text(
                eval != null ? '${eval.correctAnswers}' : '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text('Accuracy rate:', style: TextStyle(fontSize: 13)),
              ),
              Text(
                eval != null ? eval.accuracyRateString : '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton() {
    return ElevatedButton.icon(
      icon: _isEvaluating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.check_circle_outline, color: Colors.white),
      label: const Text(
        'Answer',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      onPressed: _isEvaluating ? null : _handleAnswer,
    );
  }

  Widget _buildNavigationRow() {
    final prevId = _currentProblem.id - 1;
    final nextId = _currentProblem.id + 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: prevId >= 1 ? () => _navigateToProblem(prevId) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: nextId <= 22 ? () => _navigateToProblem(nextId) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Next'),
                SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
