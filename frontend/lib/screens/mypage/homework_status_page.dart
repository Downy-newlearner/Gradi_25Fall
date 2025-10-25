import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';

/// 숙제 현황 페이지
/// 할당된 숙제 목록과 제출 현황을 보여주는 페이지
class HomeworkStatusPage extends StatefulWidget {
  const HomeworkStatusPage({super.key});

  @override
  State<HomeworkStatusPage> createState() => _HomeworkStatusPageState();
}

class _HomeworkStatusPageState extends State<HomeworkStatusPage> {
  // TODO: 서버에서 숙제 데이터 가져오기
  final List<HomeworkItem> _homeworks = [
    HomeworkItem(
      title: '블랙라벨 중등수학 1-1 - 1단원',
      dueDate: DateTime(2025, 10, 28),
      isCompleted: false,
      assignedBy: '오세종 선생님',
    ),
    HomeworkItem(
      title: '라이트쎈 중등수학 1-1 - 2단원',
      dueDate: DateTime(2025, 10, 26),
      isCompleted: true,
      assignedBy: '오세종 선생님',
    ),
    HomeworkItem(
      title: '수능완성 영어 2026 - 독해 1~10',
      dueDate: DateTime(2025, 10, 30),
      isCompleted: false,
      assignedBy: '최상일 선생님',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pendingHomeworks =
        _homeworks.where((h) => !h.isCompleted).toList();
    final completedHomeworks =
        _homeworks.where((h) => h.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // 요약 카드
                    _buildSummaryCard(pendingHomeworks.length),

                    const SizedBox(height: 24),

                    // 미완료 숙제
                    if (pendingHomeworks.isNotEmpty) ...[
                      const Text(
                        '미완료 숙제',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...pendingHomeworks.map((hw) => _buildHomeworkCard(hw)),
                      const SizedBox(height: 24),
                    ],

                    // 완료된 숙제
                    if (completedHomeworks.isNotEmpty) ...[
                      const Text(
                        '완료된 숙제',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...completedHomeworks.map((hw) => _buildHomeworkCard(hw)),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: const [
          CustomBackButton(),
          SizedBox(width: 20),
          Text(
            '숙제 현황',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, size: 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '미완료 숙제',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pendingCount개',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(HomeworkItem homework) {
    final daysLeft = homework.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final isDueSoon = daysLeft >= 0 && daysLeft <= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: homework.isCompleted
            ? const Color(0xFFF8F9FA)
            : Colors.white,
        border: Border.all(
          color: homework.isCompleted
              ? const Color(0xFFE9ECEF)
              : (isOverdue
                  ? const Color(0xFFF44336)
                  : (isDueSoon
                      ? const Color(0xFFFF9800)
                      : const Color(0xFFE9ECEF))),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  homework.title,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: homework.isCompleted
                        ? const Color(0xFF999999)
                        : const Color(0xFF333333),
                    decoration: homework.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              if (homework.isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            homework.assignedBy,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: isOverdue
                    ? const Color(0xFFF44336)
                    : const Color(0xFF999999),
              ),
              const SizedBox(width: 4),
              Text(
                '마감: ${_formatDate(homework.dueDate)}',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: isOverdue
                      ? const Color(0xFFF44336)
                      : const Color(0xFF999999),
                ),
              ),
              if (!homework.isCompleted && isDueSoon) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '곧 마감',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class HomeworkItem {
  final String title;
  final DateTime dueDate;
  final bool isCompleted;
  final String assignedBy;

  HomeworkItem({
    required this.title,
    required this.dueDate,
    required this.isCompleted,
    required this.assignedBy,
  });
}

