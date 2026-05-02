import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:ui' as ui;

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    // إعداد قلم الرسم "النيون" للخطوط
    final Paint neonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      // استبدلنا withOpacity بـ withValues لحل التحذير الأصفر
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        [
          Colors.cyanAccent,
          Colors.purpleAccent,
        ],
      )
      ..strokeCap = StrokeCap.round;

    final Paint jointPaintOuter = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final Paint jointPaintInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      // ✅ التعديل هنا: بعتنا الـ size للدالة عشان ميديناش Error
      paintConnections(canvas, size, pose.landmarks, neonPaint);

      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
          Offset(
            translateX(landmark.x, rotation, size, absoluteImageSize),
            translateY(landmark.y, rotation, size, absoluteImageSize),
          ),
          6.0,
          jointPaintOuter,
        );
        canvas.drawCircle(
          Offset(
            translateX(landmark.x, rotation, size, absoluteImageSize),
            translateY(landmark.y, rotation, size, absoluteImageSize),
          ),
          3.0,
          jointPaintInner,
        );
      });
    }
  }

  // ✅ التعديل هنا: استقبلنا Size size كمدخل
  void paintConnections(Canvas canvas, Size size,
      Map<PoseLandmarkType, PoseLandmark> landmarks, Paint paintType) {
    void paintConnection(PoseLandmarkType type1, PoseLandmarkType type2) {
      final landmark1 = landmarks[type1]; // شيلنا ! عشان نتأكد تحت
      final landmark2 = landmarks[type2];

      // التأكد إن النقاط موجودة ودقتها عالية
      if (landmark1 == null ||
          landmark2 == null ||
          landmark1.likelihood < 0.5 ||
          landmark2.likelihood < 0.5) {
        return;
      }

      canvas.drawLine(
        Offset(
          translateX(landmark1.x, rotation, size, absoluteImageSize),
          translateY(landmark1.y, rotation, size, absoluteImageSize),
        ),
        Offset(
          translateX(landmark2.x, rotation, size, absoluteImageSize),
          translateY(landmark2.y, rotation, size, absoluteImageSize),
        ),
        paintType,
      );
    }

    // رسم الجسم
    paintConnection(
        PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    paintConnection(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    paintConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    paintConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

    // الذراعات
    paintConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    paintConnection(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    paintConnection(
        PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintConnection(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // الأرجل
    paintConnection(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    paintConnection(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    paintConnection(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    paintConnection(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses;
  }

  // دوال التحويل
  double translateX(double x, InputImageRotation rotation, Size size,
      Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * size.width / absoluteImageSize.height;
      case InputImageRotation.rotation270deg:
        return size.width - x * size.width / absoluteImageSize.height;
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  double translateY(double y, InputImageRotation rotation, Size size,
      Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / absoluteImageSize.width;
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }
}
