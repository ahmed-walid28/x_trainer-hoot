import 'package:flutter/material.dart';

import 'package:x_trainer/common/color_extension.dart';
import 'package:x_trainer/common_widget/tab_button.dart';

import '../home/home_view.dart';
import '../meal_planner/meal_planner_view.dart';
import '../profile/profile_view.dart'; // 👈 ده المسار الجديد لصفحة البروفايل
import '../sleep_tracker/sleep_tracker_view.dart';
import '../workout_tracker/workout_tracker_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selectTab = 0;
  final PageStorageBucket pageBucket = PageStorageBucket();

  // كل الصفحات اللي تحت التابات
  final List<Widget> _tabs = const [
    HomeView(),             // زر 1
    MealPlannerView(),      // زر 2
    WorkoutTrackerView(),   // زر الكاميرا (3)
    SleepTrackerView(),     // زر 4
    ProfileView(),          // 👈 زر 5: تم التعديل هنا لتشغيل الصفحة الجديدة
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: PageStorage(
        bucket: pageBucket,
        child: _tabs[selectTab],
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95), // White semi-transparent
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // زر 1: Home
            _buildNavItem(
              icon: "assets/img/home_tab.png",
              selectIcon: "assets/img/home_tab_select.png",
              label: "Home",
              isActive: selectTab == 0,
              onTap: () {
                setState(() {
                  selectTab = 0;
                });
              },
            ),

            // زر 2: Search (Meal Planner)
            _buildNavItem(
              icon: "assets/img/activity_tab.png",
              selectIcon: "assets/img/activity_tab_select.png",
              label: "Search",
              isActive: selectTab == 1,
              onTap: () {
                setState(() {
                  selectTab = 1;
                });
              },
            ),

            // زر الكاميرا في النص
            _buildCenterCameraButton(),

            // زر 4: History (Sleep Tracker)
            _buildNavItem(
              icon: "assets/img/meal_tab.png",
              selectIcon: "assets/img/meal_tab_select.png",
              label: "History",
              isActive: selectTab == 3,
              onTap: () {
                setState(() {
                  selectTab = 3;
                });
              },
            ),

            // زر 5: Profile
            _buildNavItem(
              icon: "assets/img/profile_tab.png",
              selectIcon: "assets/img/profile_tab_select.png",
              label: "Profile",
              isActive: selectTab == 4,
              onTap: () {
                setState(() {
                  selectTab = 4;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String selectIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? TColor.primaryColor1.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                isActive ? selectIcon : icon,
                width: 22,
                height: 22,
                color: isActive ? TColor.primaryColor1 : Colors.grey.shade600,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error_outline,
                    color: isActive ? TColor.primaryColor1 : Colors.grey.shade600,
                    size: 22,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? TColor.primaryColor1 : Colors.grey.shade600,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterCameraButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectTab = 2;
        });
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: TColor.primaryG),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: TColor.primaryColor1.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.photo_camera,
          color: TColor.white,
          size: 26,
        ),
      ),
    );
  }
}