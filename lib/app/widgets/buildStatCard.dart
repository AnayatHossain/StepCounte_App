import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

Widget buildStatCard({
  required String animationPath, // Lottie animation path
  required String value,
  required String unit,
  required bool isDarkTheme,
  required bool isEnglish,
  required Color color,
}) {
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF3E3B3B) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: Lottie.asset(
              animationPath,
              fit: BoxFit.contain,
              repeat: true,
              frameRate: FrameRate.max,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: TextStyle(
              fontSize: 14,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}
