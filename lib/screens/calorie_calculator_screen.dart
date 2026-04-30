import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../common/color_extension.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalorieCalculatorScreen extends StatefulWidget {
  const CalorieCalculatorScreen({super.key});

  @override
  State<CalorieCalculatorScreen> createState() => _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? _calorieResult;
  String? _foodName;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _calorieResult = null;
        _foodName = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _calorieResult = null;
        _foodName = null;
      });
    }
  }

  // 👇 دالة الذكاء الاصطناعي الجديدة المربوطة بسيرفر البايثون بتاعك 👇
  Future<void> _analyzeCalories() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // ⚠️ هنا حطينا الـ IP بتاع السيرفر اللي ظهرلك في بايثون
      var uri = Uri.parse('https://upward-exact-armed.ngrok-free.dev/analyze_food');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

      // بنبعت الطلب ونستنى الرد من السيرفر بتاعك
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        // لو السيرفر رد بنجاح، بنفصل النتيجة
        String resultText = jsonResponse['data'] ?? "";

        String parsedName = "Unknown Food";
        String parsedCalories = "0";

        final lines = resultText.split('\n');
        for (var line in lines) {
          if (line.toLowerCase().startsWith("food name:")) {
            parsedName = line.substring(line.indexOf(":") + 1).trim();
          } else if (line.toLowerCase().startsWith("calories:")) {
            parsedCalories = line.substring(line.indexOf(":") + 1).replaceAll(RegExp(r'[^0-9]'), '').trim();
          }
        }

        setState(() {
          _isAnalyzing = false;
          _foodName = parsedName;
          _calorieResult = parsedCalories;
        });
      } else {
        // لو حصل مشكلة في السيرفر
        setState(() {
          _isAnalyzing = false;
          _foodName = "Server Error";
          _calorieResult = "0";
        });
      }
    } catch (e) {
      // لو الموبايل مقدرش يوصل للسيرفر
      setState(() {
        _isAnalyzing = false;
        _foodName = "Connection Error";
        _calorieResult = "0";
      });
      print("Backend Error: $e");
    }
  }
  // 👆 نهاية الدالة 👆

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        decoration: const BoxDecoration(
          color: Color(0xffF9F6FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            _optionTile(
              icon: Icons.camera_alt_rounded,
              title: "Take Photo",
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            _optionTile(
              icon: Icons.image_rounded,
              title: "Upload Image",
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffB8A1F8).withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xffF5A3D7),
                Color(0xffA8C2FF),
                Color(0xffB58BFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xff5D4D85),
          ),
        ),
      ),
    );
  }

  Widget _buildDotRing() {
    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: CalorieDotRingPainter(),
        child: Center(
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xffC27BFF).withOpacity(0.98),
                  const Color(0xffB18FFF).withOpacity(0.82),
                  const Color(0xffF0A9D6).withOpacity(0.32),
                  const Color(0xff8DBEFF).withOpacity(0.16),
                  const Color(0xff8DBEFF).withOpacity(0.02),
                ],
                stops: const [0.14, 0.34, 0.58, 0.82, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffC27BFF).withOpacity(0.28),
                  blurRadius: 46,
                  spreadRadius: 12,
                ),
                BoxShadow(
                  color: const Color(0xffF1A8D8).withOpacity(0.18),
                  blurRadius: 40,
                  spreadRadius: 7,
                ),
                BoxShadow(
                  color: const Color(0xff9CBEFF).withOpacity(0.16),
                  blurRadius: 54,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Food\nScanner",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.2,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xffEEF1FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xffFCFBFF),
                  Color(0xffF5F0FF),
                  Color(0xffEEF4FF),
                ],
              ),
              border: Border.all(
                color: Colors.white70,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffB897F9).withOpacity(0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 68,
                  left: 22,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffD7C9FF).withOpacity(0.26),
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  right: 34,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffB9D2FF).withOpacity(0.24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 158,
                  left: 26,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffEACFFF).withOpacity(0.22),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 19,
                              color: Color(0xff6A5B93),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.84),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xffCAB3FF).withOpacity(0.16),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: Color(0xffD6C3FF),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Calorie AI",
                                  style: TextStyle(
                                    color: Color(0xff605083),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Color(0xff605083),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _selectedImage == null
                            ? Column(
                          children: [
                            const Spacer(),
                            _buildDotRing(),
                            const Spacer(),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xffF2A8D7),
                                      Color(0xffA389FF),
                                      Color(0xff8EBBFF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffC5A8FF).withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Tap to upload food image',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                          ],
                        )
                            : SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: media.width * 0.65,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffC5A8FF).withOpacity(0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Stack(
                                    children: [
                                      Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImage = null;
                                              _calorieResult = null;
                                              _foodName = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isAnalyzing ? null : _analyzeCalories,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xffF2A8D7),
                                          Color(0xffA389FF),
                                          Color(0xff8EBBFF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xffC5A8FF).withOpacity(0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isAnalyzing
                                          ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Analyzing...', style: TextStyle(color: Colors.white, fontSize: 15)),
                                        ],
                                      )
                                          : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.calculate, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text('Analyze Calories', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_calorieResult != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xffFCFBFF),
                                        const Color(0xffF5F0FF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(color: const Color(0xffE6DEFF)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xffCBB8FF).withOpacity(0.12),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xffF5A3D7),
                                                  Color(0xffA8C2FF),
                                                  Color(0xffB58BFF),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Icon(Icons.restaurant, color: Colors.white, size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _foodName ?? 'Meal',
                                                  style: const TextStyle(
                                                    color: Color(0xff5D4D85),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const Text(
                                                  'Estimated Nutrition',
                                                  style: TextStyle(
                                                    color: Color(0xff8E7AB7),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _calorieResult!,
                                            style: const TextStyle(
                                              color: Color(0xff5F4E8E),
                                              fontSize: 46,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            ' kcal',
                                            style: TextStyle(
                                              color: Color(0xff8E7AB7),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 16, color: Color(0xff8E7AB7)),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Based on visual recognition • Powered by Gemini AI',
                                                style: TextStyle(color: Color(0xff7B6BA3), fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                            ],
                          ),
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

class CalorieDotRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final points = <Map<String, dynamic>>[
      {"a": 3.65, "r": 104.0, "s": 6.0, "c": const Color(0xffC890FF)},
      {"a": 3.82, "r": 98.0, "s": 5.4, "c": const Color(0xffF2B0DA)},
      {"a": 3.96, "r": 96.0, "s": 5.0, "c": const Color(0xffC890FF)},
      {"a": 4.08, "r": 100.0, "s": 4.8, "c": const Color(0xffA6C6FF)},
      {"a": 4.18, "r": 108.0, "s": 5.8, "c": const Color(0xffC890FF)},
      {"a": 4.28, "r": 101.0, "s": 4.6, "c": const Color(0xffF2B0DA)},
      {"a": 4.36, "r": 95.0, "s": 4.0, "c": const Color(0xffC890FF)},
      {"a": 4.46, "r": 103.0, "s": 5.0, "c": const Color(0xffA6C6FF)},
      {"a": 4.58, "r": 98.0, "s": 4.2, "c": const Color(0xffC890FF)},
      {"a": 4.70, "r": 92.0, "s": 3.4, "c": const Color(0xffF2B0DA)},
      {"a": 4.84, "r": 100.0, "s": 4.8, "c": const Color(0xffC890FF)},
      {"a": 4.98, "r": 110.0, "s": 3.2, "c": const Color(0xffA6C6FF)},
      {"a": 5.08, "r": 96.0, "s": 3.8, "c": const Color(0xffC890FF)},
      {"a": 5.18, "r": 104.0, "s": 3.0, "c": const Color(0xffF2B0DA)},
      {"a": 5.28, "r": 99.0, "s": 4.4, "c": const Color(0xffC890FF)},
      {"a": 5.42, "r": 107.0, "s": 3.5, "c": const Color(0xffA6C6FF)},
      {"a": 5.58, "r": 112.0, "s": 2.8, "c": const Color(0xffC890FF)},
      {"a": 5.76, "r": 104.0, "s": 2.5, "c": const Color(0xffF2B0DA)},
      {"a": 5.96, "r": 96.0, "s": 2.2, "c": const Color(0xffC890FF)},
      {"a": 0.10, "r": 100.0, "s": 5.6, "c": const Color(0xffC890FF)},
      {"a": 0.26, "r": 108.0, "s": 4.2, "c": const Color(0xffA6C6FF)},
      {"a": 0.42, "r": 98.0, "s": 3.6, "c": const Color(0xffF2B0DA)},
      {"a": 0.62, "r": 105.0, "s": 3.8, "c": const Color(0xffC890FF)},
      {"a": 0.86, "r": 102.0, "s": 2.7, "c": const Color(0xffA6C6FF)},
      {"a": 1.04, "r": 96.0, "s": 2.5, "c": const Color(0xffC890FF)},
      {"a": 1.24, "r": 103.0, "s": 4.8, "c": const Color(0xffF2B0DA)},
      {"a": 1.38, "r": 96.0, "s": 3.4, "c": const Color(0xffC890FF)},
      {"a": 1.52, "r": 106.0, "s": 5.2, "c": const Color(0xffA6C6FF)},
      {"a": 1.66, "r": 98.0, "s": 4.0, "c": const Color(0xffC890FF)},
      {"a": 1.82, "r": 108.0, "s": 3.6, "c": const Color(0xffF2B0DA)},
      {"a": 2.02, "r": 101.0, "s": 3.1, "c": const Color(0xffC890FF)},
      {"a": 2.18, "r": 95.0, "s": 4.3, "c": const Color(0xffA6C6FF)},
      {"a": 2.34, "r": 104.0, "s": 5.4, "c": const Color(0xffC890FF)},
      {"a": 2.52, "r": 98.0, "s": 3.2, "c": const Color(0xffF2B0DA)},
      {"a": 2.72, "r": 106.0, "s": 4.6, "c": const Color(0xffC890FF)},
      {"a": 2.98, "r": 103.0, "s": 3.6, "c": const Color(0xffA6C6FF)},
      {"a": 3.14, "r": 110.0, "s": 2.8, "c": const Color(0xffC890FF)},
      {"a": 3.30, "r": 101.0, "s": 4.0, "c": const Color(0xffF2B0DA)},
      {"a": 3.46, "r": 97.0, "s": 3.0, "c": const Color(0xffC890FF)},
      {"a": 4.00, "r": 83.0, "s": 2.2, "c": const Color(0xffDCC2FF)},
      {"a": 4.22, "r": 87.0, "s": 1.9, "c": const Color(0xffDCC2FF)},
      {"a": 4.46, "r": 84.0, "s": 2.0, "c": const Color(0xffDCC2FF)},
      {"a": 4.78, "r": 86.0, "s": 2.4, "c": const Color(0xffDCC2FF)},
      {"a": 5.12, "r": 82.0, "s": 1.8, "c": const Color(0xffDCC2FF)},
      {"a": 5.88, "r": 84.0, "s": 2.1, "c": const Color(0xffDCC2FF)},
      {"a": 0.38, "r": 85.0, "s": 1.9, "c": const Color(0xffDCC2FF)},
      {"a": 1.32, "r": 83.0, "s": 2.3, "c": const Color(0xffDCC2FF)},
      {"a": 2.18, "r": 86.0, "s": 2.0, "c": const Color(0xffDCC2FF)},
      {"a": 2.92, "r": 82.0, "s": 1.8, "c": const Color(0xffDCC2FF)},
    ];

    for (final p in points) {
      final angle = p["a"] as double;
      final radius = p["r"] as double;
      final dotSize = p["s"] as double;
      final color = p["c"] as Color;

      final dx = center.dx + math.cos(angle) * radius;
      final dy = center.dy + math.sin(angle) * radius;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(0.95);

      canvas.drawCircle(Offset(dx, dy), dotSize, paint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xffD394FF).withOpacity(0.18),
          const Color(0xffF3B1DC).withOpacity(0.08),
          const Color(0xffA7C3FF).withOpacity(0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 130));

    canvas.drawCircle(center, 130, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}