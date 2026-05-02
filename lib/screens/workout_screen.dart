import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils.dart';
import '../pose_painter.dart';
import 'workout_result_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final String exerciseType;

  const WorkoutScreen({
    Key? key,
    required this.exerciseType,
  }) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isProcessing = false;
  List<Pose> _poses = [];

  final FlutterTts flutterTts = FlutterTts();

  // تعريف العدادات كلها
  late SquatCounter squatCounter;
  late PushUpCounter pushUpCounter;
  late HammerCurlCounter curlCounter;
  late LateralRaiseCounter lateralRaiseCounter;
  late JumpingJackCounter jumpingJackCounter;
  late ShoulderPressCounter shoulderPressCounter;
  late LungesCounter lungesCounter;

  int _counter = 0;
  String _stage = 'START';
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _initTts();

    // تهيئة العدادات
    squatCounter = SquatCounter();
    pushUpCounter = PushUpCounter();
    curlCounter = HammerCurlCounter();
    lateralRaiseCounter = LateralRaiseCounter();
    jumpingJackCounter = JumpingJackCounter();
    shoulderPressCounter = ShoulderPressCounter();
    lungesCounter = LungesCounter();

    // 👇 التعديل المهم هنا: استخدام Base Model للسرعة القصوى
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base, // أسرع وأخف على المعالج
    );
    _poseDetector = PoseDetector(options: options);

    _initializeCamera();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium, // تقليل الجودة قليلاً لزيادة السرعة
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() {});
      _cameraController!.startImageStream(_processImage);
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        int previousCount = _counter;

        // ==========================================
        // اختيار نوع التمرين بناءً على الزر المضغوط
        // ==========================================
        if (widget.exerciseType == 'squat') {
          squatCounter.check(pose);
          if (squatCounter.count > previousCount) {
            _speak("${squatCounter.count}");
          }
          _updateData(
              squatCounter.count, squatCounter.stage, squatCounter.feedback);
        } else if (widget.exerciseType == 'push_up') {
          pushUpCounter.check(pose);
          if (pushUpCounter.count > previousCount) {
            _speak("${pushUpCounter.count}");
          }
          _updateData(
              pushUpCounter.count, pushUpCounter.stage, pushUpCounter.feedback);
        } else if (widget.exerciseType == 'hammer_curl') {
          curlCounter.check(pose);
          if (curlCounter.count > previousCount) _speak("${curlCounter.count}");
          _updateData(
              curlCounter.count, curlCounter.stage, curlCounter.feedback);
        } else if (widget.exerciseType == 'lateral_raise') {
          lateralRaiseCounter.check(pose);
          if (lateralRaiseCounter.count > previousCount) {
            _speak("${lateralRaiseCounter.count}");
          }
          _updateData(lateralRaiseCounter.count, lateralRaiseCounter.stage,
              lateralRaiseCounter.feedback);
        } else if (widget.exerciseType == 'jumping_jack') {
          jumpingJackCounter.check(pose);
          if (jumpingJackCounter.count > previousCount) {
            _speak("${jumpingJackCounter.count}");
          }
          _updateData(jumpingJackCounter.count, jumpingJackCounter.stage,
              jumpingJackCounter.feedback);
        } else if (widget.exerciseType == 'shoulder_press') {
          shoulderPressCounter.check(pose);
          if (shoulderPressCounter.count > previousCount) {
            _speak("${shoulderPressCounter.count}");
          }
          _updateData(shoulderPressCounter.count, shoulderPressCounter.stage,
              shoulderPressCounter.feedback);
        } else if (widget.exerciseType == 'lunges') {
          lungesCounter.check(pose);
          if (lungesCounter.count > previousCount) {
            _speak("${lungesCounter.count}");
          }
          _updateData(
              lungesCounter.count, lungesCounter.stage, lungesCounter.feedback);
        }
      }

      if (mounted) {
        setState(() {
          _poses = poses;
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _updateData(int count, String stage, String feedback) {
    if (_counter != count || _stage != stage || _feedback != feedback) {
      if (mounted) {
        setState(() {
          _counter = count;
          _stage = stage;
          _feedback = feedback;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    flutterTts.stop();
    super.dispose();
  }

  Widget _buildHUD() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyanAccent, width: 3),
                color: Colors.black54,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$_counter",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text("REPS",
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(
                    _stage == "UP" ? Icons.arrow_upward : Icons.arrow_downward,
                    color: _stage == "UP"
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _feedback.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2)]),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                flutterTts.stop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutResultScreen(
                      totalReps: _counter,
                      exerciseType: widget.exerciseType,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent),
                ),
                child:
                    const Icon(Icons.stop, color: Colors.redAccent, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_cameraController!)),
          if (_poses.isNotEmpty)
            CustomPaint(
              painter: PosePainter(
                _poses,
                _cameraController!.value.previewSize!,
                InputImageRotation.rotation270deg,
              ),
              child: const SizedBox.expand(),
            ),
          _buildHUD(),
        ],
      ),
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation = InputImageRotation.rotation270deg;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation270deg;
    }
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
