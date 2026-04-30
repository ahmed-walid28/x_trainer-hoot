import 'package:x_trainer/common/color_extension.dart';
import 'package:x_trainer/common_widget/round_button.dart';
import 'package:x_trainer/common_widget/round_textfield.dart';
import 'package:x_trainer/view/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  bool isCheck = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  TextEditingController txtFirstName = TextEditingController();
  TextEditingController txtLastName = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtConfirmPassword = TextEditingController();
  TextEditingController txtWeight = TextEditingController();
  TextEditingController txtHeight = TextEditingController();
  TextEditingController txtGoal = TextEditingController();
  TextEditingController txtAge = TextEditingController();
  TextEditingController txtGender = TextEditingController();

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    print("🔄 Register button pressed!");

    if (txtFirstName.text.isEmpty ||
        txtLastName.text.isEmpty ||
        txtEmail.text.isEmpty ||
        txtPassword.text.isEmpty ||
        txtConfirmPassword.text.isEmpty) {
      _showError('Please fill all required fields');
      print("❌ Validation failed: Empty fields");
      return;
    }

    if (!_isValidEmail(txtEmail.text)) {
      _showError('Please enter a valid email address');
      print("❌ Validation failed: Invalid email");
      return;
    }

    if (txtPassword.text.length < 6) {
      _showError('Password must be at least 6 characters');
      print("❌ Validation failed: Short password");
      return;
    }

    if (txtPassword.text != txtConfirmPassword.text) {
      _showError('Passwords do not match');
      print("❌ Validation failed: Password mismatch");
      return;
    }

    if (!isCheck) {
      _showError('Please accept Privacy Policy and Terms of Use');
      print("❌ Validation failed: Terms not accepted");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("⏳ Creating user in Firebase Auth...");
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: txtEmail.text.trim(),
        password: txtPassword.text.trim(),
      );

      final uid = cred.user!.uid;

      print("⏳ Saving profile to Firestore...");
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': txtFirstName.text.trim(),
        'lastName': txtLastName.text.trim(),
        'email': txtEmail.text.trim(),
        'weight': txtWeight.text.trim(),
        'height': txtHeight.text.trim(),
        'goal': txtGoal.text.trim(),
        'age': txtAge.text.trim(),
        'gender': txtGender.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ Registration & profile saved!");

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase error: ${e.code}");
      _showError(e.message ?? e.code);
    } catch (e) {
      print("❌ General error: $e");
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: media.width * 0.05),
                Text(
                  "Hey there,",
                  style: TextStyle(color: TColor.gray, fontSize: 16),
                ),
                Text(
                  "Create an Account",
                  style: TextStyle(
                      color: TColor.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(height: media.width * 0.05),
                RoundTextField(
                  controller: txtFirstName,
                  hitText: "First Name *",
                  icon: "assets/img/user_text.png",
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtLastName,
                  hitText: "Last Name *",
                  icon: "assets/img/user_text.png",
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtEmail,
                  hitText: "Email *",
                  icon: "assets/img/email.png",
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtPassword,
                  hitText: "Password *",
                  icon: "assets/img/lock.png",
                  obscureText: _obscurePassword,
                  rigtIcon: IconButton(
                    onPressed: _togglePasswordVisibility,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: TColor.gray,
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtConfirmPassword,
                  hitText: "Confirm Password *",
                  icon: "assets/img/lock.png",
                  obscureText: _obscureConfirmPassword,
                  rigtIcon: IconButton(
                    onPressed: _toggleConfirmPasswordVisibility,
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: TColor.gray,
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtWeight,
                  hitText: "Your Weight (KG)",
                  icon: "assets/img/weight.png",
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtHeight,
                  hitText: "Your Height (CM)",
                  icon: "assets/img/hight.png",
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtGoal,
                  hitText: "Your Goal (e.g. Weight Loss)",
                  icon: "assets/img/user_text.png",
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtAge,
                  hitText: "Age",
                  icon: "assets/img/user_text.png",
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtGender,
                  hitText: "Gender",
                  icon: "assets/img/user_text.png",
                ),
                SizedBox(height: media.width * 0.04),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isCheck = !isCheck;
                        });
                      },
                      icon: Icon(
                        isCheck
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank_outlined,
                        color: isCheck ? TColor.primaryColor1 : TColor.gray,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          "By continuing you accept our Privacy Policy and Term of Use",
                          style:
                          TextStyle(color: TColor.gray, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.1),
                if (_isLoading)
                  Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation(TColor.primaryColor1),
                    ),
                  )
                else
                  RoundButton(
                    title: "Register",
                    onPressed: _register,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
