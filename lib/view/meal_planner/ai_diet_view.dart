import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:x_trainer/common/color_extension.dart';

class AiDietView extends StatefulWidget {
  const AiDietView({super.key});

  @override
  State<AiDietView> createState() => _AiDietViewState();
}

class _AiDietViewState extends State<AiDietView> {
  // بيانات المستخدم
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String selectedGender = "Male";
  String selectedGoal = "Weight Loss";

  // إضافات جديدة عشان توافق الموديل بتاعك
  bool hasHypertension = false; // الضغط
  bool hasDiabetes = false; // السكر

  String resultPlan = "";
  bool isLoading = false;

// لاحظ إننا زودنا /predict_diet في الآخر
  final String serverUrl = 'http://10.150.239.7:5000/predict_diet';
  // دالة لحساب مؤشر كتلة الجسم
  double calculateBMI(double weight, double heightCm) {
    double heightM = heightCm / 100; // تحويل لمتر
    return weight / (heightM * heightM);
  }

  // دالة لتحديد مستوى الجسم بناء على الـ BMI
  String determineLevel(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi >= 18.5 && bmi <= 24.9) return "Normal";
    if (bmi >= 25 && bmi <= 29.9) return "Overweight";
    return "Obese";
  }

  Future<void> getDietPlan() async {
    if (_ageController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _weightController.text.isEmpty) {
      setState(() {
        resultPlan = "Please fill all fields";
      });
      return;
    }

    setState(() {
      isLoading = true;
      resultPlan = "";
    });

    try {
      // تجهيز الأرقام والحسابات
      double weight = double.tryParse(_weightController.text) ?? 70;
      double height = double.tryParse(_heightController.text) ?? 170;
      int age = int.tryParse(_ageController.text) ?? 25;

      // حساب BMI و Level أوتوماتيك
      double bmi = calculateBMI(weight, height);
      String level = determineLevel(bmi);

      // إرسال الـ 9 معلومات للسيرفر
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Sex": selectedGender == "Male" ? 1 : 0,
          "Age": age,
          "Height": height / 100, // الموديل عايز الطول بالمتر
          "Weight": weight,
          "Hypertension": hasHypertension ? 1 : 0,
          "Diabetes": hasDiabetes ? 1 : 0,
          "BMI": bmi, // محسوب أوتوماتيك
          "Level": level, // محسوب أوتوماتيك
          "Fitness Goal": selectedGoal
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          resultPlan = data['diet_plan'] ?? "No plan found";
        });
      } else {
        setState(() {
          resultPlan = "Server Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        resultPlan = "Connection Error. Make sure Firewall is OFF.";
      });
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Diet Consultant",
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter your details:",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            _buildSimpleTextField("Age", _ageController, "e.g. 25"),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                    child: _buildSimpleTextField(
                        "Height (cm)", _heightController, "175")),
                const SizedBox(width: 15),
                Expanded(
                    child: _buildSimpleTextField(
                        "Weight (kg)", _weightController, "75")),
              ],
            ),
            const SizedBox(height: 15),

            _buildSimpleDropdown("Gender", ["Male", "Female"], selectedGender,
                (val) => setState(() => selectedGender = val!)),
            const SizedBox(height: 15),
            _buildSimpleDropdown(
                "Fitness Goal",
                ["Weight Loss", "Weight Gain", "Healthy"],
                selectedGoal,
                (val) => setState(() => selectedGoal = val!)),

            const SizedBox(height: 20),

            // أسئلة الضغط والسكر (إضافة جديدة)
            SwitchListTile(
              title: const Text("Do you have Hypertension?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              value: hasHypertension,
              activeThumbColor: TColor.primaryColor1,
              onChanged: (val) => setState(() => hasHypertension = val),
            ),
            SwitchListTile(
              title: const Text("Do you have Diabetes?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              value: hasDiabetes,
              activeThumbColor: TColor.primaryColor1,
              onChanged: (val) => setState(() => hasDiabetes = val),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : getDietPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primaryColor1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Generate Plan",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),

            const SizedBox(height: 30),

            if (resultPlan.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: TColor.primaryColor1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Recommended Plan:",
                        style: TextStyle(
                            color: TColor.primaryColor1,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(resultPlan,
                        style: const TextStyle(
                            fontSize: 16, height: 1.5, color: Colors.black87)),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTextField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDropdown(String label, List<String> items,
      String currentVal, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentVal,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
