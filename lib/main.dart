import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 1. ضيف المكتبة دي ضروري
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:x_trainer/common/color_extension.dart';
import 'package:x_trainer/providers/profile_provider.dart';
import 'package:x_trainer/view/login/login_view.dart';
import 'package:x_trainer/view/main_tab/main_tab_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👈 2. ثبت الشاشة على الوضع الطولي (Portrait) عشان الكاميرا والـ AI ميتلخبطوش
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تهيئة Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase Init Error: $e"); // حماية عشان لو في مشكلة نت التطبيق ميقفلش
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileProvider(),
      child: MaterialApp(
        title: 'Fitness App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: TColor.primaryColor1,
          fontFamily: "Poppins",
          scaffoldBackgroundColor: Colors.white,
        ),
        // تأكد ان المسارات دي مظبوطة عندك
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginView(),
          '/home': (context) => const MainTabView(),
        },
      ),
    );
  }
}