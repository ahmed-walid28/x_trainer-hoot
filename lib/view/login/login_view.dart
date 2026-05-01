import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:x_trainer/common/color_extension.dart';
import 'package:x_trainer/common_widget/round_button.dart';
import 'package:x_trainer/common_widget/round_textfield.dart';
import 'package:x_trainer/common_widget/google_sign_in_button.dart';
import 'package:x_trainer/providers/profile_provider.dart';
import 'package:x_trainer/view/login/sign_up_view.dart';
import 'package:x_trainer/view/login/signup_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (txtEmail.text.isEmpty || txtPassword.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 [LoginView] Starting login...');
      print('📧 Email: ${txtEmail.text}');

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: txtEmail.text.trim(),
        password: txtPassword.text.trim(),
      );

      print('✅ [LoginView] Login successful!');

      if (!mounted) return;

      // نروح على /home اللي بتفتح MainTabView (اللي فيه الناف بار)
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      print('❌ [LoginView] Firebase error: ${e.code}');
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        _showError('Invalid email or password');
      } else {
        _showError('Error: ${e.message}');
      }
    } catch (e) {
      print('❌ [LoginView] General error: $e');
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

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email to reset password'),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: emailController.text.trim(),
                    );
                    Navigator.pop(context);
                    _showError('Password reset email sent!');
                  } catch (e) {
                    _showError(e.toString());
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    txtEmail.dispose();
    txtPassword.dispose();
    super.dispose();
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
                SizedBox(height: media.width * 0.1),
                Text(
                  "Hey there,",
                  style: TextStyle(color: TColor.gray, fontSize: 16),
                ),
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: media.width * 0.05),
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
                    title: "Login",
                    onPressed: _login,
                  ),
                SizedBox(height: media.width * 0.04),
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    "Forgot your password?",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.04),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpView(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: "Register",
                          style: TextStyle(
                            color: TColor.primaryColor1,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
