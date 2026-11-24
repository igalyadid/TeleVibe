import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/script_config.dart';
import 'camera_prompter_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _textController = TextEditingController(
    text: "שלום לכולם וברוכים הבאים לסרטון חדש!\n\n"
        "היום אני הולך להראות לכם איך להקליט סרטונים בצורה חלקה, "
        "טבעית ומקצועית בלי לשכוח אף מילה מהתסריט.\n\n"
        "פשוט לוחצים על הקלטה, מסתכלים ישר לעדשה, וקוראים בקצב שלכם.",
  );

  double _fontSize = 26.0;
  double _scrollSpeed = 40.0;

  Future<void> _pickTextFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString(encoding: utf8);
        setState(() {
          _textController.text = content;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('שגיאה בטעינת הקובץ. ודא שזהו קובץ txt תקין.')),
      );
    }
  }

  void _startRecordingScreen() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא הזן טקסט לתסריט לפני המעבר לצילום')),
      );
      return;
    }

    final config = ScriptConfig(
      text: _textController.text,
      fontSize: _fontSize,
      scrollSpeed: _scrollSpeed,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: CameraPrompterScreen(config: config),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TeleVibe',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'טען קובץ טקסט (.txt)',
            onPressed: _pickTextFile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'התסריט שלך:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'הדבק כאן את הטקסט או טען קובץ מלמעלה...',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSliderCard(
              title: 'גודל גופן בפרומפטר: ${_fontSize.toInt()}',
              icon: Icons.format_size_rounded,
              value: _fontSize,
              min: 18,
              max: 42,
              onChanged: (val) => setState(() => _fontSize = val),
            ),
            const SizedBox(height: 10),
            _buildSliderCard(
              title: 'מהירות גלילה: ${_scrollSpeed.toInt()}',
              icon: Icons.speed_rounded,
              value: _scrollSpeed,
              min: 10,
              max: 100,
              onChanged: (val) => setState(() => _scrollSpeed = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startRecordingScreen,
              icon: const Icon(Icons.videocam_rounded, size: 26),
              label: const Text(
                'עבור למסך צילום',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
