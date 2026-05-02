import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../common/color_extension.dart';

class WeeklyChart extends StatelessWidget {
  final List<QueryDocumentSnapshot> workoutDocs;

  const WeeklyChart({Key? key, required this.workoutDocs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<int, int> weeklyReps = _processData();
    int maxY = 0;
    weeklyReps.forEach((key, value) {
      if (value > maxY) maxY = value;
    });
    if (maxY == 0) maxY = 10;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TColor.primaryColor2.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Weekly Progress",
              style: TextStyle(
                color: TColor.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          );
                          String text = _getDayName(value.toInt());
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(text, style: style),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (weeklyReps[index] ?? 0).toDouble(),
                          color: TColor.secondaryColor1,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (maxY * 1.2).toDouble(),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  }),
                  maxY: (maxY * 1.2).toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<int, int> _processData() {
    Map<int, int> days = {};
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      days[i] = 0;
    }

    for (var doc in workoutDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? timestamp = data['date'];
      final int reps = data['reps'] ?? 0;

      if (timestamp != null) {
        DateTime date = timestamp.toDate();
        int diff = now.difference(date).inDays;
        if (diff >= 0 && diff < 7) {
          int chartIndex = 6 - diff;
          days[chartIndex] = (days[chartIndex] ?? 0) + reps;
        }
      }
    }
    return days;
  }

  String _getDayName(int index) {
    DateTime now = DateTime.now();
    DateTime date = now.subtract(Duration(days: 6 - index));
    return DateFormat('E').format(date);
  }
}
