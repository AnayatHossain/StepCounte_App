import 'package:flutter/material.dart';
import 'package:step_counter/app/widgets/walking_status_chip.dart';

class StepProgressSection extends StatelessWidget {
  final String status;
  final int steps;
  final int dailyGoal;
  final bool isWalking;
  final bool isEnglish;

  const StepProgressSection({
    super.key,
    required this.status,
    required this.steps,
    required this.dailyGoal,
    required this.isWalking,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    final progress = dailyGoal != 0 ? steps / dailyGoal : 0.0;

    return Container(
      padding: const EdgeInsets.all(30),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Icon(
                    status == 'walking'
                        ? Icons.directions_walk
                        : Icons.accessibility_new,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$steps',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isEnglish
                        ? 'of $dailyGoal Steps'
                        : '$dailyGoal স্টেপসের মধ্যে',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          WalkingStatusChip(isWalking: isWalking, isEnglish: isEnglish),
        ],
      ),
    );
  }
}
