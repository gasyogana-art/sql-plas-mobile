import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../models/evaluation_result.dart';
import '../theme/app_theme.dart';

class VerilogCodeView extends StatelessWidget {
  final Problem problem;
  final Map<int, TextEditingController> controllers;
  final EvaluationResult? lastEvaluation;

  const VerilogCodeView({
    super.key,
    required this.problem,
    required this.controllers,
    this.lastEvaluation,
  });

  @override
  Widget build(BuildContext context) {
    if (problem.codeTemplate.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final lines = problem.codeTemplate.split('\n');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.codeBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar simulating code editor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF21252B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F56),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFBD2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27C93F),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Verilog HDL Code',
                  style: TextStyle(
                    color: Color(0xFFABB2BF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Code lines content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lines.length, (lineIndex) {
                  return _buildLine(context, lines[lineIndex], lineIndex + 1);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(BuildContext context, String line, int lineNum) {
    // Check if line contains [[BLANK_X]]
    final blankRegex = RegExp(r'\[\[BLANK_([^\]]+)\]\]');
    final matches = blankRegex.allMatches(line);

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLineNumber(lineNum),
            _buildSyntaxHighlightedText(line),
          ],
        ),
      );
    }

    // Line contains one or more blanks
    final children = <Widget>[];
    children.add(_buildLineNumber(lineNum));

    int lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        children.add(_buildSyntaxHighlightedText(line.substring(lastIndex, match.start)));
      }

      final placeholder = match.group(1) ?? '1';
      // Find blank corresponding to placeholder
      final blank = problem.inputs.firstWhere(
        (b) => b.placeholder == placeholder,
        orElse: () => BlankInput(
          index: int.tryParse(placeholder) ?? 1,
          placeholder: placeholder,
          ansHash: '',
          size: 2,
        ),
      );

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: _buildInlineBlankField(context, blank),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      children.add(_buildSyntaxHighlightedText(line.substring(lastIndex)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _buildLineNumber(int num) {
    return Container(
      width: 28,
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(right: 12),
      child: Text(
        '$num',
        style: const TextStyle(
          color: Color(0xFF5C6370),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildSyntaxHighlightedText(String text) {
    final spans = <TextSpan>[];
    final tokenRegex = RegExp(r'(\b\w+\b|[^\w\s]+|\s+)');
    final allTokens = tokenRegex.allMatches(text);

    for (final m in allTokens) {
      final token = m.group(0)!;
      Color color = const Color(0xFFABB2BF); // Default light grey

      if (const [
        'module',
        'endmodule',
        'input',
        'output',
        'wire',
        'reg',
        'assign',
        'always',
        'begin',
        'end',
        'posedge',
        'negedge',
        'and',
        'or',
        'not',
        'xor'
      ].contains(token)) {
        color = const Color(0xFFC678DD); // Purple for keywords
      } else if (token.startsWith('//')) {
        color = const Color(0xFF5C6370); // Grey comments
      } else if (RegExp(r'^\d+').hasMatch(token)) {
        color = const Color(0xFFD19A66); // Orange numbers
      } else if (['(', ')', ';', ',', '='].contains(token)) {
        color = const Color(0xFF56B6C2); // Cyan punctuation
      }

      spans.add(TextSpan(
        text: token,
        style: TextStyle(
          color: color,
          fontSize: 13.5,
          fontFamily: 'monospace',
          fontWeight: color == const Color(0xFFC678DD) ? FontWeight.w600 : FontWeight.normal,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _showOptionsPicker(BuildContext context, BlankInput blank, TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Multiple Choice: Blank [${blank.placeholder}]',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                ...List.generate(blank.options.length, (optIdx) {
                  final opt = blank.options[optIdx];
                  final prefix = String.fromCharCode(65 + optIdx);
                  final isSelected = controller.text.trim() == opt;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? AppTheme.primary : Colors.grey.shade200,
                      child: Text(
                        prefix,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      opt,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                    onTap: () {
                      controller.text = opt;
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  },
    );
  }

  Widget _buildInlineBlankField(BuildContext context, BlankInput blank) {
    final controller = controllers[blank.index];
    if (controller == null) return const SizedBox.shrink();

    // Determine state color from lastEvaluation
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFF90A4AE);

    if (lastEvaluation != null) {
      final res = lastEvaluation!.blankResults.firstWhere(
        (r) => r.index == blank.index,
        orElse: () => BlankResult(
          index: blank.index,
          userAnswer: '',
          isCorrect: false,
          placeholder: blank.placeholder,
        ),
      );
      if (res.isCorrect) {
        bgColor = AppTheme.inputCorrectBg;
        borderColor = AppTheme.inputCorrectBorder;
      } else {
        bgColor = AppTheme.inputIncorrectBg; // Pink
        borderColor = AppTheme.inputIncorrectBorder;
      }
    }

    final hasOptions = blank.options.isNotEmpty;
    final currentVal = controller.text.trim();
    final displayText = currentVal.isNotEmpty ? currentVal : blank.placeholder;

    if (hasOptions) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOptionsPicker(context, blank, controller),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minWidth: 68, minHeight: 30),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  displayText,
                  style: TextStyle(
                    color: currentVal.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
              ],
            ),
          ),
        ),
      );
    }

    final width = (blank.size * 18.0).clamp(70.0, 140.0);
    return SizedBox(
      width: width,
      height: 32,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: blank.placeholder,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          filled: true,
          fillColor: bgColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
