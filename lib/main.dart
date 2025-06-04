import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:step_counter/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox<int>('stepsBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('weeklyBox');

  runApp(const StepCounter());
}
