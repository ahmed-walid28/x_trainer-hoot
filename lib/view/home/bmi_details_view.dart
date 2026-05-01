import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../providers/profile_provider.dart';

class BMIDetailsView extends StatelessWidget {
  const BMIDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final profile = Provider.of<ProfileProvider>(context);

    final double? height = double.tryParse(profile.height);
    final double? weight = double.tryParse(profile.weight);

    double? bmi;
    String category = "No Data";
    String categoryDescription = "Please add your height and weight in profile";
    Color categoryColor = TColor.gray;

    if (height != null && weight != null && height > 0 && weight > 0) {
      final double heightInMeters = height / 100;
      bmi = weight / (heightInMeters * heightInMeters);

      if (bmi < 18.5) {
        category = "Underweight";
        categoryDescription = "You need to gain weight. Consider increasing your calorie intake and building muscle mass.";
        categoryColor = Colors.blue;
      } else if (bmi < 25) {
        category = "Normal Weight";
        categoryDescription = "Great job! You have a healthy weight. Maintain it with regular exercise and balanced diet.";
        categoryColor = Colors.green;
      } else if (bmi < 30) {
        category = "Overweight";
        categoryDescription = "Consider losing some weight through diet and exercise to reach a healthier range.";
        categoryColor = Colors.orange;
      } else {
        category = "Obese";
        categoryDescription = "It's recommended to consult a healthcare professional and start a weight loss program.";
        categoryColor = Colors.red;
      }
    }

    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "BMI Details",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BMI Value Card
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: TColor.primaryG),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    Text(
                      "Your BMI",
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (bmi != null)
                      Text(
                        bmi.toStringAsFixed(1),
                        style: TextStyle(
                          color: TColor.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Text(
                        "--",
                        style: TextStyle(
                          color: TColor.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Height",
                      profile.height.isNotEmpty ? "${profile.height} cm" : "--",
                      "assets/img/hight.png",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      "Weight",
                      profile.weight.isNotEmpty ? "${profile.weight} kg" : "--",
                      "assets/img/weight.png",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Description
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: categoryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "What this means",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      categoryDescription,
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // BMI Categories Reference
              Text(
                "BMI Categories",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 15),
              _buildCategoryItem("Underweight", "< 18.5", Colors.blue, bmi != null && bmi < 18.5),
              _buildCategoryItem("Normal weight", "18.5 - 24.9", Colors.green, bmi != null && bmi >= 18.5 && bmi < 25),
              _buildCategoryItem("Overweight", "25 - 29.9", Colors.orange, bmi != null && bmi >= 25 && bmi < 30),
              _buildCategoryItem("Obese", "≥ 30", Colors.red, bmi != null && bmi >= 30),
              const SizedBox(height: 30),

              // Formula Info
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: TColor.primaryColor2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: TColor.primaryColor2.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate,
                      color: TColor.primaryColor1,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "BMI Formula: weight (kg) / height (m)²",
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 12,
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
    );
  }

  Widget _buildStatCard(String title, String value, String iconPath) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            iconPath,
            width: 30,
            height: 30,
            color: TColor.primaryColor1,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String label, String range, Color color, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : TColor.lightGray,
        borderRadius: BorderRadius.circular(15),
        border: isActive
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                label,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            range,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
