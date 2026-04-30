import 'package:flutter/material.dart';

import '../../common/color_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, String>? currentProfile;

  const EditProfileView({super.key, this.currentProfile});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  TextEditingController txtFirstName = TextEditingController();
  TextEditingController txtLastName = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtHeight = TextEditingController();
  TextEditingController txtWeight = TextEditingController();
  TextEditingController txtAge = TextEditingController();

  String selectedGender = "Female";
  String selectedGoal = "Lose a Fat";

  @override
  void initState() {
    super.initState();

// استخدم البيانات الحالية لو موجودة، أو البيانات الافتراضية
    if (widget.currentProfile != null) {
      txtFirstName.text = widget.currentProfile!['firstName'] ?? "Stefani";
      txtLastName.text = widget.currentProfile!['lastName'] ?? "Wong";
      txtEmail.text = widget.currentProfile!['email'] ?? "stefani.wong@example.com";
      txtHeight.text = widget.currentProfile!['height'] ?? "180";
      txtWeight.text = widget.currentProfile!['weight'] ?? "65";
      txtAge.text = widget.currentProfile!['age'] ?? "22";

      // استخراج الـ goal من النص (مثلاً: "Lose a Fat Program" -> "Lose a Fat")
      String currentGoal = widget.currentProfile!['goal'] ?? "Lose a Fat Program";
      if (currentGoal.contains("Program")) {
        selectedGoal = currentGoal.replaceAll(" Program", "");
      } else {
        selectedGoal = currentGoal;
      }

      selectedGender = widget.currentProfile!['gender'] ?? "Female";
    } else {
      // البيانات الافتراضية
      txtFirstName.text = "Stefani";
      txtLastName.text = "Wong";
      txtEmail.text = "stefani.wong@example.com";
      txtHeight.text = "180";
      txtWeight.text = "65";
      txtAge.text = "22";
      selectedGender = "Female";
      selectedGoal = "Lose a Fat";
    }
  }

  void _saveProfile() {
// جمع البيانات الجديدة في Map
    Map<String, dynamic> updatedProfile = {
      'firstName': txtFirstName.text,
      'lastName': txtLastName.text,
      'email': txtEmail.text,
      'height': txtHeight.text,
      'weight': txtWeight.text,
      'age': txtAge.text,
      'gender': selectedGender,
      'goal': selectedGoal,
    };

// إرجاع البيانات الجديدة لـ ProfileView
    Navigator.pop(context, updatedProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context); // يرجع بدون تغييرات
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: () {
              // Reset to default values
              setState(() {
                txtFirstName.text = "Stefani";
                txtLastName.text = "Wong";
                txtEmail.text = "stefani.wong@example.com";
                txtHeight.text = "180";
                txtWeight.text = "65";
                txtAge.text = "22";
                selectedGender = "Female";
                selectedGoal = "Lose a Fat";
              });
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset(
                "assets/img/reset.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              // Profile Picture Section
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: TColor.primaryColor1, width: 2),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: Image.asset(
                        "assets/img/u1.png",
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: TColor.primaryColor1,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: TColor.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Personal Information
              RoundTextField(
                controller: txtFirstName,
                hitText: "First Name",
                icon: "assets/img/user_text.png",
              ),
              SizedBox(height: 15),
              RoundTextField(
                controller: txtLastName,
                hitText: "Last Name",
                icon: "assets/img/user_text.png",
              ),
              SizedBox(height: 15),
              RoundTextField(
                controller: txtEmail,
                hitText: "Email",
                icon: "assets/img/email.png",
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),

              // Gender Selection
              Container(
                decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child: Image.asset(
                        "assets/img/gender.png",
                        width: 20,
                        height: 20,
                        color: TColor.gray,
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGender,
                          items: ["Male", "Female"]
                              .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(
                              gender,
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 14,
                              ),
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value!;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // Physical Stats
              Row(
                children: [
                  Expanded(
                    child: RoundTextField(
                      controller: txtHeight,
                      hitText: "Height",
                      icon: "assets/img/hight.png",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.primaryG),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "cm",
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: RoundTextField(
                      controller: txtWeight,
                      hitText: "Weight",
                      icon: "assets/img/weight.png",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.secondaryG),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "kg",
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              RoundTextField(
                controller: txtAge,
                hitText: "Age",
                icon: "assets/img/age.png",
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),

              // Goal Selection
              Container(
                decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child: Image.asset(
                        "assets/img/goal.png",
                        width: 20,
                        height: 20,
                        color: TColor.gray,
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGoal,
                          items: [
                            "Lose a Fat",
                            "Improve Shape",
                            "Lean & Tone",
                            "Muscle Gain"
                          ].map((goal) => DropdownMenuItem(
                            value: goal,
                            child: Text(
                              goal,
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 14,
                              ),
                            ),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGoal = value!;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Save Button
              RoundButton(
                title: "Save Changes",
                onPressed: _saveProfile,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}