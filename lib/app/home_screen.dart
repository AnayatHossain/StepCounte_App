import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  Timer? _stepTimer;
  Timer? _sessionTimer;

  String _status = 'stopped';
  int _steps = 100;
  int _todaySteps = 0;
  bool _isWaliking = false;
  bool _isIntialized = false;
  bool _isPermissionGranted = false;
  bool _isLoading = false;

  Random _random = Random();
  DateTime? _walkingStartTime;
  int _currentWalkingSession = 0;
  double _walkingPace = 1.0;
  int _consecutiveSteps = 0;

  double _calories = 0.0;
  double _distance = 0.0;
  int _dailyGoal = 1000;

  List<Map<String, dynamic>> _weeklyDate = [];

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
    await _loadDailyDate();
    await _loadTodaySteps();
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
    if (status == 'walking' && !_isWaliking) {
      _startWalkingSession();
    } else if (status == 'stopped' && _isWaliking) {
      _stopWalkingSession();
    }
  }

  void _startWalkingSession() {
    _isWaliking = true;
    _walkingStartTime = DateTime.now();
    _currentWalkingSession++;
    _consecutiveSteps = 0;
    _walkingPace = 0.85 + (_random.nextDouble() * 0.3);
    _startStepCounting();
  }

  void _stopWalkingSession() {
    _isWaliking = false;
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
      if (!_isWaliking) {
        timer.cancel();
        return;
      }

      double stepChance = _calculateStepProbability();
      if (_random.nextDouble() < stepChance) {
        setState(() {
          _steps++;
          _consecutiveSteps++;
          _calculateMetrics();
        });
        _saveSteps();
      }

      if (_consecutiveSteps > 0 && _consecutiveSteps % 20 == 0) {
        double adjustment = 0.95 + (_random.nextDouble() * 0.1);
        _walkingPace = (_walkingPace * adjustment).clamp(0.7, 1.3);
        _startStepCounting();
      }
    });

    _startSessionPatterns();
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
        if (!_isWaliking) {
          timer.cancel();
          return;
        }

        if (_random.nextDouble() < 0.2) {
          _stepTimer?.cancel();
          Timer(Duration(seconds: 1 + _random.nextInt(3)), () {
            if (_isWaliking) {
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
      });
      await prefs.setInt('steps_$today', _todaySteps);
      await prefs.setString('lastDate', today);
    }
    _calculateMetrics();
  }

  Future<void> _loadDailyDate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyGoal = prefs.getInt('dailyGoal') ?? 1000;
    });
    _loadWeeklyDate();
  }

  Future<void> _loadWeeklyDate() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> weekDate = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      final steps = prefs.getInt('steps_$dateStr') ?? 0;

      weekDate.add({
        'date': date,
        'steps': steps,
        'day': DateFormat('E').format(date),
      });
    }
    setState(() {
      _weeklyDate = weekDate;
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
    await prefs.setString('lastDate', today);
  }

  void _showDailyGoalDialog() {
    final controller = TextEditingController(text: _dailyGoal.toString());

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set Daily Goal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    labelText: 'Daily Steps Goal',
                    hintText: 'Enter your daily goal',
                    labelStyle: TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF4facfe),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final newGoal = int.tryParse(controller.text) ?? 1000;
                        setState(() {
                          _dailyGoal = newGoal;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('dailyGoal', newGoal);
                        Navigator.pop(context);
                      },
                      child: Text('Set Goal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dailyGoal != 0 ? _steps / _dailyGoal : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Step Counter'),
        elevation: 0,
        actions: _isPermissionGranted
            ? [
                IconButton(
                  onPressed: _showDailyGoalDialog,
                  icon: Icon(Icons.settings),
                ),
              ]
            : [],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : !_isPermissionGranted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_walk, size: 100, color: Colors.red),
                  SizedBox(height: 30),
                  Text(
                    'Permission not granted.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please grant permission to use the app.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Grant Permission'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  '${_steps ?? 0}',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'of ${_dailyGoal ?? 0} Steps',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isWaliking
                                ? Colors.green
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: _isWaliking
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isWaliking
                                    ? Icons.directions_walk
                                    : Icons.stop,
                                color: _isWaliking
                                    ? Colors.green[700]
                                    : Colors.redAccent,
                                size: 30,
                              ),
                              SizedBox(width: 10),
                              Text(
                                _isWaliking ? 'Walking' : 'Stopped',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: _isWaliking
                                      ? Colors.green[700]
                                      : Colors.white,
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
                      _buildStatCard(
                        icon: Icons.local_fire_department,
                        value: _calories.toStringAsFixed(2),
                        unit: 'cal',
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        icon: Icons.straighten,
                        value: _distance.toStringAsFixed(2),
                        unit: 'km',
                        color: Colors.purple,
                      ),
                      _buildStatCard(
                        icon: Icons.timer,
                        value: (_steps * 0.008).toStringAsFixed(0),
                        unit: 'min',
                        color: Colors.teal,
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                          'Weekly Steps',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _weeklyDate.map((data) {
                            final height = (data['steps'] / _dailyGoal * 100)
                                .clamp(10.0, 100.0);
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
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(unit, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
