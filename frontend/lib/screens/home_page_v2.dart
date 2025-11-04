import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/app_header_menu_button.dart';
import '../widgets/continuous_learning_widget_v2.dart';

/// 홈 화면 V2 - 개선된 UI/UX
///
/// 주요 기능:
/// 1. 연속학습 위젯 - 날짜 기반 스와이프 캘린더
/// 2. 오늘의 숙제 - 문제집 표지 + 상세 정보 카드
/// 3. 누적 학습량 - 2단계 프로그레스 바
class HomePageV2 extends StatefulWidget {
  const HomePageV2({super.key});

  @override
  State<HomePageV2> createState() => _HomePageV2State();
}

class _HomePageV2State extends State<HomePageV2> {
  // 임시 데이터: 학습 완료한 날짜들
  final Set<String> _completedDates = {
    '2025-10-22',
    '2025-10-23',
    '2025-10-24',
    '2025-10-25',
    '2025-10-26',
    '2025-10-27',
  };

  // 임시 데이터: 숙제 마감일
  final Set<String> _homeworkDeadlines = {
    '2025-10-22',
    '2025-10-25',
    '2025-10-26',
  };

  // 숙제 완료 상태 관리
  final Map<String, bool> _homeworkStatus = {
    '0-0': false, // 오세종 선생님 3반 - 첫 번째
    '0-1': false, // 오세종 선생님 3반 - 두 번째
    '1-0': true, // 조성제 선생님 3반 - 첫 번째
  };

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
                    SizedBox(height: screenHeight * 0.0297), // 26px → 2.97%
                    ContinuousLearningWidgetV2(
                      consecutiveDays: _getConsecutiveDays(),
                      completedDates: _completedDates,
                      homeworkDeadlines: _homeworkDeadlines,
                      onDateSelected: (date) {
                        setState(() {
                          // 선택된 날짜의 데이터 로드
                          // TODO: 구현
                        });
                      },
                    ),
                    SizedBox(height: screenHeight * 0.0297), // 26px → 2.97%
                    _buildTodayHomeworkSection(),
                    SizedBox(height: screenHeight * 0.0297), // 26px → 2.97%
                    _buildAccumulatedLearningSection(),
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
    // ✅ Rule 1: 아이콘 사이즈도 상대 크기로
    final iconSize = MediaQuery.of(context).size.width * 0.06;

