import 'package:flutter/material.dart';
import '../../widgets/continuous_learning_widget.dart';

enum WorkbookViewType {
  byClass, // 클래스 순
  byWorkbook, // 문제집 순
}

class WorkbookPage extends StatefulWidget {
  const WorkbookPage({super.key});

  @override
  State<WorkbookPage> createState() => _WorkbookPageState();
}

class _WorkbookPageState extends State<WorkbookPage> {
  WorkbookViewType _currentView = WorkbookViewType.byClass;

  // TODO: Fetch data from server
  // 클래스 순 데이터
  final List<ClassData> _classData = [
    ClassData(
      className: '오세종 선생님 3반',
      lastStudyDate: '2025.10.09',
      workbooks: [
        WorkbookInfo(
          name: '블랙라벨 중등수학 1-1',
          lastStudyDate: '2025.10.09',
          progress: 65,
          thumbnailPath: 'assets/images/bookcovers/BookCover_Blacklabel.png',
        ),
        WorkbookInfo(
          name: '라이트쎈 중등수학 1-1',
          lastStudyDate: '2025.10.06',
          progress: 40,
          thumbnailPath: 'assets/images/bookcovers/BookCover_LightSsen.png',
        ),
      ],
    ),
    ClassData(
      className: '조성재 선생님 1반',
      lastStudyDate: '2025.10.07',
      workbooks: [
        WorkbookInfo(
          name: '100발 100중 중등수학 2-2',
          lastStudyDate: '2025.10.07',
          progress: 55,
          thumbnailPath: 'assets/images/bookcovers/BookCover_100to100.png',
        ),
      ],
    ),
    ClassData(
      className: '최상일 선생님 2반',
      lastStudyDate: '2025.10.05',
      workbooks: [
        WorkbookInfo(
          name: '수능완성 영어 2026',
          lastStudyDate: '2025.10.05',
          progress: 75,
          thumbnailPath: 'assets/images/bookcovers/workbook_2026.jpg',
        ),
        WorkbookInfo(
          name: '수능완성 영어 2025',
          lastStudyDate: '2025.10.03',
          progress: 90,
          thumbnailPath: 'assets/images/bookcovers/workbook_2025.jpg',
        ),
        WorkbookInfo(
          name: '수능완성 영어 2024',
          lastStudyDate: '2025.10.01',
          progress: 100,
          thumbnailPath: 'assets/images/bookcovers/workbook_2024.jpg',
        ),
      ],
    ),
  ];

  // 문제집 순 데이터 (모든 문제집을 마지막 학습일 순으로 정렬)
  final List<WorkbookData> _workbookData = [
    WorkbookData(
      workbookName: '블랙라벨 중등수학 1-1',
      lastStudyDate: '2025.10.09',
      progress: 65,
      thumbnailPath: 'assets/images/bookcovers/BookCover_Blacklabel.png',
      className: '오세종 선생님 3반',
    ),
    WorkbookData(
      workbookName: '100발 100중 중등수학 2-2',
      lastStudyDate: '2025.10.07',
      progress: 55,
      thumbnailPath: 'assets/images/bookcovers/BookCover_100to100.png',
      className: '조성재 선생님 1반',
    ),
    WorkbookData(
      workbookName: '라이트쎈 중등수학 1-1',
      lastStudyDate: '2025.10.06',
      progress: 40,
      thumbnailPath: 'assets/images/bookcovers/BookCover_LightSsen.png',
      className: '오세종 선생님 3반',
    ),
    WorkbookData(
      workbookName: '수능완성 영어 2026',
      lastStudyDate: '2025.10.05',
      progress: 75,
      thumbnailPath: 'assets/images/bookcovers/workbook_2026.jpg',
      className: '최상일 선생님 2반',
    ),
    WorkbookData(
      workbookName: '수능완성 영어 2025',
      lastStudyDate: '2025.10.03',
      progress: 90,
      thumbnailPath: 'assets/images/bookcovers/workbook_2025.jpg',
      className: '최상일 선생님 2반',
    ),
    WorkbookData(
      workbookName: '수능완성 영어 2024',
      lastStudyDate: '2025.10.01',
      progress: 100,
      thumbnailPath: 'assets/images/bookcovers/workbook_2024.jpg',
      className: '최상일 선생님 2반',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 메인 콘텐츠 (스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.032,
                    ),

                    // 주간 캘린더
                    _buildWeeklyCalendar(),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),

                    // 토글 버튼
                    _buildToggle(),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),

