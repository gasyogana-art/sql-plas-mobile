import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/plas_storage_service.dart';
import '../theme/app_theme.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _recordController = TextEditingController();
  final GlobalKey _saveButtonKey = GlobalKey();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedStudentId();
  }

  Future<void> _loadSavedStudentId() async {
    final savedId = await PlasStorageService.getStudentId();
    if (mounted && savedId.isNotEmpty) {
      _studentIdController.text = savedId;
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _recordController.dispose();
    super.dispose();
  }

  Future<void> _handleShowRecord() async {
    final uid = _studentIdController.text.trim();
    if (uid.isEmpty) {
      setState(() {
        _recordController.text = 'Fill in Student ID';
      });
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }
    await PlasStorageService.setStudentId(uid);
    final text = await PlasStorageService.generateRecordText(uid);

    if (mounted) {
      setState(() {
        _recordController.text = text;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final uid = _studentIdController.text.trim();
    final content = _recordController.text.trim();

    if (uid.isEmpty ||
        content.isEmpty ||
        content == 'Fill in Student ID' ||
        content.startsWith('No records found')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Student ID and answer some problems first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save & Export Record'),
        content: Text(
          'File: V_CH1_$uid.txt\n\nAccording to PLAS workflow, saving the record will export the text file and clear the local attempt records. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save & Export', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Calculate safe share popover origin for iOS / iPadOS
        Rect? shareOrigin;
        final RenderBox? buttonBox =
            _saveButtonKey.currentContext?.findRenderObject() as RenderBox?;
        if (buttonBox != null && buttonBox.hasSize) {
          shareOrigin = buttonBox.localToGlobal(Offset.zero) & buttonBox.size;
        } else if (mounted) {
          final size = MediaQuery.of(context).size;
          shareOrigin = Rect.fromLTWH(0, 0, size.width, size.height / 2);
        }

        final savedFile = await PlasStorageService.shareRecordFile(
          studentId: uid,
          recordContent: content,
          clearAfterShare: true,
          sharePositionOrigin: shareOrigin,
        );
        if (mounted) {
          setState(() {
            _recordController.text =
                'Records saved and exported successfully!\nFile: ${savedFile.path}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved V_CH1_$uid.txt successfully!'),
              backgroundColor: const Color(0xFF1BBC9B),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error exporting file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _copyToClipboard() {
    if (_recordController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _recordController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title
        Row(
          children: const [
            Icon(Icons.send_rounded, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Submission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Step 1: Student ID
        _buildStepBadge('1', 'Enter your Student ID'),
        const SizedBox(height: 8),
        TextField(
          controller: _studentIdController,
          decoration: const InputDecoration(
            hintText: 'Student ID',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),

        const SizedBox(height: 20),

        // Step 2: Show Record
        _buildStepBadge('2', 'Display your answer records'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.history_edu, color: Color(0xFF2C3E50)),
          label: const Text(
            'Show Record',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Color(0xFFCED4DA)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isLoading ? null : _handleShowRecord,
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            TextField(
              controller: _recordController,
              readOnly: true,
              maxLines: 8,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Your Record will appear here after clicking "Show Record"',
                fillColor: Color(0xFFF8F9FA),
              ),
            ),
            if (_recordController.text.isNotEmpty &&
                _recordController.text != 'Fill in Student ID')
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: AppTheme.primary),
                  tooltip: 'Copy record',
                  onPressed: _copyToClipboard,
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // Step 3: Save
        _buildStepBadge('3', 'Save & Export Record File'),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          key: _saveButtonKey,
          icon: const Icon(Icons.save_alt, color: Colors.white),
          label: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.topButtonColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
          onPressed: _handleSave,
        ),

        const SizedBox(height: 24),

        // Instruction card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBEE5EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF0C5460), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Instructions:\n1. Input your Student ID.\n2. Tap "Show Record" to generate your SHA-256 session hash and answer logs.\n3. Tap "Save" to export V_CH1_<StudentID>.txt and submit it according to your instructor\'s guidelines.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0C5460),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepBadge(String step, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF343A40),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF495057),
            ),
          ),
        ),
      ],
    );
  }
}
