import 'package:flutter/material.dart';
import '../widgets/continuous_learning_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 상수 정의
  static const double _sectionSpacing = 0.04; // 섹션 간 간격 (화면 높이의 4%)
  static const double _smallSpacing = 0.01; // 작은 간격 (화면 높이의 1%)
  static const double _horizontalPadding = 0.05; // 수평 패딩 (화면 너비의 5%)
  static const double _containerPadding = 0.048; // 컨테이너 패딩 (화면 너비의 4.8%)
  static const double _progressFactor = 0.7; // 진행률 기본값 (70%)
  static const int _consecutiveDays = 2; // 연속 학습 일수

  // TODO: DB 연동 구현 필요
  // 1. 연속 학습 데이터 (consecutiveDays, weeklyProgress) - DB에서 사용자의 학습 기록 조회
  // 2. 오늘의 숙제 목록 - DB에서 해당 사용자의 오늘 할당된 숙제 목록 조회
  // 3. 오늘의 학습 현황 - DB에서 오늘 완료한 학습 과목별 진행률 조회
  // 4. 주간 학습 현황 - DB에서 지난 7일간의 학습 통계 데이터 조회
  // 5. 학원 정보 (헤더의 '정다훈 학원') - DB에서 사용자가 등록한 학원 정보 조회

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      MediaQuery.of(context).size.width * _horizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.032,
                    ),

                    // 연속학습 섹션
                    // TODO: DB에서 사용자의 연속 학습 데이터 조회하여 동적으로 설정
                    // - consecutiveDays: DB에서 사용자의 연속 학습 일수 조회
                    // - weeklyProgress: DB에서 지난 7일간의 학습 완료 여부 조회
                    ContinuousLearningWidget(
                      consecutiveDays: _consecutiveDays, // TODO: DB 데이터로 교체
                      weeklyProgress: [
                        true, // TODO: DB에서 월요일 학습 완료 여부 조회
                        true, // TODO: DB에서 화요일 학습 완료 여부 조회
                        false, // TODO: DB에서 수요일 학습 완료 여부 조회
                        false, // TODO: DB에서 목요일 학습 완료 여부 조회
                        false, // TODO: DB에서 금요일 학습 완료 여부 조회
                        false, // TODO: DB에서 토요일 학습 완료 여부 조회
                        false, // TODO: DB에서 일요일 학습 완료 여부 조회
                      ],
                    ),

                    Container(
                      height:
                          MediaQuery.of(context).size.height * _sectionSpacing,
                    ),

                    // 오늘의 숙제 섹션
                    _buildTodayHomework(),

                    Container(
                      height:
                          MediaQuery.of(context).size.height * _sectionSpacing,
                    ),

                    // 오늘의 학습 현황 섹션
                    _buildTodayLearning(),

                    Container(
                      height:
                          MediaQuery.of(context).size.height * _sectionSpacing,
                    ),

                    // 주간 학습 현황 섹션
                    _buildWeeklyLearning(),

                    Container(
                      height:
                          MediaQuery.of(context).size.height * _sectionSpacing,
                    ),
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
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.075,
        MediaQuery.of(context).size.height * 0.021,
        MediaQuery.of(context).size.width * 0.075,
        MediaQuery.of(context).size.height * 0.012,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더 콘텐츠
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 학원명과 드롭다운
              // TODO: DB에서 사용자가 등록한 학원 정보 조회
              // - 사용자가 등록한 학원명 표시
              // - 여러 학원에 등록된 경우 드롭다운으로 선택 가능
              Row(
                children: [
                  const Text(
                    '정다훈 학원', // TODO: DB에서 조회한 실제 학원명으로 교체
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Container(width: MediaQuery.of(context).size.width * 0.015),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ],
              ),

              // 메뉴 버튼
              Icon(Icons.menu, color: Colors.grey[600], size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayHomework() {
    // TODO: DB에서 오늘의 숙제 데이터 조회
    // - 사용자가 등록한 학원의 오늘 할당된 숙제 목록 조회
    // - 숙제 제목, 완료 여부, 마감일 등 정보 포함
    // - 완료된 숙제는 체크박스 표시, 미완료 숙제는 빈 체크박스 표시

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('오늘의 숙제'),
        Container(height: MediaQuery.of(context).size.height * _smallSpacing),
        _buildHomeworkContainer(),
      ],
    );
  }

  Widget _buildHomeworkContainer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * _containerPadding,
        MediaQuery.of(context).size.height * 0.019,
        MediaQuery.of(context).size.width * _containerPadding,
        MediaQuery.of(context).size.height * 0.026,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: _buildHomeworkItems()),
    );
  }

  List<Widget> _buildHomeworkItems() {
    // TODO: DB에서 조회한 숙제 목록을 동적으로 생성
    return [
      _buildHomeworkItem('오늘의 숙제 리스트'),
      _buildHomeworkItem('오늘의 숙제 리스트'),
      _buildHomeworkItem('오늘의 숙제 리스트'),
      _buildHomeworkItem('오늘의 숙제 리스트'),
      _buildHomeworkItem('오늘의 숙제 리스트'),
    ];
  }

  Widget _buildHomeworkItem(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * 0.012,
      ),
      child: Row(
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.03,
              minWidth: 10,
              maxHeight: MediaQuery.of(context).size.width * 0.03,
              minHeight: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE9ECEF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(width: MediaQuery.of(context).size.width * 0.02),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLearning() {
    // TODO: DB에서 오늘의 학습 현황 데이터 조회
    // - 사용자가 오늘 학습한 과목별 진행률 조회
    // - 각 과목의 아이콘, 진행률, 과목명 정보 포함
    // - 학습 완료율에 따른 진행률 바 표시

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('오늘의 학습 현황'),
        Container(height: MediaQuery.of(context).size.height * _smallSpacing),
        _buildLearningContainer(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF333333),
          ),
        ),
        const Spacer(),
        Icon(Icons.chevron_right, color: Colors.grey[600], size: 17),
      ],
    );
  }

  Widget _buildLearningContainer() {
    final screenHeight = MediaQuery.of(context).size.height;
    final sectionHeight = screenHeight * 0.2; // 화면 높이의 20%

    return Container(
      height: sectionHeight,
      padding: EdgeInsets.symmetric(
        horizontal: sectionHeight * 0.05, // 5% 수평 패딩
        vertical: sectionHeight * 0.1, // 10% 수직 패딩
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, innerConstraints) {
          final availableHeight = innerConstraints.maxHeight;
          return _buildLearningList(availableHeight);
        },
      ),
    );
  }

  Widget _buildLearningList(double availableHeight) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _buildLearningItem(
          'assets/images/bookcovers/workbook_2026.jpg',
          availableHeight,
        ),
        SizedBox(width: availableHeight * 0.15),
        _buildLearningItem(
          'assets/images/bookcovers/workbook_2025.jpg',
          availableHeight,
        ),
        SizedBox(width: availableHeight * 0.15),
        _buildLearningItem(
          'assets/images/bookcovers/workbook_2024.jpg',
          availableHeight,
        ),
        SizedBox(width: availableHeight * 0.15),
      ],
    );
  }

  Widget _buildLearningItem(String imagePath, double containerHeight) {
    // 표지와 상태바가 컨테이너 높이의 90%를 차지하도록 설정 (더 크게!)
    final totalItemHeight = containerHeight * 0.9;

    // 표지 높이: 전체 아이템 높이의 80%
    final bookHeight = totalItemHeight * 0.8;
    // 3:4 비율에 맞춰 너비 계산
    final bookWidth = bookHeight * 0.75; // 3/4 = 0.75

    return SizedBox(
      height: containerHeight, // 전체 컨테이너 높이 사용
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
        children: [
          // 학습 아이콘 (3:4 비율 사각형) - 교재 표지 이미지
          Container(
            width: bookWidth, // 상대 크기 (3:4 비율)
            height: bookHeight, // 상대 크기 (컨테이너 높이의 80%)
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(
                bookHeight * 0.1,
              ), // 상대적 둥근 모서리
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(bookHeight * 0.1),
              child: Image.asset(
                imagePath, // 교재 표지 이미지 경로
                width: bookWidth,
                height: bookHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지 로드 실패 시 기본 아이콘 표시
                  return Icon(
                    Icons.book,
                    color: Colors.grey[400],
                    size: bookHeight * 0.4,
                  );
                },
              ),
            ),
          ),

          SizedBox(height: totalItemHeight * 0.1), // 표지와 진행률 바 사이 간격
          // 진행률 바
          Container(
            width: bookWidth,
            height: totalItemHeight * 0.1, // 전체 아이템 높이의 10%
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(totalItemHeight * 0.05),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progressFactor, // 70% 진행률
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
                  ),
                  borderRadius: BorderRadius.circular(totalItemHeight * 0.05),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyLearning() {
    // TODO: DB에서 주간 학습 현황 데이터 조회
    // - 지난 7일간의 학습 통계 데이터 조회
    // - 일별 학습 시간, 완료한 과목 수, 성취도 등 정보 포함
    // - 차트 라이브러리(fl_chart 등)를 사용하여 시각화 구현

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('주간 학습 현황'),
        Container(height: MediaQuery.of(context).size.height * _smallSpacing),
        _buildWeeklyChartContainer(),
      ],
    );
  }

  Widget _buildWeeklyChartContainer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * _containerPadding,
        MediaQuery.of(context).size.height * 0.019,
        MediaQuery.of(context).size.width * _containerPadding,
        MediaQuery.of(context).size.height * 0.026,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.1,
          maxHeight: MediaQuery.of(context).size.height * 0.15,
        ),
        child: const Center(
          child: Text(
            '주간 학습 현황 차트', // TODO: 실제 차트로 교체 (fl_chart 등 사용)
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}
