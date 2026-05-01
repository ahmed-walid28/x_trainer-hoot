import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../common/color_extension.dart';
import '../../providers/profile_provider.dart';
import 'edit_profile_view.dart'; // تأكد إن المسار ده صح لملف التعديل

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    // 1. استدعاء البروفايدر لبيانات المستخدم الأساسية
    final profile = Provider.of<ProfileProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Profile",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          // زرار تسجيل الخروج
          IconButton(
            onPressed: () async {
              await profile.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: Icon(Icons.logout, color: TColor.secondaryColor1),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= الجزء الأول: بيانات المستخدم (من Provider) =================
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: profile.profileImageUrl.isNotEmpty
                      ? Image.network(
                          profile.profileImageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              "assets/img/u1.png",
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          "assets/img/u1.png",
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName.isNotEmpty ? profile.fullName : "User Name",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        profile.goal.isNotEmpty ? profile.goal : "Lose a Fat Program",
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ),
                // زرار التعديل
                SizedBox(
                  width: 80,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      final profile = Provider.of<ProfileProvider>(context, listen: false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileView(
                            currentProfile: {
                              'firstName': profile.firstName,
                              'lastName': profile.lastName,
                              'email': profile.email,
                              'height': profile.height,
                              'weight': profile.weight,
                              'age': profile.age,
                              'gender': profile.gender,
                              'goal': profile.goal,
                            },
                          ),
                        ),
                      ).then((_) {
                        final profile = Provider.of<ProfileProvider>(context, listen: false);
                        profile.loadUserProfile();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primaryColor1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    child: const Text(
                      "Edit",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 15),

            // عرض الطول والوزن والعمر
            Row(
              children: [
                Expanded(child: _buildStatBox("Height", "${profile.height}cm")),
                const SizedBox(width: 15),
                Expanded(child: _buildStatBox("Weight", "${profile.weight}kg")),
                const SizedBox(width: 15),
                Expanded(child: _buildStatBox("Age", "${profile.age}yo")),
              ],
            ),

            const SizedBox(height: 25),

            // ================= الجزء الثاني: سجل التمارين (من Firebase) =================
            Text(
              "Workout History",
              style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 15),

            // StreamBuilder لجلب البيانات الحقيقية
            if (user != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('workouts')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text("No workouts yet. Start training!", style: TextStyle(color: TColor.gray)),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // حساب الإجماليات
                  int totalWorkouts = docs.length;
                  double totalCalories = 0;
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalCalories += (data['calories'] as num? ?? 0).toDouble();
                  }

                  return Column(
                    children: [
                      // كارت ملخص الأداء
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: TColor.primaryColor2.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem("Workouts", "$totalWorkouts"),
                            _buildSummaryItem("Kcal Burned", totalCalories.toStringAsFixed(0)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // قائمة التمارين السابقة
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return _buildHistoryRow(data);
                        },
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ويدجيت لعرض الطول/الوزن
  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                color: TColor.primaryColor1,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: TColor.gray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ويدجيت لملخص التمارين
  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: TColor.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: TColor.gray, fontSize: 12),
        ),
      ],
    );
  }

  // ويدجيت لعرض سطر في سجل التمارين
  Widget _buildHistoryRow(Map<String, dynamic> data) {
    final timestamp = data['date'] as Timestamp?;
    final dateStr = timestamp != null
        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
        : '-';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 50,
              width: 50,
              color: TColor.secondaryColor1.withOpacity(0.2),
              child: Icon(Icons.fitness_center, color: TColor.secondaryColor1),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['exercise'] ?? "Workout").toString().toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  "$dateStr | ${data['reps']} Reps",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${(data['calories'] as num).toStringAsFixed(0)} Kcal",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}