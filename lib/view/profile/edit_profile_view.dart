import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';
import '../../providers/profile_provider.dart';

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

  String? selectedGender;
  String? selectedGoal;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Load from passed profile or fallback to Provider
    if (widget.currentProfile != null) {
      txtFirstName.text = widget.currentProfile!['firstName'] ?? '';
      txtLastName.text = widget.currentProfile!['lastName'] ?? '';
      txtEmail.text = widget.currentProfile!['email'] ?? '';
      txtHeight.text = widget.currentProfile!['height'] ?? '';
      txtWeight.text = widget.currentProfile!['weight'] ?? '';
      txtAge.text = widget.currentProfile!['age'] ?? '';

      String currentGoal = widget.currentProfile!['goal'] ?? '';
      if (currentGoal.contains("Program")) {
        selectedGoal = currentGoal.replaceAll(" Program", "");
      } else if (currentGoal.isNotEmpty) {
        selectedGoal = currentGoal;
      }

      String currentGender = widget.currentProfile!['gender'] ?? '';
      if (currentGender.isNotEmpty) {
        selectedGender = currentGender;
      }
    } else {
      // Fallback: load from Provider if no data passed
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      txtFirstName.text = profile.firstName;
      txtLastName.text = profile.lastName;
      txtEmail.text = profile.email;
      txtHeight.text = profile.height;
      txtWeight.text = profile.weight;
      txtAge.text = profile.age;
      if (profile.gender.isNotEmpty) selectedGender = profile.gender;
      String currentGoal = profile.goal;
      if (currentGoal.contains("Program")) {
        selectedGoal = currentGoal.replaceAll(" Program", "");
      } else if (currentGoal.isNotEmpty) {
        selectedGoal = currentGoal;
      }
    }
  }

  bool _isSaving = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected. Press Save to upload.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _saveProfile() async {
    if (txtFirstName.text.isEmpty ||
        txtLastName.text.isEmpty ||
        txtEmail.text.isEmpty ||
        txtHeight.text.isEmpty ||
        txtWeight.text.isEmpty ||
        txtAge.text.isEmpty ||
        selectedGender == null ||
        selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    final profile = Provider.of<ProfileProvider>(context, listen: false);
    XFile? imageToUpload = _selectedImage;

    try {
      // Save profile data FIRST (fast)
      await profile.saveUserProfile(
        firstName: txtFirstName.text,
        lastName: txtLastName.text,
        email: txtEmail.text,
        height: txtHeight.text,
        weight: txtWeight.text,
        age: txtAge.text,
        gender: selectedGender!,
        goal: selectedGoal!,
      );

      // Clear local image immediately for optimistic UI
      if (imageToUpload != null) {
        setState(() {
          _selectedImage = null;
        });
      }

      if (!mounted) return;

      // Show success for profile data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved! Uploading image...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Pop immediately - don't wait for image upload
      Navigator.of(context).pop();

      // Upload image in BACKGROUND (async, non-blocking)
      if (imageToUpload != null) {
        _uploadImageInBackground(imageToUpload, profile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  // Background upload - doesn't block UI
  void _uploadImageInBackground(XFile image, ProfileProvider profile) async {
    try {
      print('Starting background image upload...');
      final imageUrl = await profile.uploadProfileImage(image);

      if (imageUrl != null) {
        print('Background upload complete: $imageUrl');
        // Reload profile to show new image
        await profile.loadUserProfile();
      } else {
        print('Background upload failed');
      }
    } catch (e) {
      print('Error in background upload: $e');
    }
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
          IconButton(
            onPressed: () async {
              final profile =
                  Provider.of<ProfileProvider>(context, listen: false);
              await profile.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: Icon(Icons.logout, color: TColor.secondaryColor1),
          ),
        ],
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 25, bottom: 15),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Profile Picture Section
              GestureDetector(
                onTap: _pickImage,
                child: Consumer<ProfileProvider>(
                  builder: (context, profile, child) {
                    Widget imageWidget;
                    if (_selectedImage != null) {
                      // Use Image.network for web, FileImage for mobile
                      if (kIsWeb) {
                        imageWidget = Image.network(
                          _selectedImage!.path,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              "assets/img/u1.png",
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            );
                          },
                        );
                      } else {
                        imageWidget = Image.file(
                          File(_selectedImage!.path),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              "assets/img/u1.png",
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            );
                          },
                        );
                      }
                    } else if (profile.profileImageUrl.isNotEmpty) {
                      imageWidget = Image.network(
                        profile.profileImageUrl,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "assets/img/u1.png",
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          );
                        },
                      );
                    } else {
                      imageWidget = Image.asset(
                        "assets/img/u1.png",
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      );
                    }

                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border:
                            Border.all(color: TColor.primaryColor1, width: 2),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child: imageWidget,
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Personal Information
              RoundTextField(
                controller: txtFirstName,
                hitText: "First Name",
                icon: "assets/img/user_text.png",
              ),
              const SizedBox(height: 15),
              RoundTextField(
                controller: txtLastName,
                hitText: "Last Name",
                icon: "assets/img/user_text.png",
              ),
              const SizedBox(height: 15),
              RoundTextField(
                controller: txtEmail,
                hitText: "Email",
                icon: "assets/img/email.png",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

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
                          hint: Text(
                            "Select Gender",
                            style: TextStyle(color: TColor.gray, fontSize: 14),
                          ),
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
                              selectedGender = value;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 15),

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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 15),

              RoundTextField(
                controller: txtAge,
                hitText: "Age",
                icon: "assets/img/age.png",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

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
                          hint: Text(
                            "Select Goal",
                            style: TextStyle(color: TColor.gray, fontSize: 14),
                          ),
                          items: [
                            "Lose a Fat",
                            "Improve Shape",
                            "Lean & Tone",
                            "Muscle Gain"
                          ]
                              .map((goal) => DropdownMenuItem(
                                    value: goal,
                                    child: Text(
                                      goal,
                                      style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGoal = value;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              _isSaving
                  ? Container(
                      width: double.infinity,
                      height: 50,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(TColor.primaryColor1),
                      ),
                    )
                  : RoundButton(
                      title: "Save Changes",
                      onPressed: _saveProfile,
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
