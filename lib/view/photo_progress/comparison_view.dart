import 'package:x_trainer/common_widget/icon_title_next_row.dart';
import 'package:x_trainer/common_widget/round_button.dart';
import 'package:x_trainer/view/photo_progress/result_view.dart';
import 'package:flutter/material.dart';

import '../../common/color_extension.dart';

class ComparisonView extends StatefulWidget {
  const ComparisonView({super.key});

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  DateTime? _selectedMonth1;
  DateTime? _selectedMonth2;

  void _selectMonth1() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth1 ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Month 1',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth1 = DateTime(picked.year, picked.month);
      });
    }
  }

  void _selectMonth2() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth2 ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Month 2',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth2 = DateTime(picked.year, picked.month);
      });
    }
  }

  void _compareMonths() {
    if (_selectedMonth1 == null || _selectedMonth2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both months to compare'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultView(
          date1: _selectedMonth1!,
          date2: _selectedMonth2!,
        ),
      ),
    );
  }

  String _formatMonth(DateTime? date) {
    if (date == null) return "Select Month";
    return "${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Comparison",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: () {
// Reset both selections
              setState(() {
                _selectedMonth1 = null;
                _selectedMonth2 = null;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset(
                "assets/img/reset.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            IconTitleNextRow(
                icon: "assets/img/date.png",
                title: "Select Month 1",
                time: _formatMonth(_selectedMonth1),
                onPressed: _selectMonth1,
                color: TColor.lightGray),
            const SizedBox(
              height: 15,
            ),
            IconTitleNextRow(
                icon: "assets/img/date.png",
                title: "Select Month 2",
                time: _formatMonth(_selectedMonth2),
                onPressed: _selectMonth2,
                color: TColor.lightGray),
            const Spacer(),
            RoundButton(
              title: "Compare",
              onPressed: _compareMonths,
            ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}
