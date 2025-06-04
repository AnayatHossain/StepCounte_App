import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GoalAchievedBottomSheet extends StatefulWidget {
  final bool isDarkTheme;
  final bool isEnglish;
  final int achievedSteps;
  final int dailyGoal;

  const GoalAchievedBottomSheet({
    super.key,
    required this.isDarkTheme,
    required this.isEnglish,
    required this.achievedSteps,
    required this.dailyGoal,
  });

  @override
  State<GoalAchievedBottomSheet> createState() =>
      _GoalAchievedBottomSheetState();
}

class _GoalAchievedBottomSheetState extends State<GoalAchievedBottomSheet> {
  bool _showCelebration = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showCelebration = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkTheme ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(25),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration Animation
            if (_showCelebration)
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  'assets/celebration.json',
                  fit: BoxFit.contain,
                ),
              ),

            // Success Message
            Text(
              widget.isEnglish ? 'GOAL ACHIEVED!' : 'লক্ষ্য অর্জিত!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: widget.isDarkTheme ? Colors.white : Colors.green[800],
              ),
            ),
            const SizedBox(height: 15),

            // Steps Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDarkTheme ? Colors.grey[800] : Colors.green[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isEnglish ? 'Your Steps:' : 'আপনার পদক্ষেপ:',
                        style: TextStyle(
                          fontSize: 18,
                          color: widget.isDarkTheme
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      Text(
                        '${widget.achievedSteps}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isEnglish ? 'Daily Goal:' : 'দৈনিক লক্ষ্য:',
                        style: TextStyle(
                          fontSize: 18,
                          color: widget.isDarkTheme
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      Text(
                        '${widget.dailyGoal}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkTheme
                              ? Colors.blue[300]
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Motivational Message
            Text(
              widget.isEnglish
                  ? 'You did amazing today!\nKeep up the great work!'
                  : 'আপনি আজ অসাধারণ করেছেন!\nভালো কাজ চালিয়ে যান!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: widget.isDarkTheme ? Colors.white70 : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 30),

            // Close Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.isEnglish ? 'AWESOME!' : 'দারুণ!',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
