import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyGoalDialog extends StatelessWidget {
  final bool isDarkTheme;
  final bool isEnglish;
  final int currentGoal;
  final Function(int) onGoalChanged;

  const DailyGoalDialog({
    required this.isDarkTheme,
    required this.isEnglish,
    required this.currentGoal,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: '$currentGoal');

    Gradient themeGradient = LinearGradient(
      colors: [Colors.blue[400]!, Colors.blue[600]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Dialog(
      backgroundColor: Colors.transparent, // Transparent to show gradient
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDarkTheme ? themeGradient : null,
          color: isDarkTheme ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEnglish ? 'Set Daily Goal' : 'দৈনিক লক্ষ্য নির্ধারণ করুন',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: isEnglish ? 'Steps Goal' : 'পদক্ষেপের লক্ষ্য',
                labelStyle: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.grey[800],
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDarkTheme ? Colors.white54 : Colors.grey,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text(
                    isEnglish ? 'Cancel' : 'বাতিল',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: Text(isEnglish ? 'Save' : 'সংরক্ষণ করুন'),
                  onPressed: () async {
                    final newGoal =
                        int.tryParse(controller.text) ?? currentGoal;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('dailyGoal', newGoal);
                    onGoalChanged(newGoal);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
