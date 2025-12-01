import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/app_header_menu_button.dart';
import '../widgets/back_button.dart';
import '../services/continuous_learning_api.dart';
import '../services/academy_service.dart';
import '../services/auth_service.dart';
import '../services/get_monthly_learning_status_use_case_impl.dart';
import '../domain/learning/get_monthly_learning_status_use_case.dart';
import '../domain/learning/daily_learning_status.dart';
import '../utils/academy_utils.dart';
import '../utils/app_logger.dart';
import 'dart:developer' as developer;

/// 연속학습 상세 페이지
///
/// Figma 디자인 기반 캘린더 뷰
class ContinuousLearningDetailPage extends StatefulWidget {
  final GetMonthlyLearningStatusUseCase monthlyStatusUseCase;

  const ContinuousLearningDetailPage({
    super.key,
    required this.monthlyStatusUseCase,
  });

  @override
  State<ContinuousLearningDetailPage> createState() =>
      _ContinuousLearningDetailPageState();
}

class _ContinuousLearningDetailPageState
    extends State<ContinuousLearningDetailPage> {
  late int _currentMonth;
  late int _currentYear;

  // Services
  final AuthService _authService = AuthService();
  final AcademyService _academyService = AcademyService();
  final ContinuousLearningApi _continuousLearningApi = ContinuousLearningApi();

  // UseCase 접근 (widget을 통해)
  GetMonthlyLearningStatusUseCase get _monthlyStatusUseCase =>
      widget.monthlyStatusUseCase;

  // 현재 월의 상태 캐시
  Map<DateTime, DailyLearningStatus>? _currentMonthStatuses;

  // Statistics data
  int _totalDays = 0;
  int _totalProblems = 0;
  bool _isLoadingStatistics = false;

  @override
  void initState() {
    super.initState();
    // 현재 날짜를 기반으로 초기 월/년 설정
    final now = DateTime.now();
    _currentMonth = now.month;
    _currentYear = now.year;

    // 통계 데이터 로드
    _loadStatistics();
    // 현재 월의 학습 상태 로드
    _loadMonthlyStatuses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 페이지에서 돌아올 때 강제 새로고침
    _loadStatistics(forceRefresh: true);
    _loadMonthlyStatuses();
  }

  /// UseCase로 현재 월의 학습 상태 로드
  Future<void> _loadMonthlyStatuses() async {
    try {
      // 사용자 학원 정보 조회
      final userId = await _authService.getUserId();
      if (userId == null) {
        setState(() {
          _currentMonthStatuses = {};
        });
        return;
      }

      final academies = await _academyService.getUserAcademies(userId);
      final registeredAcademies = academies
          .where((a) => a.registerStatus == 'Y')
          .toList();

      if (registeredAcademies.isEmpty) {
        setState(() {
          _currentMonthStatuses = {};
        });
        return;
      }

      // academyId와 academyUserIds 조회
      final userAcademyId = await getUserAcademyId(
        academyService: _academyService,
        registeredAcademies: registeredAcademies,
      );

      if (userAcademyId == null) {
        setState(() {
          _currentMonthStatuses = {};
        });
        return;
      }

      final academyUserIds = registeredAcademies
          .map((a) => a.academy_user_id)
          .whereType<int>()
          .toList();

      // UseCase 구현체의 callWithContext 호출
      final month = DateTime(_currentYear, _currentMonth, 1);
      if (_monthlyStatusUseCase is GetMonthlyLearningStatusUseCaseImpl) {
        final statuses = await (_monthlyStatusUseCase as GetMonthlyLearningStatusUseCaseImpl)
            .callWithContext(
          month: month,
          academyId: userAcademyId,
          academyUserIds: academyUserIds,
        );

        setState(() {
          _currentMonthStatuses = {
            for (var status in statuses)
              DailyLearningStatus.normalizeDate(status.date): status
          };
        });
      } else {
        // 기본 UseCase 인터페이스 사용 (빈 상태)
        final statuses = await _monthlyStatusUseCase.call(month);
        setState(() {
          _currentMonthStatuses = {
            for (var status in statuses)
              DailyLearningStatus.normalizeDate(status.date): status
          };
        });
      }
    } catch (e) {
      // 에러 발생 시 빈 상태 유지
    }
  }

  /// 통계 데이터 로드
  Future<void> _loadStatistics({bool forceRefresh = false}) async {
    if (_isLoadingStatistics) return;

    setState(() {
      _isLoadingStatistics = true;
    });

    try {
      // 1. UserId로 academyUserIds 조회
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }

      final academies = await _academyService.getUserAcademies(userId);
      final academyUserIds = academies
          .where((a) => a.registerStatus == 'Y')
          .map((a) => a.academy_user_id)
          .whereType<int>()
          .toList();

      if (academyUserIds.isEmpty) {
        setState(() {
          _totalDays = 0;
          _totalProblems = 0;
          _isLoadingStatistics = false;
        });
        return;
      }

      // 2. 여러 academyUserId에 대한 통계 조회 (병렬)
      appLog(
        '[continuous_learning:continuous_learning_detail_page] 통계 조회 시작 - academyUserIds: $academyUserIds',
      );
      final summariesMap = await _continuousLearningApi
          .fetchGradingHistorySummaries(academyUserIds);

      // 3. 데이터 합산
      int totalDays = 0;
      double totalScore = 0.0;

      summariesMap.forEach((academyUserId, summary) {
        appLog(
          '[continuous_learning:continuous_learning_detail_page] academyUserId: $academyUserId - totalScore: ${summary.totalScore}, daysSinceStartOfYear: ${summary.daysSinceStartOfYear}',
        );
        // days_since_start_of_year는 가장 큰 값 사용 (가장 오래된 시작일 기준)
        if (summary.daysSinceStartOfYear > totalDays) {
          totalDays = summary.daysSinceStartOfYear;
        }
        // total_score는 합산
        totalScore += summary.totalScore;
      });

      appLog(
        '[continuous_learning:continuous_learning_detail_page] 통계 합산 완료 - totalDays: $totalDays, totalScore: $totalScore',
      );

      // 4. UI 업데이트
      setState(() {
        _totalDays = totalDays;
        _totalProblems = totalScore.round(); // total_score를 문제 수로 사용
        _isLoadingStatistics = false;
      });
    } catch (e) {
      appLog(
        '[continuous_learning:continuous_learning_detail_page] 통계 로드 실패: $e',
      );
      developer.log('❌ [ContinuousLearningDetailPage] 통계 로드 실패: $e');
      setState(() {
        _isLoadingStatistics = false;
        // 에러 발생 시 기본값 유지
      });
    }
  }

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
    return AppHeader(
      leading: CustomBackButton(),
      title: const Text(
        '연속학습',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Color(0xFF585B69),
        ),
      ),
      trailing: const AppHeaderMenuButton(),
      titleAlignment: 'left',
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
            _loadMonthlyStatuses();
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
            _loadMonthlyStatuses();
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
    // Flutter의 weekday: 월요일=1, 화요일=2, ..., 일요일=7
    // 우리는 월요일을 0으로 변환 (0~6)
    final firstWeekday = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday - 1;

    // 필요한 주 수 계산: 첫 번째 날의 위치 + 마지막 날의 위치를 고려
    // 총 날짜 수 + 첫 번째 날 이전의 빈 칸 수를 7로 나눈 후 올림
    final totalDays = lastDayOfMonth.day;
    final totalCells = firstWeekday + totalDays;
    final weeksNeeded = (totalCells / 7).ceil();

    // 이전 달의 마지막 날짜들 계산
    final prevMonth = _currentMonth == 1 ? 12 : _currentMonth - 1;
    final prevYear = _currentMonth == 1 ? _currentYear - 1 : _currentYear;
    final daysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;

    // Table 위젯을 사용하여 정확한 그리드 정렬
    return Table(
      border: TableBorder.all(color: Colors.transparent),
      columnWidths: {for (int i = 0; i < 7; i++) i: const FlexColumnWidth(1.0)},
      children: List.generate(weeksNeeded, (weekIndex) {
        return TableRow(
          children: List.generate(7, (dayIndex) {
            final cellIndex = weekIndex * 7 + dayIndex;
            final day = cellIndex - firstWeekday + 1;

            // 이전 달의 날짜
            if (day <= 0) {
              final dayInPrevMonth = daysInPrevMonth + day;
              return _buildDateCell(
                day: dayInPrevMonth,
                isCurrentMonth: false,
                isCompleted: false,
              );
            }
            // 다음 달의 날짜
            else if (day > totalDays) {
              final dayInNextMonth = day - totalDays;
              return _buildDateCell(
                day: dayInNextMonth,
                isCurrentMonth: false,
                isCompleted: false,
              );
            }
            // 현재 달의 날짜
            else {
              final date = DateTime(_currentYear, _currentMonth, day);
              final isCompleted = _isDateCompleted(day);
              return _buildDateCell(
                day: day,
                isCurrentMonth: true,
                isCompleted: isCompleted,
                date: date,
              );
            }
          }),
        );
      }),
    );
  }

  /// 날짜가 완료되었는지 판단
  bool _isDateCompleted(int day) {
    final date = DailyLearningStatus.normalizeDate(
      DateTime(_currentYear, _currentMonth, day),
    );
    return _currentMonthStatuses?[date]?.isCompleted ?? false;
  }

  /// 날짜 셀 탭 핸들러
  void _onDateCellTapped(DateTime date) {
    final timestamp = DateTime.now().toIso8601String();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '선택된 날짜: ${_formatDate(date)}\nTimestamp: $timestamp',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildDateCell({
    required int day,
    required bool isCurrentMonth,
    required bool isCompleted,
    DateTime? date,
  }) {
    return GestureDetector(
      onTap: date != null && isCurrentMonth
          ? () => _onDateCellTapped(date)
          : null,
      child: Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 날짜 박스
          if (isCurrentMonth)
            Container(
              width: 41,
              height: 43,
              decoration: isCompleted
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                          // 로고 그라데이션: linear-gradient(121.67deg, #AC5BF8 19.64%, #636ACF 77.54%)
                          colors: [
                            Color(0xFFAC5BF8),
                            Color(0xFF636ACF),
                          ],
                          stops: [0.1964, 0.7754],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : BoxDecoration(
                        color: const Color(0xFFE1E7ED), // 회색
                      borderRadius: BorderRadius.circular(10),
                    ),
            ),
          // 날짜 텍스트
          Text(
            '$day',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: isCurrentMonth
                  ? (isCompleted ? Colors.white : const Color(0xFF000000))
                  : const Color(0xFF707070),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        ),
      ),
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
      child: _isLoadingStatistics
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFAC5BF8)),
                ),
              ),
            )
          : Text(
              '$_totalDays일동안 $_totalProblems문제를 풀었어요.',
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
