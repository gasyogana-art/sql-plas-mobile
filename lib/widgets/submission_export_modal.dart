import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/plas_storage_service.dart';
import '../services/txt_submission_service.dart';
import '../theme/app_theme.dart';

class SubmissionExportModal extends StatefulWidget {
  const SubmissionExportModal({super.key});

  /// Displays the submission export modal as a Material Design 3 bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SubmissionExportModal(),
    );
  }

  @override
  State<SubmissionExportModal> createState() => _SubmissionExportModalState();
}

class _SubmissionExportModalState extends State<SubmissionExportModal> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();

  final GlobalKey _shareButtonKey = GlobalKey();

  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;

  OverallSubmissionData? _submissionData;
  String? _generatedText;
  String? _uniqueFilename;
  File? _savedFile;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final studentId = await PlasStorageService.getStudentId();
    final studentName = await PlasStorageService.getStudentName();
    final courseName = await PlasStorageService.getCourseName();

    if (mounted) {
      _studentIdController.text = studentId;
      _studentNameController.text = studentName;
      _courseNameController.text = courseName;

      setState(() => _isLoading = false);

      // If student ID is already filled, automatically build preview
      if (studentId.trim().isNotEmpty) {
        _generateSubmission();
      }
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    _courseNameController.dispose();
    super.dispose();
  }

  Future<void> _generateSubmission() async {
    final studentId = _studentIdController.text.trim();
    final studentName = _studentNameController.text.trim();
    final courseName = _courseNameController.text.trim();

    if (studentId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Student ID first.';
        _generatedText = null;
        _submissionData = null;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Save credentials for subsequent sessions
      await PlasStorageService.setStudentId(studentId);
      await PlasStorageService.setStudentName(studentName);
      await PlasStorageService.setCourseName(courseName);

      final records = await PlasStorageService.getAllRecords();
      if (records.isEmpty) {
        setState(() {
          _isGenerating = false;
          _errorMessage =
              'No problem attempts found. Please solve some problems before generating submission.';
          _generatedText = null;
          _submissionData = null;
        });
        return;
      }

      final data = await TxtSubmissionService.buildSubmissionData(
        studentId: studentId,
        studentName: studentName.isNotEmpty ? studentName : 'Student',
        courseName: courseName.isNotEmpty ? courseName : PlasStorageService.defaultCourseName,
      );

      final text = TxtSubmissionService.formatAsText(data);
      final filename = TxtSubmissionService.generateUniqueFilename(
        studentId: studentId,
        courseCode: 'VerilogHDL',
        timestamp: data.studentInfo.submissionDate,
      );

      if (mounted) {
        setState(() {
          _submissionData = data;
          _generatedText = text;
          _uniqueFilename = filename;
          _savedFile = null;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Error generating submission: $e';
        });
      }
    }
  }

  Future<void> _handleSaveToDevice() async {
    if (_generatedText == null || _uniqueFilename == null) return;

    try {
      final file = await TxtSubmissionService.saveSubmissionToFile(
        filename: _uniqueFilename!,
        content: _generatedText!,
      );

      setState(() => _savedFile = file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1BBC9B),
            content: Text(
              'File saved successfully:\n${file.path}',
              style: const TextStyle(fontSize: 12),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'COPY PATH',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to save file: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    if (_savedFile == null && _generatedText != null && _uniqueFilename != null) {
      _savedFile = await TxtSubmissionService.saveSubmissionToFile(
        filename: _uniqueFilename!,
        content: _generatedText!,
      );
    }

    if (_savedFile == null || _submissionData == null) return;

    try {
      Rect? shareOrigin;
      final RenderBox? buttonBox =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (buttonBox != null && buttonBox.hasSize) {
        shareOrigin = buttonBox.localToGlobal(Offset.zero) & buttonBox.size;
      } else if (mounted) {
        final size = MediaQuery.of(context).size;
        shareOrigin = Rect.fromLTWH(0, 0, size.width, size.height / 2);
      }

      await TxtSubmissionService.shareSubmissionFile(
        file: _savedFile!,
        studentInfo: _submissionData!.studentInfo,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Sharing error: $e'),
          ),
        );
      }
    }
  }

  void _handleCopyText() {
    if (_generatedText != null && _generatedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission text copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isLoading
          ? const Center(
              heightFactor: 5,
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Generate TXT Submission',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              'Export formatted report for Email & Teams',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Input Form
                      _buildInputForm(),

                      const SizedBox(height: 16),

                      // Generate Button
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isGenerating ? null : _generateSubmission,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          _generatedText == null ? 'Generate Submission' : 'Update Submission',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_submissionData != null && _generatedText != null) ...[
                        const SizedBox(height: 20),
                        _buildSummaryCard(_submissionData!),
                        const SizedBox(height: 16),
                        _buildPreviewCard(),
                      ],
                    ],
                  ),
                ),

                // Bottom Action Bar
                if (_generatedText != null) _buildBottomActionBar(),
              ],
            ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student & Course Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF495057),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _studentIdController,
            decoration: const InputDecoration(
              labelText: 'Student ID *',
              hintText: 'e.g. 1301204012',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _studentNameController,
            decoration: const InputDecoration(
              labelText: 'Student Name',
              hintText: 'e.g. Budi Santoso',
              prefixIcon: Icon(Icons.person_outline, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _courseNameController,
            decoration: const InputDecoration(
              labelText: 'Course Name',
              hintText: 'e.g. Hardware Description Language',
              prefixIcon: Icon(Icons.school_outlined, size: 20),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(OverallSubmissionData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBEE5EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF0C5460), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _uniqueFilename ?? 'Submission File',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF0C5460),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricChip(
                  'Attempted',
                  '${data.problemsAttempted}/${data.totalProblemsAvailable}',
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricChip(
                  'Mastered',
                  '${data.problemsCompleted}',
                  const Color(0xFF1BBC9B),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricChip(
                  'Accuracy',
                  '${data.overallAccuracyRate.toStringAsFixed(1)}%',
                  data.overallAccuracyRate >= 70 ? const Color(0xFF1BBC9B) : Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricChip(
                  'Grade',
                  data.finalGrade.split(' ').first,
                  const Color(0xFF343A40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCED4DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TXT File Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF495057),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  onPressed: _handleCopyText,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(10),
            height: 180,
            child: SingleChildScrollView(
              child: SelectableText(
                _generatedText ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF212529),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text(
                  'Save to Device',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleSaveToDevice,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: _shareButtonKey,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text(
                  'Email / Teams',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.topButtonColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
