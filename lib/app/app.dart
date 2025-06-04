import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'home_screen.dart';

class StepCounter extends StatefulWidget {
  const StepCounter({super.key});

  @override
  State<StepCounter> createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  bool isDarkTheme = false;
  bool isEnglish = true;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box('settingsBox');
    isDarkTheme = settingsBox.get('isDarkTheme', defaultValue: false);
    isEnglish = settingsBox.get('isEnglish', defaultValue: true);
  }

  void updateTheme(bool value) {
    setState(() => isDarkTheme = value);
    Hive.box('settingsBox').put('isDarkTheme', value);
  }

  void updateLanguage(bool value) {
    setState(() => isEnglish = value);
    Hive.box('settingsBox').put('isEnglish', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        textTheme: GoogleFonts.hindSiliguriTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: HomeScreen(
        isDarkTheme: isDarkTheme,
        isEnglish: isEnglish,
        onThemeChanged: updateTheme,
        onLanguageChanged: updateLanguage,
      ),
    );
  }
}
