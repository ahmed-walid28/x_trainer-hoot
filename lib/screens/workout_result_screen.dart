import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // مكتبة الداتابيز
import 'package:firebase_auth/firebase_auth.dart';     // مكتبة المستخدم

class WorkoutResultScreen extends StatefulWidget {
  final int totalReps;
  final String exerciseType;

  const WorkoutResultScreen({
    Key? key,
    required this.totalReps,
    required this.exerciseType,
  }) : super(key: key);

  @override
  State<WorkoutResultScreen> createState() => _WorkoutResultScreenState();
}

class _WorkoutResultScreenState extends State<WorkoutResultScreen> {
  bool _isSaving = false; // عشان نظهر علامة تحميل والبيانات بتتبعت

  Future<void> _saveAndExit() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // حساب السعرات
        final double caloriesBurned = widget.totalReps * 0.4;

        // 1. تجهيز البيانات
        final workoutData = {
          'exercise': widget.exerciseType,
          'reps': widget.totalReps,
          'calories': caloriesBurned,
          'date': FieldValue.serverTimestamp(), // وقت السيرفر
        };

        // 2. الحفظ داخل مستند المستخدم في كوليكشن اسمه 'workouts'
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .add(workoutData);

        print("✅ Workout Saved Successfully!");
      }
    } catch (e) {
      print("❌ Error saving workout: $e");
      // ممكن تظهر رسالة خطأ هنا لو حابب
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving: $e")),
      );
    } finally {
      // 3. في كل الأحوال (حفظ أو فشل) نرجع للصفحة الرئيسية
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double caloriesBurned = widget.totalReps * 0.4;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 100, color: Colors.orangeAccent),
              const SizedBox(height: 20),

              const Text(
                "COMPLETED!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Great job on your ${widget.exerciseType.replaceAll('_', ' ')} session",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultCard("Reps", "${widget.totalReps}", Colors.blueAccent),
                  _buildResultCard("Kcal", caloriesBurned.toStringAsFixed(1), Colors.redAccent),
                ],
              ),

              const Spacer(),

              // زر الحفظ والخروج
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndExit, // لو بيحمل نوقف الزرار
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white) // علامة تحميل
                      : const Text(
                    "Save & Finish",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}