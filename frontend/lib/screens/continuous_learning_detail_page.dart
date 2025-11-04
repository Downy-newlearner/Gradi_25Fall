import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/app_header_menu_button.dart';
import '../widgets/back_button.dart';

/// 연속학습 상세 페이지
///
/// Figma 디자인 기반 캘린더 뷰
class ContinuousLearningDetailPage extends StatefulWidget {
  const ContinuousLearningDetailPage({super.key});

  @override
  State<ContinuousLearningDetailPage> createState() =>
      _ContinuousLearningDetailPageState();
}

class _ContinuousLearningDetailPageState
    extends State<ContinuousLearningDetailPage> {
  int _currentMonth = 7; // 7월
  int _currentYear = 2025;

  // TODO: DB에서 학습 데이터 조회
  // 임시 데이터: 학습 완료한 날짜들 (7월 기준)
  final Set<int> _completedDates = {6, 7, 13, 14, 15, 20, 21, 22, 23};

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.03),
                    _buildCalendarSection(),
                    SizedBox(height: screenHeight * 0.033),
                    _buildStatisticsSection(),
                    SizedBox(height: screenHeight * 0.016),
                    _buildAccumulatedLearningSection(),
                    SizedBox(height: screenHeight * 0.02),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return AppHeader(
      title: Row(
        children: [
          CustomBackButton(),
          SizedBox(width: screenWidth * 0.025),
          const Text(
            '연속학습',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF585B69),
            ),
          ),
        ],
      ),
      trailing: const AppHeaderMenuButton(),
    );
  }

  Widget _buildCalendarSection() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        screenHeight * 0.029,
        8,
        screenHeight * 0.018,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE1E7ED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // 월/년 표시와 이전/다음 달 버튼
          _buildCalendarHeader(),
          SizedBox(height: screenHeight * 0.018),
          // 요일 표시
          _buildWeekDays(),
          SizedBox(height: screenHeight * 0.037),
          // 날짜 그리드 (7열 x 5행)
          _buildDateGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 이전 달 버튼
        IconButton(
          icon: Icon(Icons.chevron_left, size: screenWidth * 0.037),
          onPressed: () {
            setState(() {
              if (_currentMonth > 1) {
                _currentMonth--;
              } else {
                _currentMonth = 12;
                _currentYear--;
              }
            });
          },
        ),
        const SizedBox(width: 32),
        // 월/년 표시
        Column(
          children: [
            Text(
              '$_currentMonth월',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 22,
                color: Color(0xFF000000),
                height: 1.0,
              ),
            ),
            Text(
              '$_currentYear',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF000000),
                height: 1.23,
              ),
            ),
          ],
        ),
        const SizedBox(width: 32),
        // 다음 달 버튼
        IconButton(
          icon: Icon(Icons.chevron_right, size: screenWidth * 0.037),
          onPressed: () {
            setState(() {
              if (_currentMonth < 12) {
                _currentMonth++;
              } else {
                _currentMonth = 1;
                _currentYear++;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        return SizedBox(
          width: MediaQuery.of(context).size.width / 15,
          child: Text(
            day,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF707070),
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateGrid() {
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final lastDayOfMonth = DateTime(_currentYear, _currentMonth + 1, 0);

    // 첫 번째 날의 요일 (월요일 = 1, 일요일 = 7)
    final firstWeekday = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;

    // 7열 (월~일) x 5행
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (colIndex) {
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (rowIndex) {
              final day = colIndex + (rowIndex * 7) - firstWeekday + 1;

              // 이전/다음 달의 날짜 또는 범위를 벗어난 날짜
              if (day <= 0 || day > lastDayOfMonth.day) {
                // 이전 달의 마지막 날짜들 표시
                if (day <= 0) {
                  final prevMonth = _currentMonth == 1 ? 12 : _currentMonth - 1;
                  final prevYear = _currentMonth == 1
                      ? _currentYear - 1
                      : _currentYear;
                  final daysInPrevMonth = DateTime(
                    prevYear,
                    prevMonth + 1,
                    0,
                  ).day;
                  final dayInPrevMonth = daysInPrevMonth + day;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      '$dayInPrevMonth',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF707070),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                // 다음 달의 날짜 표시
                else {
                  final dayInNextMonth = day - lastDayOfMonth.day;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      '$dayInNextMonth',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF707070),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              }

              // 현재 달의 날짜
              final isCompleted = _completedDates.contains(day);

              return Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 날짜 박스
                    Container(
                      width: 41,
                      height: 43,
                      decoration: isCompleted
                          ? BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            )
                          : BoxDecoration(
                              color: const Color(0xFFE1E7ED),
                              borderRadius: BorderRadius.circular(10),
                            ),
                    ),
                    // 날짜 텍스트
                    Text(
                      '$day',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF000000),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildStatisticsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.087,
        screenHeight * 0.011,
        screenWidth * 0.087,
        screenHeight * 0.011,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE1E7ED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '303일동안 1435문제를 풀었어요.',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          height: 1.2,
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(const Rect.fromLTWH(0, 0, 1000, 70)),
        ),
      ),
    );
  }

  Widget _buildAccumulatedLearningSection() {
    // TODO: DB에서 누적 학습량 데이터 조회
    final learningData = [
      {'name': '블랙라벨 중등수학 1-1', 'progress': 100},
      {'name': '라이트쎈 중등수학 1-1', 'progress': 46},
      {'name': '100발 100중 중등수학 2-2', 'progress': 23},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: learningData.map((data) {
        return _buildLearningItem(
          name: data['name'] as String,
          progress: data['progress'] as int,
        );
      }).toList(),
    );
  }

  Widget _buildLearningItem({required String name, required int progress}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.016),
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.047,
        screenHeight * 0.017,
        screenWidth * 0.047,
        screenHeight * 0.024,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE1E7ED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF585B69),
            ),
          ),
          SizedBox(height: screenHeight * 0.011),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: progress / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
