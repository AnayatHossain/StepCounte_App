import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_counter/app/widgets/buildStatCard.dart';
import 'package:step_counter/app/widgets/setting_screen_bottom_sheet.dart';
import 'package:step_counter/app/widgets/successful_bottom_sheet.dart';

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

    // Update weekly data for today
    final todayData = _weeklyData.firstWhere(
      (data) => DateFormat('dd-MM-yyyy').format(data['date']) == today,
      orElse: () => {
        'date': DateTime.now(),
        'steps': _steps,
        'day': DateFormat('E').format(DateTime.now()),
      },
    );

    todayData['steps'] = _steps;

    setState(() {
      _weeklyData = _weeklyData.map((data) {
        if (DateFormat('dd-MM-yyyy').format(data['date']) == today) {
          return {'date': data['date'], 'steps': _steps, 'day': data['day']};
        }
        return data;
      }).toList();
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

    // Update weekly data for today only
    setState(() {
      _weeklyData = _weeklyData.map((data) {
        if (DateFormat('dd-MM-yyyy').format(data['date']) == today) {
          return {'date': data['date'], 'steps': 0, 'day': data['day']};
        }
        return data;
      }).toList();
    });
  }

  void _showDailyGoalDialog() {
    final controller = TextEditingController(text: '$_dailyGoal');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkTheme ? Colors.grey[900] : Colors.white,
        title: Text(
          widget.isEnglish ? 'Set Daily Goal' : 'দৈনিক লক্ষ্য নির্ধারণ করুন',
          style: TextStyle(
            color: widget.isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: widget.isDarkTheme ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: widget.isEnglish ? 'Steps Goal' : 'পদক্ষেপের লক্ষ্য',
            labelStyle: TextStyle(
              color: widget.isDarkTheme ? Colors.white70 : Colors.grey[800],
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: widget.isDarkTheme ? Colors.white54 : Colors.grey,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              widget.isEnglish ? 'Cancel' : 'বাতিল',
              style: TextStyle(
                color: widget.isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.isEnglish ? 'Save' : 'সংরক্ষণ করুন'),
            onPressed: () async {
              final newGoal = int.tryParse(controller.text) ?? _dailyGoal;
              setState(() {
                _dailyGoal = newGoal;
                _goalAchievedShown = _steps >= newGoal;
              });

              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('dailyGoal', newGoal);

              Navigator.pop(context);
            },
          ),
        ],
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
                        onThemeChanged: widget.onThemeChanged,
                        onLanguageChanged: widget.onLanguageChanged,
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
    final progress = _dailyGoal != 0 ? _steps / _dailyGoal : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Circular Progress & Status
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Column(
                      children: [
                        Icon(
                          _status == 'walking'
                              ? Icons.directions_walk
                              : Icons.accessibility_new,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$_steps',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.isEnglish
                              ? 'of $_dailyGoal Steps'
                              : '$_dailyGoal স্টেপসের মধ্যে',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isWalking
                        ? Colors.green
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isWalking ? Icons.directions_walk : Icons.stop,
                        color: _isWalking
                            ? Colors.green[700]
                            : Colors.redAccent,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        _isWalking
                            ? (widget.isEnglish ? 'Walking' : 'চলছেন')
                            : (widget.isEnglish ? 'Stopped' : 'বন্ধ'),
                        style: TextStyle(
                          fontSize: 20,
                          color: _isWalking ? Colors.green[700] : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildStatCard(
                icon: Icons.local_fire_department,
                value: _calories.toStringAsFixed(2),
                unit: widget.isEnglish ? 'Calories' : 'ক্যালোরি',
                isDarkTheme: widget.isDarkTheme,
                isEnglish: widget.isEnglish,
                color: Colors.orange,
              ),
              buildStatCard(
                icon: Icons.straighten,
                value: _distance.toStringAsFixed(2),
                unit: widget.isEnglish ? 'Kilometers' : 'কি.মি',
                isDarkTheme: widget.isDarkTheme,
                isEnglish: widget.isEnglish,
                color: Colors.purple,
              ),
              buildStatCard(
                icon: Icons.timer,
                value: (_steps * 0.008).toStringAsFixed(0),
                unit: widget.isEnglish ? 'Minutes' : 'মিনিট',
                isDarkTheme: widget.isDarkTheme,
                isEnglish: widget.isEnglish,
                color: Colors.teal,
              ),
            ],
          ),

          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDarkTheme ? Color(0xFF3E3B3B) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEnglish ? 'Weekly Steps' : 'সাপ্তাহিক স্টেপস',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkTheme ? Colors.white : Colors.blue,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weeklyData.map((data) {
                    final height = (data['steps'] / _dailyGoal * 100).clamp(
                      10.0,
                      100.0,
                    );
                    final isToday =
                        DateFormat('dd-MM-yyyy').format(data['date']) ==
                        DateFormat('dd-MM-yyyy').format(DateTime.now());

                    return Column(
                      children: [
                        Container(
                          width: 35,
                          height: height.toDouble(),
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? LinearGradient(
                                    colors: [
                                      Colors.blue[400]!,
                                      Colors.blue[600]!,
                                    ],
                                  )
                                : null,
                            color: !isToday ? Colors.grey[300] : null,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '${data['day']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkTheme
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
