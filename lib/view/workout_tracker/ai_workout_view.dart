import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class AiWorkoutView extends StatefulWidget {
  const AiWorkoutView({super.key});

  @override
  State<AiWorkoutView> createState() => _AiWorkoutViewState();
}

class _AiWorkoutViewState extends State<AiWorkoutView> {
  CameraController? _controller;
  IO.Socket? socket;
  bool isProcessing = false;
  String feedback = "جاري الاتصال...";
  String stage = "-";
  String reps = "0";
  Timer? _timer;

// تأكد إن السطر ده مكتوب كدة بالظبط
  final String serverUrl = 'http://10.150.239.7:5000';
  @override
  void initState() {
    super.initState();
    initSocket();
    initCamera();
  }

  // 1. إعداد السيرفر
  void initSocket() {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('✅ تم الاتصال بالسيرفر بنجاح');
      if (mounted) {
        setState(() => feedback = "ابدأ التمرين!");
      }
    });

    socket!.onDisconnect((_) => print('❌ انقطع الاتصال'));

    socket!.on('response', (data) {
      if (mounted) {
        setState(() {
          reps = data['reps'].toString();
          stage = data['stage']?.toString() ?? "-";
          feedback = data['feedback']?.toString() ?? "";
        });
      }
    });
  }

  // 2. إعداد الكاميرا
  Future<void> initCamera() async {
    final cameras = await availableCameras();
    // الكاميرا الأمامية
    final frontCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() {});

    // 3. مؤقت لإرسال الصور (كل 800 مللي ثانية - يعني تقريباً صورة في الثانية)
    // ده أضمن حل عشان السيرفر يلحق يعالج الصورة وميهنجش
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) async {
      if (isProcessing || _controller == null || !_controller!.value.isInitialized) return;

      isProcessing = true;
      try {
        // ناخد صورة
        final image = await _controller!.takePicture();
        final bytes = await File(image.path).readAsBytes();

        // نحولها Base64
        String base64Image = base64Encode(bytes);

        // نبعتها للسيرفر
        socket!.emit('process_frame', base64Image);
      } catch (e) {
        print("Error sending frame: $e");
      } finally {
        isProcessing = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // شاشة الكاميرا
          Center(child: CameraPreview(_controller!)),

          // طبقة المعلومات (العداد والتعليمات)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "العدات: $reps",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    feedback,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: feedback.contains("Good") ? Colors.green : Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "الحالة: $stage",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // زر الرجوع
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}