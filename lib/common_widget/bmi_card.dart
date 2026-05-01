import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../common/color_extension.dart';
import '../providers/profile_provider.dart';
import '../view/home/bmi_details_view.dart';
import 'round_button.dart';

class BMICard extends StatelessWidget {
  const BMICard({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Consumer<ProfileProvider>(
      builder: (context, profile, child) {
        final double? height = double.tryParse(profile.height);
        final double? weight = double.tryParse(profile.weight);

        // Calculate BMI if valid data exists
        double? bmi;
        String category = "normal";
        Color categoryColor = TColor.secondaryColor1;

        if (height != null && weight != null && height > 0 && weight > 0) {
          final double heightInMeters = height / 100;
          bmi = weight / (heightInMeters * heightInMeters);

          // Classification logic
          if (bmi < 18.5) {
            category = "low";
            categoryColor = Colors.blue;
          } else if (bmi < 25) {
            category = "normal";
            categoryColor = Colors.green;
          } else if (bmi < 30) {
            category = "high";
            categoryColor = Colors.orange;
          } else {
            category = "high";
            categoryColor = Colors.red;
          }
        }

        return Container(
          height: media.width * 0.4,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: TColor.primaryG),
            borderRadius: BorderRadius.circular(media.width * 0.075),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                "assets/img/bg_dots.png",
                height: media.width * 0.4,
                width: double.maxFinite,
                fit: BoxFit.fitHeight,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "BMI (Body Mass Index)",
                          style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "You have a ${bmi != null ? category : 'normal'} weight",
                          style: TextStyle(
                            color: TColor.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 120,
                          height: 35,
                          child: RoundButton(
                            title: "View More",
                            type: RoundButtonType.bgSGradient,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BMIDetailsView(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                          ),
                          startDegreeOffset: 250,
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 1,
                          centerSpaceRadius: 0,
                          sections: _buildSections(bmi, categoryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(double? bmi, Color color) {
    if (bmi == null) {
      // Default sections when no data
      return [
        PieChartSectionData(
          color: TColor.secondaryColor1,
          value: 33,
          title: '',
          radius: 55,
          titlePositionPercentageOffset: 0.55,
          badgeWidget: const Text(
            "20,1",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PieChartSectionData(
          color: Colors.white,
          value: 75,
          title: '',
          radius: 45,
          titlePositionPercentageOffset: 0.55,
        ),
      ];
    }

    // Calculate proportions based on BMI (max 40 for chart)
    final bmiValue = bmi.clamp(0.0, 40.0);
    final coloredValue = (bmiValue / 40) * 100;
    final whiteValue = 100 - coloredValue;

    return [
      PieChartSectionData(
        color: color,
        value: coloredValue,
        title: '',
        radius: 55,
        titlePositionPercentageOffset: 0.55,
        badgeWidget: Text(
          bmi.toStringAsFixed(1).replaceAll('.', ','),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      PieChartSectionData(
        color: Colors.white,
        value: whiteValue,
        title: '',
        radius: 45,
        titlePositionPercentageOffset: 0.55,
      ),
    ];
  }
}
