import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyStepsChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final int dailyGoal;
  final bool isDarkTheme;
  final bool isEnglish;

  const WeeklyStepsChart({
    super.key,
    required this.weeklyData,
    required this.dailyGoal,
    required this.isDarkTheme,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF3E3B3B) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              isEnglish ? 'Weekly Steps' : 'সাপ্তাহিক স্টেপস',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weeklyData.map((data) {
              final height = (data['steps'] / dailyGoal * 100).clamp(
                10.0,
                100.0,
              );
              final isToday =
                  DateFormat('dd-MM-yyyy').format(data['date']) ==
                  DateFormat('dd-MM-yyyy').format(DateTime.now());

              final dayName = DateFormat(
                'E',
                isEnglish ? 'en_US' : 'bn_BD',
              ).format(data['date']);

              return Column(
                children: [
                  Container(
                    width: 35,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      gradient: isToday
                          ? LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                            )
                          : null,
                      color: !isToday ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkTheme ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
