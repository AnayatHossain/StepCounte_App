import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class WeeklyStatsCards extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final bool isDarkTheme;
  final bool isEnglish;

  const WeeklyStatsCards({
    super.key,
    required this.weeklyData,
    required this.isDarkTheme,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Center(
            child: Text(
              isEnglish ? 'Weekly Stats' : 'সাপ্তাহিক স্ট্যাটাস',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : Colors.blue,
              ),
            ),
          ),
        ),
        Divider(color: isDarkTheme ? Colors.white : Colors.grey, thickness: 1),
        const SizedBox(height: 10),
        SizedBox(
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: weeklyData.length,
            itemBuilder: (context, index) {
              final dayData = weeklyData[index];

              final dayName = DateFormat(
                'EEEE',
                isEnglish ? 'en_US' : 'bn_BD',
              ).format(dayData['date']);

              final calories = dayData['calories'] as double? ?? 0;
              final distance = dayData['distance'] as double? ?? 0;
              final minutes = dayData['minutes'] as double? ?? 0;

              final isToday =
                  DateFormat('dd-MM-yyyy').format(dayData['date']) ==
                  DateFormat('dd-MM-yyyy').format(DateTime.now());

              final cardColor = isToday
                  ? (isDarkTheme ? Colors.blue[700] : Colors.blue[300])
                  : (isDarkTheme ? Colors.grey[800] : Colors.grey[100]);

              final textColor = isDarkTheme ? Colors.white : Colors.black87;

              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (isToday)
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          height: 20,
                          child: Lottie.asset(
                            "assets/calorie.json",
                            fit: BoxFit.contain,
                            repeat: true,
                            frameRate: FrameRate.max,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${calories.toStringAsFixed(1)} ${isEnglish ? "Cal" : "ক্যাল"}',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          height: 20,
                          child: Lottie.asset(
                            "assets/distance.json",
                            fit: BoxFit.contain,
                            repeat: true,
                            frameRate: FrameRate.max,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${distance.toStringAsFixed(2)} ${isEnglish ? "km" : "কি.মি."}',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          height: 20,
                          child: Lottie.asset(
                            "assets/watch.json",
                            fit: BoxFit.contain,
                            repeat: true,
                            frameRate: FrameRate.max,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${minutes.toStringAsFixed(0)} ${isEnglish ? "min" : "মিনিট"}',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
