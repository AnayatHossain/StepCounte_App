import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:step_counter/app/app.dart';
import 'package:upgrader/upgrader.dart'; // এটা লাগবে upgrader প্যাকেজের জন্য

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Hive.initFlutter();

  await Hive.openBox<int>('stepsBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('weeklyBox');

  runApp(UpgradeAlert(child: StepCounter()));
}
