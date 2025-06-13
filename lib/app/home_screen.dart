import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_counter/app/widgets/daily_goal_dialog.dart';
import 'package:step_counter/app/widgets/goal_achieved_bottom_sheet.dart';
import 'package:step_counter/app/widgets/setting_screen_bottom_sheet.dart';
import 'package:step_counter/app/widgets/stats_row.dart';
import 'package:step_counter/app/widgets/step_progress_section.dart';
import 'package:step_counter/app/widgets/weekly_stats_cards.dart';
import 'package:step_counter/app/widgets/weekly_steps_chart.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkTheme;
  final bool isEnglish;
  final Function(bool) onThemeChanged;
  final Function(bool) onLanguageChanged;

  HomeScreen({
    required this.isDarkTheme,
    required this.isEnglish,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  Timer? _stepTimer;
  Timer? _sessionTimer;

  String _status = 'stopped';
  int _steps = 0;
  int _todaySteps = 0;
  bool _isWalking = false;
  bool _isIntialized = false;
  bool _isPermissionGranted = false;
  bool _isLoading = false;
  bool _goalAchievedShown = false;

  Random _random = Random();
  DateTime? _walkingStartTime;
  int _currentWalkingSession = 0;
  double _walkingPace = 1.0;
  int _consecutiveSteps = 0;

  double _calories = 0.0;
  double _distance = 0.0;
  int _dailyGoal = 1000;

  List<Map<String, dynamic>> _weeklyData = [];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _pedestrianStatusStream?.cancel();
    _stepTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isLoading = true;
    });
    final status = await Permission.activityRecognition.request();
    setState(() {
      _isPermissionGranted = status == PermissionStatus.granted;
    });

    if (_isPermissionGranted) {
      await _initializeApp();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _initializeApp() async {
    await _loadDailyGoal();
    await _loadTodaySteps();
    await _loadWeeklyData();
    await _loadMovementDirection();

    setState(() {
      _isIntialized = true;
    });
  }

  Future<void> _loadMovementDirection() async {
    try {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          _handleMovementChange(event.status);
        },
        onError: (error) {
          print("Error in pedestrian status stream: $error");
        },
      );
    } catch (e) {
      print("Error setting up movement detection: $e");
    }
  }

  void _handleMovementChange(String status) {
    setState(() {
      _status = status;
    });
    if (status == 'walking' && !_isWalking) {
      _startWalkingSession();
    } else if (status == 'stopped' && _isWalking) {
      _stopWalkingSession();
    }
  }

  void _startWalkingSession() {
    _isWalking = true;
    _walkingStartTime = DateTime.now();
    _currentWalkingSession++;
    _consecutiveSteps = 0;
    _walkingPace = 0.85 + (_random.nextDouble() * 0.3);
    _startStepCounting();
  }

  void _stopWalkingSession() {
    _isWalking = false;
    _walkingStartTime = null;
    _stepTimer?.cancel();
    _sessionTimer?.cancel();
    _stepTimer = null;
    _sessionTimer = null;
  }

  void _startStepCounting() {
    _stepTimer?.cancel();
    int baseInterval = (600 / _walkingPace).round();

    _stepTimer = Timer.periodic(Duration(milliseconds: baseInterval), (timer) {
      if (!_isWalking) {
        timer.cancel();
        return;
      }

      double stepChance = _calculateStepProbability();
      if (_random.nextDouble() < stepChance) {
        setState(() {
          _steps++;
          _todaySteps = _steps;
          _consecutiveSteps++;
          _calculateMetrics();
        });
        _saveSteps();
        _checkGoalAchievement();
      }

      if (_consecutiveSteps > 0 && _consecutiveSteps % 20 == 0) {
        double adjustment = 0.95 + (_random.nextDouble() * 0.1);
        _walkingPace = (_walkingPace * adjustment).clamp(0.7, 1.3);
        _startStepCounting();
      }
    });

    _startSessionPatterns();
  }

  void _checkGoalAchievement() {
    if (_steps >= _dailyGoal && !_goalAchievedShown) {
      _goalAchievedShown = true;
      _showGoalAchievedSheet();
    } else if (_steps < _dailyGoal) {
      _goalAchievedShown = false;
    }
  }

  void _showGoalAchievedSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => GoalAchievedBottomSheet(
          isDarkTheme: widget.isDarkTheme,
          isEnglish: widget.isEnglish,
          achievedSteps: _steps,
          dailyGoal: _dailyGoal,
        ),
      );
    });
  }

  double _calculateStepProbability() {
    double baseProbability = 0.92;

    if (_consecutiveSteps > 5) {
      baseProbability += 0.08;
    }

    double randomVariation = 0.95 + (_random.nextDouble() * 0.1);
    return (baseProbability * randomVariation).clamp(0.0, 1.0);
  }

  void _startSessionPatterns() {
    _sessionTimer = Timer.periodic(
      Duration(seconds: 10 + _random.nextInt(30)),
      (timer) {
        if (!_isWalking) {
          timer.cancel();
          return;
        }

        if (_random.nextDouble() < 0.2) {
          _stepTimer?.cancel();
          Timer(Duration(seconds: 1 + _random.nextInt(3)), () {
            if (_isWalking) {
              _startStepCounting();
            }
          });
        }
      },
    );
  }

  Future<void> _loadTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateKey();
    final lastDate = prefs.getString('last_date') ?? '';

    if (lastDate == today) {
      setState(() {
        _todaySteps = prefs.getInt('steps_$today') ?? 0;
        _steps = _todaySteps;
      });
    } else {
      setState(() {
        _todaySteps = 0;
        _steps = 0;
        _goalAchievedShown = false;
      });
      await prefs.setInt('steps_$today', _todaySteps);
      await prefs.setString('last_date', today);
    }
    _calculateMetrics();
  }

  Future<void> _loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyGoal = prefs.getInt('dailyGoal') ?? 1000;
    });
  }

  Future<void> _loadWeeklyData() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> weekData = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      final steps = prefs.getInt('steps_$dateStr') ?? 0;

      weekData.add({
        'date': date,
        'steps': steps,
        'day': DateFormat('E').format(date),
      });
    }

    setState(() {
      _weeklyData = weekData;
    });
  }

  void _calculateMetrics() {
    _calories = _steps * 0.04;
    _distance = (_steps * 0.762) / 100;
  }

  String _getDateKey() {
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateKey();

    await prefs.setInt('steps_$today', _steps);
    await prefs.setString('last_date', today);
    await prefs.setDouble('calories_$today', _calories);
    await prefs.setDouble('distance_$today', _distance);

    if (_walkingStartTime != null) {
      final walkedMinutes = DateTime.now()
          .difference(_walkingStartTime!)
          .inMinutes;
      final prevMinutes = prefs.getInt('minutes_$today') ?? 0;
      await prefs.setInt('minutes_$today', prevMinutes + walkedMinutes);
    }

    final updatedWeeklyData = List<Map<String, dynamic>>.from(_weeklyData);
    bool found = false;

    for (int i = 0; i < updatedWeeklyData.length; i++) {
      final data = updatedWeeklyData[i];
      if (DateFormat('dd-MM-yyyy').format(data['date']) == today) {
        updatedWeeklyData[i] = {
          'date': data['date'],
          'steps': _steps,
          'day': data['day'],
        };
        found = true;
        break;
      }
    }

    if (!found) {
      updatedWeeklyData.removeAt(0);
      updatedWeeklyData.add({
        'date': DateTime.now(),
        'steps': _steps,
        'day': DateFormat('E').format(DateTime.now()),
      });
    }

    setState(() {
      _weeklyData = updatedWeeklyData;
    });
  }

  void _resetSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateKey();

    setState(() {
      _steps = 0;
      _todaySteps = 0;
      _calories = 0;
      _distance = 0;
      _status = 'stopped';
      _isWalking = false;
      _goalAchievedShown = false;
    });

    await prefs.setInt('steps_$today', 0);
    await prefs.setString('last_date', today);
  }

  void _showDailyGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => DailyGoalDialog(
        isDarkTheme: widget.isDarkTheme,
        isEnglish: widget.isEnglish,
        currentGoal: _dailyGoal,
        onGoalChanged: (newGoal) {
          setState(() {
            _dailyGoal = newGoal;
            _goalAchievedShown = _steps >= newGoal;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dailyGoal != 0 ? _steps / _dailyGoal : 0.0;
    final bgColor = widget.isDarkTheme ? Color(0xFF12121F) : Colors.white;
    final txtColor = widget.isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEnglish ? 'Step Counter' : 'স্টেপস কাউন্টার',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: txtColor,
        actions: _isPermissionGranted
            ? [
                IconButton(onPressed: _resetSteps, icon: Icon(Icons.refresh)),
                IconButton(
                  onPressed: _showDailyGoalDialog,
                  icon: Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) => SettingScreenBottomSheet(
                        isDarkTheme: widget.isDarkTheme,
                        isEnglish: widget.isEnglish,
                        onThemeChanged: (newTheme) {
                          setState(() {
                            widget.onThemeChanged(newTheme);
                          });
                        },
                        onLanguageChanged: (newLang) {
                          setState(() {
                            widget.onLanguageChanged(newLang);
                          });
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.settings),
                ),
              ]
            : [],
      ),
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : !_isPermissionGranted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_walk, size: 100, color: Colors.blue),
                  SizedBox(height: 30),
                  Text(
                    widget.isEnglish
                        ? 'Permission not granted.'
                        : 'অনুমতি প্রদান করা হয়নি।',
                    style: TextStyle(fontSize: 24, color: Colors.red),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.isEnglish
                        ? 'Please grant permission to use the app.'
                        : 'অ্যাপটি ব্যবহার করতে অনুমতি দিন।',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkPermission,
                    child: Text(
                      widget.isEnglish ? 'Grant Permission' : 'অনুমতি দিন',
                      style: TextStyle(
                        color: widget.isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _buildStepBody(txtColor),
    );
  }

  Widget _buildStepBody(Color txtColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          StepProgressSection(
            status: _status,
            steps: _steps,
            dailyGoal: _dailyGoal,
            isWalking: _isWalking,
            isEnglish: widget.isEnglish,
          ),
          SizedBox(height: 30),
          StatsRow(
            calories: _calories,
            distance: _distance,
            steps: _steps,
            isEnglish: widget.isEnglish,
            isDarkTheme: widget.isDarkTheme,
          ),
          SizedBox(height: 30),
          WeeklyStepsChart(
            weeklyData: _weeklyData,
            dailyGoal: _dailyGoal,
            isDarkTheme: widget.isDarkTheme,
            isEnglish: widget.isEnglish,
          ),
          SizedBox(height: 30),
          WeeklyStatsCards(
            weeklyData: _weeklyData,
            isDarkTheme: widget.isDarkTheme,
            isEnglish: widget.isEnglish,
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
