import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ==========================================
// 1. أدوات الحسابات الهندسية 📐
// ==========================================
class PoseUtils {
  static double calculateAngle(
      PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    double angle = math.atan2(last.y - middle.y, last.x - middle.x) -
        math.atan2(first.y - middle.y, first.x - middle.x);

    angle = angle * 180 / math.pi;
    angle = angle.abs();

    if (angle > 180) {
      angle = 360 - angle;
    }
    return angle;
  }
}

// ==========================================
// 2. Squat (سكوات)
// ==========================================
class SquatCounter {
  int count = 0;
  String stage = "UP";
  String feedback = "";

  void check(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (hip != null && knee != null && ankle != null && shoulder != null) {
      double kneeAngle = PoseUtils.calculateAngle(hip, knee, ankle);
      double backAngle = PoseUtils.calculateAngle(shoulder, hip, knee);

      if (kneeAngle > 160) {
        stage = "UP";
        feedback = "";
      }
      if (kneeAngle < 90 && stage == "UP") {
        stage = "DOWN";
        count++;
        feedback = "Great!";
      }

      if (stage == "DOWN" && backAngle < 100) {
        feedback = "Straighten Back!";
      } else if (stage == "DOWN" && kneeAngle > 100) feedback = "Go Lower!";
    }
  }
}

// ==========================================
// 3. Push Up (ضغط)
// ==========================================
class PushUpCounter {
  int count = 0;
  String stage = "UP";
  String feedback = "";

  void check(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (shoulder != null &&
        elbow != null &&
        wrist != null &&
        hip != null &&
        ankle != null) {
      double elbowAngle = PoseUtils.calculateAngle(shoulder, elbow, wrist);
      double bodyLineAngle = PoseUtils.calculateAngle(shoulder, hip, ankle);

      if (elbowAngle > 160) {
        stage = "UP";
        feedback = "";
      }
      if (elbowAngle < 90 && stage == "UP") {
        stage = "DOWN";
        count++;
        feedback = "Good!";
      }

      if (bodyLineAngle < 160) feedback = "Fix Body Line!";
    }
  }
}

// ==========================================
// 4. Hammer Curl (بايسبس)
// ==========================================
class HammerCurlCounter {
  int count = 0;
  String stage = "DOWN";
  String feedback = "";

  void check(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];

    if (shoulder != null && elbow != null && wrist != null && hip != null) {
      double elbowAngle = PoseUtils.calculateAngle(shoulder, elbow, wrist);
      double armStabilityAngle = PoseUtils.calculateAngle(shoulder, elbow, hip);

      if (elbowAngle > 160) {
        stage = "DOWN";
        feedback = "";
      }
      if (elbowAngle < 45 && stage == "DOWN") {
        stage = "UP";
        count++;
        feedback = "Squeeze!";
      }

      if (stage == "UP" && armStabilityAngle < 150) feedback = "Fix Elbow!";
    }
  }
}

// ==========================================
// 5. Lateral Raise (رفرفة أكتاف)
// ==========================================
class LateralRaiseCounter {
  int count = 0;
  String stage = "DOWN";
  String feedback = "";

  void check(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];

    if (hip != null && shoulder != null && elbow != null) {
      double armBodyAngle = PoseUtils.calculateAngle(hip, shoulder, elbow);

      if (armBodyAngle < 30) {
        stage = "DOWN";
        feedback = "";
      }
      if (armBodyAngle > 80 && stage == "DOWN") {
        stage = "UP";
        count++;
        feedback = "Good!";
      }
      if (stage == "UP" && armBodyAngle > 110) feedback = "Too High!";
    }
  }
}

// ==========================================
// 6. Jumping Jack (قفز)
// ==========================================
class JumpingJackCounter {
  int count = 0;
  String stage = "DOWN";
  String feedback = "";

  void check(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftShoulder != null &&
        rightShoulder != null &&
        leftWrist != null &&
        rightWrist != null &&
        leftAnkle != null &&
        rightAnkle != null) {
      double legDistance = (leftAnkle.x - rightAnkle.x).abs();
      double shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();

      bool handsUp =
          leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y;
      bool handsDown =
          leftWrist.y > leftShoulder.y && rightWrist.y > rightShoulder.y;

      if (handsUp && legDistance > shoulderWidth * 1.5) {
        stage = "UP";
        feedback = "";
      }
      if (handsDown && legDistance < shoulderWidth * 1.2 && stage == "UP") {
        stage = "DOWN";
        count++;
        feedback = "Keep Going!";
      }
    }
  }
}

// ==========================================
// 7. Shoulder Press (ضغط أكتاف) - جديد ✅
// ==========================================
class ShoulderPressCounter {
  int count = 0;
  String stage = "DOWN";
  String feedback = "";

  void check(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (shoulder != null && elbow != null && wrist != null) {
      double elbowAngle = PoseUtils.calculateAngle(shoulder, elbow, wrist);

      // الدراع مفرود فوق (UP)
      if (elbowAngle > 160) {
        stage = "UP";
        feedback = "Down!";
      }
      // الدراع نزل (DOWN) - زاوية 90 تقريباً
      if (elbowAngle < 90 && stage == "UP") {
        stage = "DOWN";
        count++;
        feedback = "Push!";
      }
    }
  }
}

// ==========================================
// 8. Lunges (طعن) - جديد ✅
// ==========================================
class LungesCounter {
  int count = 0;
  String stage = "UP";
  String feedback = "";

  void check(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (hip != null && knee != null && ankle != null) {
      double kneeAngle = PoseUtils.calculateAngle(hip, knee, ankle);

      // واقف (UP)
      if (kneeAngle > 160) {
        stage = "UP";
        feedback = "";
      }
      // نزل (DOWN) - الركبة قربت من 90
      if (kneeAngle < 100 && stage == "UP") {
        stage = "DOWN";
        count++;
        feedback = "Up!";
      }
    }
  }
}
