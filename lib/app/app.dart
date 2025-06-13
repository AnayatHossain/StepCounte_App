import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:step_counter/app/home_screen.dart';
import 'package:step_counter/app/splash_screen.dart';

class StepCounter extends StatefulWidget {
  const StepCounter({super.key});

  @override
  State<StepCounter> createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  bool isDarkTheme = false;
  bool isEnglish = true;
  bool showSplash = true;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box('settingsBox');
    isDarkTheme = settingsBox.get('isDarkTheme', defaultValue: false);
    isEnglish = settingsBox.get('isEnglish', defaultValue: true);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showSplash = false;
        });
      }
    });
  }

  void updateTheme(bool value) {
    setState(() {
      isDarkTheme = value;
    });
    Hive.box('settingsBox').put('isDarkTheme', value);
  }

  void updateLanguage(bool value) {
    setState(() {
      isEnglish = value;
    });
    Hive.box('settingsBox').put('isEnglish', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        textTheme: GoogleFonts.hindSiliguriTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      locale: isEnglish ? const Locale('en', 'US') : const Locale('bn', 'BD'),
      supportedLocales: const [Locale('en', 'US'), Locale('bn', 'BD')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: showSplash
          ? SplashScreenWidget(isDarkTheme: isDarkTheme, isEnglish: isEnglish)
          : HomeScreen(
              isDarkTheme: isDarkTheme,
              isEnglish: isEnglish,
              onThemeChanged: updateTheme,
              onLanguageChanged: updateLanguage,
            ),
    );
  }
}
