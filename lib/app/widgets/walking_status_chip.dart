import 'package:flutter/material.dart';

class WalkingStatusChip extends StatelessWidget {
  final bool isWalking;
  final bool isEnglish;

  const WalkingStatusChip({
    super.key,
    required this.isWalking,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isWalking ? Colors.green : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWalking ? Icons.directions_walk : Icons.stop,
            color: isWalking ? Colors.green[700] : Colors.redAccent,
            size: 30,
          ),
          const SizedBox(width: 10),
          Text(
            isWalking
                ? (isEnglish ? 'Walking' : 'চলছেন')
                : (isEnglish ? 'Stopped' : 'বন্ধ'),
            style: TextStyle(
              fontSize: 20,
              color: isWalking ? Colors.green[700] : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
