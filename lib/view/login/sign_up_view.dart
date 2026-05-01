import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:x_trainer/common/color_extension.dart';
import 'package:x_trainer/common_widget/round_button.dart';
import 'package:x_trainer/common_widget/round_textfield.dart';
import 'package:x_trainer/common_widget/google_sign_in_button.dart';
import 'package:x_trainer/providers/profile_provider.dart';
import 'package:x_trainer/view/login/signup_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController txtFirstName = TextEditingController();
  final TextEditingController txtLastName = TextEditingController();
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  final TextEditingController txtConfirmPassword = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    txtFirstName.dispose();
    txtLastName.dispose();
    txtEmail.dispose();
    txtPassword.dispose();
    txtConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (txtFirstName.text.isEmpty ||
        txtLastName.text.isEmpty ||
        txtEmail.text.isEmpty ||
        txtPassword.text.isEmpty ||
        txtConfirmPassword.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (txtPassword.text != txtConfirmPassword.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // إنشاء المستخدم في Firebase Auth
      UserCredential cred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: txtEmail.text.trim(),
        password: txtPassword.text.trim(),
      );

      final uid = cred.user!.uid;

      // إنشاء مستند للمستخدم في Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': txtFirstName.text.trim(),
        'lastName': txtLastName.text.trim(),
        'email': txtEmail.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'profileCompleted': false,
      });

      if (!mounted) return;

      // الانتقال إلى شاشة إكمال البروفايل
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CompleteProfileView(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError('Email already in use');
      } else if (e.code == 'weak-password') {
        _showError('Password is too weak');
      } else {
        _showError(e.message ?? 'Registration failed');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final isNewUser = await profile.signInWithGoogle();

      if (!mounted) return;

      if (isNewUser) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CompleteProfileView()),
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'account-exists-with-different-credential') {
        _showError('This email is already registered. Please log in with your email and password.');
      } else {
        _showError(e.message ?? 'Google sign-in failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  // ويدجت مخصص لحل مشكلة أيقونة الاسم
  Widget _buildPersonTextField(TextEditingController controller, String hint) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 15),
            // ✅ هنا الحل: استخدمنا أيقونة جاهزة بدل الصورة الناقصة
            child: Icon(Icons.person, color: TColor.gray, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final isSmallScreen = media.width < 360;
    final isTablet = media.width >= 600;

    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: TColor.black,
            size: 20,
          ),
        ),
        title: Text(
          "Sign Up",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : media.width,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 20,
              vertical: isSmallScreen ? 10 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: isSmallScreen ? 10 : media.width * 0.05),
                Text(
                  "Hey there,",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
                Text(
                  "Create Account",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 15 : media.width * 0.05),

                // ✅ استبدلنا RoundTextField بالويدجت المخصص الجديد
                Row(
                  children: [
                    Expanded(
                      child: _buildPersonTextField(txtFirstName, "First Name"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPersonTextField(txtLastName, "Last Name"),
                    ),
                  ],
                ),

                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtEmail,
                  hitText: "Email",
                  icon: "assets/img/email.png",
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: txtPassword,
                  hitText: "Password",
                  icon: "assets/img/lock.png",
                  obscureText: _obscurePassword,
                  rigtIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
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
                  hitText: "Confirm Password",
                  icon: "assets/img/lock.png",
                  obscureText: _obscureConfirm,
                  rigtIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: TColor.gray,
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.06),
                if (_isLoading)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation(TColor.primaryColor1),
                      ),
                    ),
                  )
                else
                  RoundButton(
                    title: "Sign Up",
                    onPressed: _signUp,
                  ),
                SizedBox(height: media.width * 0.04),
                const Text(
                  "Or",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                SizedBox(height: media.width * 0.04),
                GoogleSignInButton(
                  onPressed: _handleGoogleSignIn,
                ),
                SizedBox(height: media.width * 0.04),
                // Back to login link
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        size: 14,
                        color: TColor.gray,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Back to Login",
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 14,
                        ),
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