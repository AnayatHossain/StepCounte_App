import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:step_counter/app/versions/version.dart';

class SplashScreenWidget extends StatelessWidget {
  final bool isDarkTheme;
  final bool isEnglish;

  const SplashScreenWidget({
    super.key,
    required this.isDarkTheme,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/step_count.json',
              height: 250,
              fit: BoxFit.contain,
            ),
            Text(
              isEnglish ? 'Step Counter' : 'স্টেপস কাউন্টার',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 300),
            Text(
              getVersion(isEnglish),
              style: TextStyle(
                fontSize: 14,
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              isEnglish
                  ? "© Anayat Hossain All rights reserved."
                  : "© এনায়েত হোসেন সর্বস্বত্ব সংরক্ষিত।",
              style: TextStyle(
                fontSize: 12,
                color: isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
