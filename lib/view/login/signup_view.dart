import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:x_trainer/common/color_extension.dart';
import 'package:x_trainer/view/login/what_your_goal_view.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final TextEditingController txtDate = TextEditingController();
  final TextEditingController txtWeight = TextEditingController();
  final TextEditingController txtHeight = TextEditingController();
  final TextEditingController txtBMI = TextEditingController();

  String? selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    txtWeight.addListener(_calculateBMI);
    txtHeight.addListener(_calculateBMI);
  }

  @override
  void dispose() {
    txtDate.dispose();
    txtWeight.dispose();
    txtHeight.dispose();
    txtBMI.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primaryColor1,
              onPrimary: Colors.white,
              onSurface: TColor.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: TColor.primaryColor1,
              ),
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        txtDate.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _calculateBMI() {
    if (txtWeight.text.isNotEmpty && txtHeight.text.isNotEmpty) {
      try {
        double weight = double.parse(txtWeight.text);
        double height = double.parse(txtHeight.text) / 100;
        if (height > 0) {
          double bmi = weight / (height * height);
          setState(() {
            txtBMI.text = bmi.toStringAsFixed(1);
          });
        }
      } catch (_) {
        txtBMI.text = "";
      }
    } else {
      txtBMI.text = "";
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Future<void> _saveProfile() async {
    if (selectedGender == null || txtDate.text.isEmpty) {
      _showError('Please select gender and date of birth');
      return;
    }

    if (txtWeight.text.isEmpty || txtHeight.text.isEmpty) {
      _showError('Please enter weight and height');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("🚀 [CompleteProfile] Starting to save profile...");

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showError('User not logged in');
        return;
      }

      debugPrint("👤 User UID: ${currentUser.uid}");

      String calculatedAge = _calculateAgeFromDate(txtDate.text);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'gender': selectedGender,
        'dateOfBirth': txtDate.text,
        'weight': txtWeight.text,
        'height': txtHeight.text,
        'bmi': txtBMI.text.isNotEmpty ? txtBMI.text : "0.0",
        'age': calculatedAge,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Profile data saved to Firebase!");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WhatYourGoalView(),
        ),
      );
    } catch (e) {
      debugPrint("❌ Error saving profile: $e");
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _calculateAgeFromDate(String dateOfBirth) {
    if (dateOfBirth.isEmpty) return '';
    try {
      List<String> parts = dateOfBirth.split('/');
      if (parts.length != 3) return '';
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      DateTime birthDate = DateTime(year, month, day);
      DateTime now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      debugPrint('Error calculating age: $e');
      return '';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    double? currentBMI;

    if (txtBMI.text.isNotEmpty) {
      currentBMI = double.tryParse(txtBMI.text);
    }

    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Image.asset(
                  "assets/img/complete_profile.png",
                  width: media.width,
                  fit: BoxFit.fitWidth,
                ),
                SizedBox(height: media.width * 0.05),
                Text(
                  "Let's complete your profile",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "It will help us to know more about you!",
                  style: TextStyle(color: TColor.gray, fontSize: 12),
                ),
                SizedBox(height: media.width * 0.05),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      // Gender
                      Container(
                        decoration: BoxDecoration(
                          color: TColor.lightGray,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: 50,
                              height: 50,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 15),
                              child: Image.asset(
                                "assets/img/gender.png",
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                                color: TColor.gray,
                              ),
                            ),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedGender,
                                  items: ["Male", "Female"]
                                      .map(
                                        (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          color: TColor.gray,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedGender = value;
                                    });
                                  },
                                  isExpanded: true,
                                  hint: Text(
                                    "Choose Gender",
                                    style: TextStyle(
                                      color: TColor.gray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                      SizedBox(height: media.width * 0.04),

                      // Date of Birth
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          decoration: BoxDecoration(
                            color: TColor.lightGray,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15),
                                child: Image.asset(
                                  "assets/img/date.png",
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  color: TColor.gray,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 15),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Date of Birth",
                                        style: TextStyle(
                                          color: TColor.gray,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        txtDate.text.isEmpty
                                            ? "Select your birth date"
                                            : txtDate.text,
                                        style: TextStyle(
                                          color: txtDate.text.isEmpty
                                              ? TColor.gray
                                              : TColor.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 15),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: TColor.gray,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: media.width * 0.04),

                      // Weight
                      Row(
                        children: [
                          Expanded(
                            child: RoundTextField(
                              controller: txtWeight,
                              hitText: "Your Weight",
                              icon: "assets/img/weight.png",
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: TColor.secondaryG,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "KG",
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: media.width * 0.04),

                      // Height
                      Row(
                        children: [
                          Expanded(
                            child: RoundTextField(
                              controller: txtHeight,
                              hitText: "Your Height",
                              icon: "assets/img/hight.png",
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: TColor.secondaryG,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "CM",
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: media.width * 0.04),

                      // BMI
                      Container(
                        decoration: BoxDecoration(
                          color: TColor.lightGray,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: 50,
                              height: 50,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 15),
                              child: Icon(
                                Icons.monitor_weight_outlined,
                                size: 20,
                                color: TColor.gray,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Your BMI",
                                      style: TextStyle(
                                        color: TColor.gray,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      txtBMI.text.isEmpty
                                          ? "Enter weight & height"
                                          : "${txtBMI.text} (${currentBMI != null ? _getBMICategory(currentBMI) : ""})",
                                      style: TextStyle(
                                        color: currentBMI != null
                                            ? _getBMIColor(currentBMI)
                                            : TColor.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (currentBMI != null)
                              Container(
                                margin: const EdgeInsets.only(right: 15),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getBMIColor(currentBMI),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _getBMICategory(currentBMI),
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: media.width * 0.07),

                      // Next button
                      if (_isLoading)
                        Container(
                          width: double.infinity,
                          height: 50,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              TColor.primaryColor1,
                            ),
                          ),
                        )
                      else
                        RoundButton(
                          title: "Next >",
                          onPressed: _saveProfile,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
