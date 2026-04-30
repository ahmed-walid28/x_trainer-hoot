import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _analyzeCalories() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // ✅ الرابط الجديد المباشر من Replit
      var uri = Uri.parse('https://a093ec37-ccee-4e87-8f04-f34d3198d9cf-00-zfiuu5b4y2hh.spock.replit.dev:8080/analyze_food');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        String resultText = jsonResponse['data'] ?? "";
        String parsedName = "Unknown Food";
        String parsedCalories = "0";

        final lines = resultText.split('\n');
        for (var line in lines) {
          if (line.toLowerCase().contains("food name:")) {
            parsedName = line.substring(line.indexOf(":") + 1).trim();
          } else if (line.toLowerCase().contains("calories:")) {
            parsedCalories = line.substring(line.indexOf(":") + 1).replaceAll(RegExp(r'[^0-9]'), '').trim();
          }
        }

        setState(() {
          _isAnalyzing = false;
          _foodName = parsedName;
          _calorieResult = parsedCalories;
        });
      } else {
        setState(() {
          _isAnalyzing = false;
          _foodName = "Server Error";
          _calorieResult = "0";
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _foodName = "Connection Error";
        _calorieResult = "0";
      });
    }
  }

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

  Widget _optionTile({required IconData icon, required String title, required VoidCallback onTap}) {
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
              colors: [Color(0xffF5A3D7), Color(0xffA8C2FF), Color(0xffB58BFF)],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xff5D4D85))),
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
                BoxShadow(color: const Color(0xffC27BFF).withOpacity(0.28), blurRadius: 46, spreadRadius: 12),
                BoxShadow(color: const Color(0xffF1A8D8).withOpacity(0.18), blurRadius: 40, spreadRadius: 7),
              ],
            ),
            child: const Center(
              child: Text("Food\nScanner", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, height: 1.2, fontSize: 18, fontWeight: FontWeight.w700)),
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
                colors: [Color(0xffFCFBFF), Color(0xffF5F0FF), Color(0xffEEF4FF)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xffB897F9).withOpacity(0.24), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Stack(
              children: [
                // الدوائر الطائرة الخلفية
                Positioned(top: 68, left: 22, child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffD7C9FF).withOpacity(0.26)))),
                Positioned(top: 120, right: 34, child: Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffB9D2FF).withOpacity(0.24)))),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: Color(0xff6A5B93))),
                          const Spacer(),
                          const Text("Calorie AI", style: TextStyle(color: Color(0xff605083), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (_selectedImage == null) ...[
                                const SizedBox(height: 60),
                                _buildDotRing(),
                                const SizedBox(height: 60),
                                GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xffF2A8D7), Color(0xffA389FF), Color(0xff8EBBFF)]),
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [BoxShadow(color: const Color(0xffC5A8FF).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
                                    ),
                                    child: const Text('Scan Your Meal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  height: media.width * 0.65,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                                  child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.file(_selectedImage!, fit: BoxFit.cover)),
                                ),
                                const SizedBox(height: 25),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: _isAnalyzing ? null : _analyzeCalories,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffA389FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                    child: _isAnalyzing ? const CircularProgressIndicator(color: Colors.white) : const Text('Analyze Calories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                if (_calorieResult != null) ...[
                                  const SizedBox(height: 25),
                                  Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xffE6DEFF))),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.restaurant, color: Color(0xffB58BFF), size: 28),
                                            const SizedBox(width: 15),
                                            Expanded( // ✅ حل الـ Overflow النهائي
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(_foodName ?? 'Meal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff5D4D85)), overflow: TextOverflow.ellipsis),
                                                  const Text('Estimated Nutrition', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 40),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(_calorieResult!, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xff5F4E8E))),
                                            const SizedBox(width: 5),
                                            const Text('kcal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xff8E7AB7))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
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
    final paint = Paint()..style = PaintingStyle.fill;
    // نقاط الحلقة بشكل مبسط وسريع
    for (int i = 0; i < 40; i++) {
      double angle = i * (math.pi * 2) / 40;
      double radius = 100.0 + (i % 2 == 0 ? 5 : -5);
      canvas.drawCircle(Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius), 3.5, paint..color = const Color(0xffC890FF).withOpacity(0.7));
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}