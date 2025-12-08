import 'package:flutter/material.dart';

class ContinuousLearningWidget extends StatelessWidget {
  final int consecutiveDays;
  final List<bool> weeklyProgress;

  const ContinuousLearningWidget({
    super.key,
    required this.consecutiveDays,
    required this.weeklyProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$consecutiveDays일 연속으로 학습하고 있어요',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF333333),
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border.all(color: const Color(0xFFE9ECEF)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDayCard('월', weeklyProgress[0]),
              _buildDayCard('화', weeklyProgress[1]),
              _buildDayCard('수', weeklyProgress[2]),
              _buildDayCard('목', weeklyProgress[3]),
              _buildDayCard('금', weeklyProgress[4]),
              _buildDayCard('토', weeklyProgress[5]),
              _buildDayCard('일', weeklyProgress[6]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(String day, bool isActive) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 34,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFAC5BF8).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: isActive ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
