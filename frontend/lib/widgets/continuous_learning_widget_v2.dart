import 'package:flutter/material.dart';
import '../models/assessment.dart';

/// 연속학습 위젯 V2 - 개선된 UI/UX
///
/// 주요 기능:
/// 1. 월별 날짜 스크롤 (한 달 단위)
/// 2. 선택된 날짜 표시
/// 3. 학습 완료 상태 표시 (그라데이션 박스)
/// 4. 숙제 마감일 표시 (책 아이콘)
/// 5. 연속 학습일 연결선 표시
class ContinuousLearningWidgetV2 extends StatefulWidget {
  final int consecutiveDays;
  final Set<String> completedDates;
  final Set<String> homeworkDeadlines;
  final Map<String, List<Assessment>>? dateAssessments; // Assessment 데이터
  final Function(DateTime)? onDateSelected;
  final DateTime? selectedDate;

  const ContinuousLearningWidgetV2({
    super.key,
    required this.consecutiveDays,
    this.completedDates = const {},
    this.homeworkDeadlines = const {},
    this.dateAssessments,
    this.onDateSelected,
    this.selectedDate,
  });

  @override
  State<ContinuousLearningWidgetV2> createState() =>
      _ContinuousLearningWidgetV2State();
}

class _ContinuousLearningWidgetV2State
    extends State<ContinuousLearningWidgetV2> {
  late DateTime _selectedDate;
  final ScrollController _dateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();

    // 오늘 날짜가 오른쪽 끝에 오도록 스크롤 위치 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(_selectedDate, jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant ContinuousLearningWidgetV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSelected = widget.selectedDate ?? DateTime.now();
    if (!_isSameDay(newSelected, _selectedDate)) {
      setState(() {
        _selectedDate = newSelected;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToDate(newSelected);
      });
    }
  }
  void _scrollToDate(DateTime date, {bool jump = false}) {
    final itemWidth = MediaQuery.of(context).size.width / 8;
    final targetIndex = date.day - 4; // 중앙 근처에 오도록 약간 여유
    final offset = targetIndex <= 0 ? 0.0 : itemWidth * targetIndex;
    if (jump) {
      _dateScrollController.jumpTo(offset);
    } else {
      _dateScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 연속 학습 일수 표시 + 상세 페이지 이동 버튼
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/continuous-learning-detail');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.consecutiveDays}일',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFFAC5BF8),
                      ),
                    ),
                    const TextSpan(
                      text: ' 연속으로 학습하고 있어요',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: MediaQuery.of(context).size.width * 0.06,
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.0092), // 8px → 0.92%
        // 날짜 스크롤 영역 (ListView 가로 스크롤) - 한 달 단위
        SizedBox(
          height: screenHeight * 0.08, // 높이 더 증가로 overflow 방지
          child: ListView.builder(
            controller: _dateScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemExtent: MediaQuery.of(context).size.width / 8, // 카드 너비
            itemBuilder: (context, index) {
              // 현재 월의 1일부터 시작
              final today = DateTime.now();
              final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

              // 인덱스가 현재 월의 일수를 벗어나면 null 반환
              if (index >= daysInMonth) return null;

              final date = DateTime(today.year, today.month, index + 1);

              final isSelected = _isSameDay(date, _selectedDate);
              final isCompleted = _isDateCompleted(date);
              final hasHomework = _hasHomeworkDeadline(date);

              // 다음 날짜의 완료 여부 확인 (연결선 표시용)
              final nextDate = date.add(const Duration(days: 1));
              final isNextCompleted = _isDateCompleted(nextDate);
              // 다음 날이 현재 월에 속할 때만 연결선 표시
              final showConnector =
                  isCompleted &&
                  isNextCompleted &&
                  nextDate.month == date.month;

              return _buildDateItem(
                date: date,
                isSelected: isSelected,
                isCompleted: isCompleted,
                hasHomework: hasHomework,
                showConnector: showConnector,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 날짜 아이템 UI
  Widget _buildDateItem({
    required DateTime date,
    required bool isSelected,
    required bool isCompleted,
    required bool hasHomework,
    required bool showConnector,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth / 8; // 화면 너비의 1/8

    // 박스 배경 (학습 완료 여부에 따라)
    final boxDecoration = isCompleted
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFAC5BF8),
                Color(0xFF636ACF),
              ], // Gradi 시그니처 그라데이션
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFAC5BF8).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(8),
          );

    // 날짜 텍스트 색상
    final dateColor = isSelected ? Colors.white : const Color(0xFF666666);

    // 책 아이콘 색상
    final bookIconColor = isCompleted ? Colors.white : const Color(0xFF7C3AED);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        if (widget.onDateSelected != null) {
          widget.onDateSelected!(date);
        }
      },
      child: SizedBox(
        width: cardWidth,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 날짜 (월/일) - 선택된 날은 그라데이션 배경
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFAC5BF8).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      )
                    : BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                child: Text(
                  '${date.month}/${date.day}',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: dateColor,
                    height: 1.1, // 줄 간격 줄임
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // 박스와 연결선을 Stack으로 구성
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // 박스 (책 아이콘 또는 체크 아이콘 또는 둘 다 또는 빈 공간) - 1:1 비율 강제
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: boxDecoration,
                      child: _buildBoxContent(
                        hasHomework: hasHomework,
                        isCompleted: isCompleted,
                        bookIconColor: bookIconColor,
                        cardHeight: cardWidth,
                      ),
                    ),
                  ),
                  // 연결선 (다음 날짜와 연결)
                  if (showConnector)
                    Positioned(
                      right: -(screenWidth * 0.01 * 2),
                      top: (cardWidth - 4) / 2,
                      child: Container(
                        width: screenWidth * 0.01 * 2,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFAC5BF8),
                              Color(0xFF636ACF),
                            ], // Gradi 시그니처 그라데이션
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 박스 내부 콘텐츠 (책 아이콘, 체크 아이콘, 둘 다, 또는 빈 공간)
  Widget? _buildBoxContent({
    required bool hasHomework,
    required bool isCompleted,
    required Color bookIconColor,
    required double cardHeight,
  }) {
    // 둘 다 있는 경우: 책 아이콘과 체크 아이콘을 함께 표시
    if (hasHomework && isCompleted) {
      return Stack(
        children: [
          // 책 아이콘 (중앙)
          Center(
            child: Icon(
              Icons.menu_book,
              color: bookIconColor,
              size: cardHeight * 0.4,
            ),
          ),
          // 체크 아이콘 (오른쪽 상단)
          Positioned(
            top: cardHeight * 0.1,
            right: cardHeight * 0.1,
            child: Icon(
              Icons.check_circle,
              color: Colors.white,
              size: cardHeight * 0.25,
            ),
          ),
        ],
      );
    }
    // 책 아이콘만
    else if (hasHomework) {
      return Center(
        child: Icon(
          Icons.menu_book,
          color: bookIconColor,
          size: cardHeight * 0.5,
        ),
      );
    }
    // 체크 아이콘만 (학습 완료)
    else if (isCompleted) {
      return Center(
        child: Icon(Icons.check, color: Colors.white, size: cardHeight * 0.5),
      );
    }
    // 둘 다 없음
    return null;
  }

  // 헬퍼 메서드들

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isDateCompleted(DateTime date) {
    final dateStr = _formatDate(date);

    // Assessment 데이터가 있으면 그것을 우선 사용
    if (widget.dateAssessments != null) {
      final assessments = widget.dateAssessments![dateStr] ?? [];
      return assessments.any((a) => a.assessStatus == 'Y');
    }

    // 없으면 기존 completedDates 사용 (하위 호환성)
    return widget.completedDates.contains(dateStr);
  }

  bool _hasHomeworkDeadline(DateTime date) {
    final dateStr = _formatDate(date);

    // Assessment 데이터가 있으면 그것을 우선 사용
    if (widget.dateAssessments != null) {
      final assessments = widget.dateAssessments![dateStr] ?? [];
      return assessments.isNotEmpty;
    }

    // 없으면 기존 homeworkDeadlines 사용 (하위 호환성)
    return widget.homeworkDeadlines.contains(dateStr);
  }

  /// 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