                    // 메인 콘텐츠
                    _currentView == WorkbookViewType.byClass
                        ? _buildClassView()
                        : _buildWorkbookView(),
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
        MediaQuery.of(context).size.width * 0.05,
        MediaQuery.of(context).size.height * 0.021,
        MediaQuery.of(context).size.width * 0.05,
        MediaQuery.of(context).size.height * 0.012,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '문제집',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF333333),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF333333)),
            onPressed: () {
              // TODO: 메뉴 기능 구현
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('메뉴 기능 구현 예정')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    return ContinuousLearningWidget(
      consecutiveDays: 2,
      weeklyProgress: const [true, true, false, false, false, false, false],
    );
  }

  Widget _buildToggle() {
    return Row(
      children: [
        // 토글 스위치
        GestureDetector(
          onTap: () {
            setState(() {
              _currentView = _currentView == WorkbookViewType.byClass
                  ? WorkbookViewType.byWorkbook
                  : WorkbookViewType.byClass;
            });
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.12,
              minWidth: 40,
              maxHeight: 20,
              minHeight: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _currentView == WorkbookViewType.byClass
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.05,
                  minWidth: 7,
                  maxHeight: MediaQuery.of(context).size.width * 0.05,
                  minHeight: 7,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.005,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Container(width: MediaQuery.of(context).size.width * 0.03),
        // 토글 라벨
        Text(
          _currentView == WorkbookViewType.byClass ? '최근 클래스 순' : '최근 문제집 순',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildClassView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _classData.length,
          separatorBuilder: (context, index) =>
              Container(height: MediaQuery.of(context).size.height * 0.02),
          itemBuilder: (context, index) {
            return _buildClassCard(_classData[index]);
          },
        ),
      ],
    );
  }

  Widget _buildClassCard(ClassData classData) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 클래스명
          Text(
            classData.className,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),

          Container(height: MediaQuery.of(context).size.height * 0.02),

          // 문제집 썸네일과 진행률 리스트
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              classData.workbooks.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  right: index < classData.workbooks.length - 1
                      ? MediaQuery.of(context).size.width * 0.04
                      : 0,
                ),
                child: _buildWorkbookProgress(classData.workbooks[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkbookProgress(WorkbookInfo workbook) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = screenWidth * 0.15; // 화면 너비의 15%
    final thumbnailHeight = thumbnailWidth * 1.33; // 3:4 비율 유지

    return GestureDetector(
      onTap: () {
        // WorkbookDetailPage로 이동
        Navigator.pushNamed(
          context,
          '/workbook/detail',
          arguments: {
            'workbookName': workbook.name,
            'thumbnailPath': workbook.thumbnailPath,
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문제집 썸네일
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: thumbnailWidth,
              height: thumbnailHeight,
              color: const Color(0xFFE9ECEF),
              child: Image.asset(
                workbook.thumbnailPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.book, color: Color(0xFF999999)),
                  );
                },
              ),
            ),
          ),
          Container(height: MediaQuery.of(context).size.height * 0.01),
          // 진행률 바
          SizedBox(
            width: thumbnailWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFFE9ECEF)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: workbook.progress / 100,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkbookView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _workbookData.length,
          separatorBuilder: (context, index) =>
              Container(height: MediaQuery.of(context).size.height * 0.02),
          itemBuilder: (context, index) {
            return _buildWorkbookCard(_workbookData[index]);
          },
        ),
      ],
    );
  }

  Widget _buildWorkbookCard(WorkbookData workbookData) {
    return GestureDetector(
      onTap: () {
        // WorkbookDetailPage로 이동
        Navigator.pushNamed(
          context,
          '/workbook/detail',
          arguments: {
            'workbookName': workbookData.workbookName,
            'thumbnailPath': workbookData.thumbnailPath,
          },
        );
      },
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE9ECEF)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 문제집 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.18,
                  minWidth: 60,
                  maxHeight: MediaQuery.of(context).size.width * 0.23,
                  minHeight: 80,
                ),
                color: const Color(0xFFE74C3C),
                child: Image.asset(
                  workbookData.thumbnailPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'blacklabel',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            Container(width: MediaQuery.of(context).size.width * 0.04),

            // 문제집 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 문제집명
                  Text(
                    workbookData.workbookName,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.01),

                  // 학습 정보
                  Text(
                    '${workbookData.className}에서 진행 중',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.005),

                  // 마지막 학습일
                  Text(
                    '마지막 학습 일 ${workbookData.lastStudyDate}',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.015),

                  // 진행률
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9ECEF),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: workbookData.progress / 100,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFAC5BF8),
                                    Color(0xFF7C3AED),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
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
            ),
          ],
        ),
      ),
    );
  }
}

// 클래스 데이터 모델
class ClassData {
  final String className;
  final String lastStudyDate;
  final List<WorkbookInfo> workbooks;

  ClassData({
    required this.className,
    required this.lastStudyDate,
    required this.workbooks,
  });
}

// 문제집 정보 모델 (클래스 내부용)
class WorkbookInfo {
  final String name;
  final String lastStudyDate;
  final int progress;
  final String thumbnailPath;

  WorkbookInfo({
    required this.name,
    required this.lastStudyDate,
    required this.progress,
    required this.thumbnailPath,
  });
}

// 문제집 데이터 모델 (문제집 순 페이지용)
class WorkbookData {
  final String workbookName;
  final String lastStudyDate;
  final int progress;
  final String thumbnailPath;
  final String className;

  WorkbookData({
    required this.workbookName,
    required this.lastStudyDate,
    required this.progress,
    required this.thumbnailPath,
    required this.className,
  });
}
