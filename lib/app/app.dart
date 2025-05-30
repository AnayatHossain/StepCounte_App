import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:step_counter/app/home_screen.dart';

class StepCounter extends StatelessWidget {
  const StepCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        textTheme: GoogleFonts.hindSiliguriTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: HomeScreen(),
    );
  }
}
