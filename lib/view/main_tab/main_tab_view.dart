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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: InkWell(
          onTap: () {
            setState(() {
              selectTab = 2; // زر الكاميرا يفتح Workout Tracker
            });
          },
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.primaryG),
              borderRadius: BorderRadius.circular(35),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 2),
              ],
            ),
            child: Icon(
              Icons.photo_camera,
              color: TColor.white,
              size: 30,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: kToolbarHeight,
          decoration: BoxDecoration(
            color: TColor.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // زر 1: Home
              TabButton(
                icon: "assets/img/home_tab.png",
                selectIcon: "assets/img/home_tab_select.png",
                isActive: selectTab == 0,
                onTap: () {
                  setState(() {
                    selectTab = 0;
                  });
                },
              ),

              // زر 2: Meal Planner
              TabButton(
                icon: "assets/img/activity_tab.png",
                selectIcon: "assets/img/activity_tab_select.png",
                isActive: selectTab == 1,
                onTap: () {
                  setState(() {
                    selectTab = 1;
                  });
                },
              ),

              const SizedBox(width: 40), // مسافة لزر الكاميرا في النص

              // زر 4: Sleep Tracker
              TabButton(
                icon: "assets/img/meal_tab.png",
                selectIcon: "assets/img/meal_tab_select.png",
                isActive: selectTab == 3,
                onTap: () {
                  setState(() {
                    selectTab = 3;
                  });
                },
              ),

              // زر 5: Profile
              TabButton(
                icon: "assets/img/profile_tab.png",
                selectIcon: "assets/img/profile_tab_select.png",
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
      ),
    );
  }
}