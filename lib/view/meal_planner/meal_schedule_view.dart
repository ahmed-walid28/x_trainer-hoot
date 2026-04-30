import 'package:flutter/material.dart';

import '../../common/color_extension.dart';
import '../../common_widget/meal_food_schedule_row.dart';
import '../../common_widget/nutritions_row.dart';

class MealScheduleView extends StatefulWidget {
  const MealScheduleView({super.key});

  @override
  State<MealScheduleView> createState() => _MealScheduleViewState();
}

class _MealScheduleViewState extends State<MealScheduleView> {
  late DateTime _selectedDateAppBBar;

  List breakfastArr = [
    {
      "name": "Honey Pancake",
      "time": "07:00am",
      "image": "assets/img/honey_pan.png"
    },
    {"name": "Coffee", "time": "07:30am", "image": "assets/img/coffee.png"},
  ];

  List lunchArr = [
    {
      "name": "Chicken Steak",
      "time": "01:00pm",
      "image": "assets/img/chicken.png"
    },
    {
      "name": "Milk",
      "time": "01:20pm",
      "image": "assets/img/glass-of-milk 1.png"
    },
  ];
  List snacksArr = [
    {"name": "Orange", "time": "04:30pm", "image": "assets/img/orange.png"},
    {
      "name": "Apple Pie",
      "time": "04:40pm",
      "image": "assets/img/apple_pie.png"
    },
  ];
  List dinnerArr = [
    {"name": "Salad", "time": "07:10pm", "image": "assets/img/salad.png"},
    {"name": "Oatmeal", "time": "08:10pm", "image": "assets/img/oatmeal.png"},
  ];

  List nutritionArr = [
    {
      "title": "Calories",
      "image": "assets/img/burn.png",
      "unit_name": "kCal",
      "value": "350",
      "max_value": "500",
    },
    {
      "title": "Proteins",
      "image": "assets/img/proteins.png",
      "unit_name": "g",
      "value": "300",
      "max_value": "1000",
    },
    {
      "title": "Fats",
      "image": "assets/img/egg.png",
      "unit_name": "g",
      "value": "140",
      "max_value": "1000",
    },
    {
      "title": "Carbo",
      "image": "assets/img/carbo.png",
      "unit_name": "g",
      "value": "140",
      "max_value": "1000",
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateAppBBar = DateTime.now();
  }

  Widget _buildCalendar() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30, // 30 يوم
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index - 15));
          bool isSelected = _isSameDay(date, _selectedDateAppBBar);
          bool hasMeal = _hasMealOnDate(date);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateAppBBar = date;
              });
            },
            child: Container(
              width: 60,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: TColor.primaryG) : null,
                color: isSelected ? null : TColor.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      color: isSelected ? TColor.white : TColor.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      color: isSelected ? TColor.white : TColor.gray,
                      fontSize: 12,
                    ),
                  ),
                  if (hasMeal)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? TColor.white : TColor.primaryColor1,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _hasMealOnDate(DateTime date) {
    // في التطبيق الحقيقي، هنا بتكون فيه منطق للتحقق من وجود وجبات في هذا التاريخ
    // حالياً بنرجع true عشوائياً علشان نعرض النقاط
    return date.weekday % 2 == 0; // أيام زوجية فيها وجبات
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
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
          "Meal Schedule",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset(
                "assets/img/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar البديل
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: _buildCalendar(),
          ),
          Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "BreakFast",
                            style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${breakfastArr.length} Items | 230 calories",
                              style: TextStyle(color: TColor.gray, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                    ),
                    ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: breakfastArr.length,
                        itemBuilder: (context, index) {
                          var mObj = breakfastArr[index] as Map? ?? {};
                          return MealFoodScheduleRow(
                            mObj: mObj,
                            index: index,
                          );
                        }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Lunch",
                            style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${lunchArr.length} Items | 500 calories",
                              style: TextStyle(color: TColor.gray, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                    ),
                    ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: lunchArr.length,
                        itemBuilder: (context, index) {
                          var mObj = lunchArr[index] as Map? ?? {};
                          return MealFoodScheduleRow(
                            mObj: mObj,
                            index: index,
                          );
                        }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Snacks",
                            style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${snacksArr.length} Items | 140 calories",
                              style: TextStyle(color: TColor.gray, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                    ),
                    ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: snacksArr.length,
                        itemBuilder: (context, index) {
                          var mObj = snacksArr[index] as Map? ?? {};
                          return MealFoodScheduleRow(
                            mObj: mObj,
                            index: index,
                          );
                        }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Dinner",
                            style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${dinnerArr.length} Items | 120 calories",
                              style: TextStyle(color: TColor.gray, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                    ),
                    ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: dinnerArr.length,
                        itemBuilder: (context, index) {
                          var mObj = dinnerArr[index] as Map? ?? {};
                          return MealFoodScheduleRow(
                            mObj: mObj,
                            index: index,
                          );
                        }),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today Meal Nutritions",
                            style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: nutritionArr.length,
                        itemBuilder: (context, index) {
                          var nObj = nutritionArr[index] as Map? ?? {};

                          return NutritionRow(
                            nObj: nObj,
                          );
                        }),
                    SizedBox(
                      height: media.width * 0.05,
                    )
                  ],
                ),
              ))
        ],
      ),
    );
  }
}