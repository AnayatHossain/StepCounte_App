import 'package:flutter/material.dart';

import 'buildStatCard.dart';

class StatsRow extends StatelessWidget {
  final double calories;
  final double distance;
  final int steps;
  final bool isEnglish;
  final bool isDarkTheme;

  const StatsRow({
    super.key,
    required this.calories,
    required this.distance,
    required this.steps,
    required this.isEnglish,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildStatCard(
          animationPath: "assets/calorie.json",
          value: calories.toStringAsFixed(2),
          unit: isEnglish ? 'Calories' : 'ক্যালোরি',
          isDarkTheme: isDarkTheme,
          isEnglish: isEnglish,
          color: Colors.orange,
        ),
        buildStatCard(
          animationPath: "assets/distance.json",
          value: distance.toStringAsFixed(2),
          unit: isEnglish ? 'Kilometers' : 'কি.মি.',
          isDarkTheme: isDarkTheme,
          isEnglish: isEnglish,
          color: Colors.purple,
        ),
        buildStatCard(
          animationPath: "assets/watch.json",
          value: (steps * 0.008).toStringAsFixed(0),
          unit: isEnglish ? 'Minutes' : 'মিনিট',
          isDarkTheme: isDarkTheme,
          isEnglish: isEnglish,
          color: Colors.teal,
        ),
      ],
    );
  }
}
