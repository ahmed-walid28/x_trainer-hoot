import 'package:flutter/material.dart';
import 'workout_screen.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // خلفية الصفحة بيضاء
      appBar: AppBar(
        title: const Text('Fitness Trainer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let\'s Move!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                'Choose your workout',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              // === القائمة بتصميم الكروت الرأسية ===

              _buildVerticalCard(
                title: 'Squat',
                subtitle: 'Legs Day',
                imagePath: 'assets/img/squat.jpg',
                type: 'squat',
                color: const Color(0xFFE3F2FD),
                textColor: const Color(0xFF1565C0),
              ),

              _buildVerticalCard(
                title: 'Push Up',
                subtitle: 'Power Chest',
                imagePath: 'assets/img/pushup.jpg',
                type: 'push_up',
                color: const Color(0xFFFFF3E0),
                textColor: const Color(0xFFEF6C00),
              ),

              _buildVerticalCard(
                title: 'Hammer Curl',
                subtitle: 'Big Biceps',
                imagePath: 'assets/img/curl.jpg',
                type: 'hammer_curl',
                color: const Color(0xFFF3E5F5),
                textColor: const Color(0xFF7B1FA2),
              ),

              _buildVerticalCard(
                title: 'Lateral Raise',
                subtitle: 'Wide Shoulders',
                imagePath: 'assets/img/lateral.jpg',
                type: 'lateral_raise',
                color: const Color(0xFFFFEBEE),
                textColor: const Color(0xFFC62828),
              ),

              _buildVerticalCard(
                title: 'Jumping Jack',
                subtitle: 'Cardio Time',
                imagePath: 'assets/img/jump.jpg',
                type: 'jumping_jack',
                color: const Color(0xFFE8F5E9),
                textColor: const Color(0xFF2E7D32),
              ),

              _buildVerticalCard(
                title: 'Shoulder Press',
                subtitle: 'Overhead Power',
                imagePath: 'assets/img/press.jpg',
                type: 'shoulder_press',
                color: const Color(0xFFE8EAF6),
                textColor: const Color(0xFF3949AB),
              ),

              _buildVerticalCard(
                title: 'Lunges',
                subtitle: 'Legs Balance',
                imagePath: 'assets/img/lunges.jpg',
                type: 'lunges',
                color: const Color(0xFFE0F2F1),
                textColor: const Color(0xFF00897B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تصميم الكارت الرأسي الجديد (صورة كبيرة فوق + كلام تحت)
  Widget _buildVerticalCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required String type,
    required Color color,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutScreen(exerciseType: type),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 25), // مسافة بين كل كارت والتاني
        width: double.infinity, // الكارت ياخد عرض الشاشة
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الصورة الكبيرة (فوق)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: SizedBox(
                height: 180, // ارتفاع الصورة (كبير وواضح)
                width: double.infinity,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover, // الصورة تملأ المساحة بالكامل
                  errorBuilder: (c, o, s) => Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: textColor),
                  ),
                ),
              ),
            ),

            // 2. الكلام (تحت)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  // زر أيقونة صغير كديكور
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: textColor, size: 28),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}