    return AppHeader(
      title: Row(
        children: [
          const Text(
            '정다훈 학원', // TODO: DB에서 학원명 조회
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF333333),
            ),
          ), // ✅ Rule 5: trailing comma
          const SizedBox(width: 8), // ✅ Rule 1: spacing은 OK
          Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF333333),
            size: iconSize, // ✅ Rule 1: 상대 크기
          ), // ✅ Rule 5: trailing comma
          const Spacer(), // 왼쪽 정렬을 위해 오른쪽을 밀기
        ],
      ), // ✅ Rule 5: trailing comma
      trailing: const AppHeaderMenuButton(),
    );
  }

  /// 오늘의 숙제 섹션
  Widget _buildTodayHomeworkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '오늘의 숙제',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: MediaQuery.of(context).size.width * 0.06,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // TODO: DB에서 선택된 날짜의 숙제 목록 조회
        _buildHomeworkList(),
      ],
    );
  }

  Widget _buildHomeworkList() {
    // 임시 데이터: 클래스(반) 단위로 그룹화
    final homeworksByClass = [
      {
        'className': '오세종 선생님 3반',
        'workbooks': [
          {
            'chapter': '챕터1: 도형의 이동',
            'pages': 'P.15~P.25',
            'thumbnail': 'assets/images/bookcovers/workbook_2024.jpg',
            'isCompleted': false,
          },
          {
            'chapter': '챕터1: 도형의 이동',
            'pages': 'P.15~P.25',
            'thumbnail': 'assets/images/bookcovers/workbook_2025.jpg',
            'isCompleted': false,
          },
        ],
      },
      {
        'className': '조성제 선생님 3반',
        'workbooks': [
          {
            'chapter': '챕터1: 도형의 이동',
            'pages': 'P.15~P.25',
            'thumbnail': 'assets/images/bookcovers/workbook_2024.jpg',
            'isCompleted': true,
          },
        ],
      },
    ];

    return Column(
      children: homeworksByClass.asMap().entries.map((entry) {
        final classIndex = entry.key;
        final classData = entry.value;
        return _buildHomeworkClassCard(classData, classIndex);
      }).toList(),
    );
  }

  /// 클래스(반) 단위 숙제 카드
  Widget _buildHomeworkClassCard(
    Map<String, dynamic> classData,
    int classIndex,
  ) {
    final className = classData['className'] as String;
    final workbooks = classData['workbooks'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE1E7ED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 클래스(반) 이름
          Text(
            className,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 10),

          // 문제집 목록
          ...workbooks.asMap().entries.map((entry) {
            final workbookIndex = entry.key;
            final workbook = entry.value;
            final statusKey = '$classIndex-$workbookIndex';
            final isCompleted = _homeworkStatus[statusKey] ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildWorkbookItem(
                workbook,
                classIndex,
                workbookIndex,
                isCompleted,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 문제집 아이템 (챕터 + 페이지만 표시)
  Widget _buildWorkbookItem(
    Map<String, dynamic> workbook,
    int classIndex,
    int workbookIndex,
    bool isCompleted,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = screenWidth * 0.12;
    final thumbnailHeight = thumbnailWidth * 1.34;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 문제집 썸네일
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.asset(
            workbook['thumbnail'] as String,
            width: thumbnailWidth,
            height: thumbnailHeight,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: thumbnailWidth,
                height: thumbnailHeight,
                color: Colors.grey[300],
                child: const Icon(Icons.book, color: Colors.grey),
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // 챕터 + 페이지 정보 (문제집명 제거)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                workbook['chapter'] as String,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                workbook['pages'] as String,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),

        // 체크박스
        GestureDetector(
          onTap: () {
            setState(() {
              final statusKey = '$classIndex-$workbookIndex';
              _homeworkStatus[statusKey] = !_homeworkStatus[statusKey]!;
            });
            // TODO: 서버 동기화
          },
          child: Container(
            width: screenWidth * 0.06,
            height: screenWidth * 0.06,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFAC5BF8) : Colors.white,
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFFAC5BF8)
                    : const Color(0xFFCED4DA),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: screenWidth * 0.04,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  /// 누적 학습량 섹션
  Widget _buildAccumulatedLearningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '누적 학습량',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: MediaQuery.of(context).size.width * 0.06,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // TODO: DB에서 선택된 날짜에 학습한 문제집 목록 조회
        _buildLearningProgressCard(),
      ],
    );
  }

  Widget _buildLearningProgressCard() {
    // 임시 데이터
    const workbookName = '블랙라벨 중등수학 1-1';
    const chapterName = '챕터1: 도형의 이동';
    const currentPage = 148;
    const totalPages = 300;
    const todayPages = 25; // 오늘 푼 페이지 수
    const correctRate = 80;

    final previousProgress = (currentPage - todayPages) / totalPages;
    final currentProgress = currentPage / totalPages;

    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = screenWidth * 0.17;
    final thumbnailHeight = thumbnailWidth * 1.33;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE1E7ED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문제집 썸네일
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              'assets/images/bookcovers/workbook_2024.jpg',
              width: thumbnailWidth,
              height: thumbnailHeight,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: thumbnailWidth,
                  height: thumbnailHeight,
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.book,
                    color: Colors.grey,
                    size: thumbnailWidth * 0.57,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 15),

          // 학습 정보 및 프로그레스
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 문제집명
                const Text(
                  workbookName,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),

                // 챕터명
                const Text(
                  chapterName,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 12),

                // 2단계 프로그레스 바
                LayoutBuilder(
                  builder: (context, constraints) {
                    final progressHeight = constraints.maxWidth * 0.04;
                    return Stack(
                      children: [
                        // 전체 배경 (회색)
                        Container(
                          height: progressHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9ECEF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // 기존 누적 진행률 (보라색)
                        FractionallySizedBox(
                          widthFactor: previousProgress,
                          child: Container(
                            height: progressHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFFAC5BF8).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        // 오늘 추가 분량 (진한 보라색)
                        FractionallySizedBox(
                          widthFactor: currentProgress,
                          child: Container(
                            height: progressHeight,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),

                // 진행 정보
                Text(
                  '${currentPage}페이지까지 진행',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '정답률 $correctRate%',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 헬퍼 메서드들

  int _getConsecutiveDays() {
    // TODO: DB에서 실제 연속 학습 일수 계산
    return 2;
  }
}
