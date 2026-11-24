import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import '../models/script_config.dart';

class CameraPrompterScreen extends StatefulWidget {
  final ScriptConfig config;

  const CameraPrompterScreen({super.key, required this.config});

  @override
  State<CameraPrompterScreen> createState() => _CameraPrompterScreenState();
}

class _CameraPrompterScreenState extends State<CameraPrompterScreen> {
  CameraController? _cameraController;
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  bool _isCameraReady = false;
  bool _isRecording = false;
  late double _currentSpeed;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.config.scrollSpeed;
    _initFrontCamera();
  }

  Future<void> _initFrontCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בהפעלת המצלמה: $e')),
      );
    }
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    const tick = Duration(milliseconds: 30);
    _scrollTimer = Timer.periodic(tick, (timer) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll >= maxScroll) {
        timer.cancel();
      } else {
        // חישוב תזוזה חלקה לפי המהירות הנבחרת
        double delta = (_currentSpeed / 30.0);
        _scrollController.jumpTo(currentScroll + delta);
      }
    });
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
  }

  Future<void> _toggleRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    if (_isRecording) {
      // עצירת הקלטה ושמירה לגלריה
      try {
        _stopAutoScroll();
        final XFile videoFile = await _cameraController!.stopVideoRecording();
        setState(() => _isRecording = false);

        await Gal.putVideo(videoFile.path);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הסרטון נשמר בהצלחה בגלריה!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירת הסרטון: $e')),
        );
      }
    } else {
      // התחלת הקלטה וגלילה
      try {
        await _cameraController!.prepareForVideoRecording();
        await _cameraController!.startVideoRecording();
        setState(() => _isRecording = true);
        _startAutoScroll();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בהתחלת הקלטה: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. שכבת המצלמה
          if (_isCameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator()),

          // 2. שכבת הפרומפטר (ממוקמת למעלה קרוב לעדשת המצלמה!)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            height: MediaQuery.of(context).size.height * 0.38,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(widget.config.boxOpacity),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      widget.config.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.config.fontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 180), // מרווח לסיום חלק
                  ],
                ),
              ),
            ),
          ),

          // 3. כפתור חזרה לעריכה
          Positioned(
            top: 45,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _isRecording ? null : () => Navigator.pop(context),
              ),
            ),
          ),

          // 4. פקדי שליטה תחתונים (הקלטה + שינוי מהירות בזמן אמת)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // סליידר מהיר לשינוי קצב תוך כדי צילום
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.white70, size: 20),
                      Expanded(
                        child: Slider(
                          value: _currentSpeed,
                          min: 10,
                          max: 100,
                          activeColor: const Color(0xFF6366F1),
                          onChanged: (val) {
                            setState(() => _currentSpeed = val);
                          },
                        ),
                      ),
                      Text(
                        '${_currentSpeed.toInt()}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // כפתור הקלטה מרכזי
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.black26,
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: _isRecording ? 30 : 58,
                        width: _isRecording ? 30 : 58,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius:
                              BorderRadius.circular(_isRecording ? 8 : 30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
