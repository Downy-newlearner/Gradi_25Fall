import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../domain/learning/daily_learning_status.dart';
import '../domain/learning/get_monthly_learning_status_use_case.dart';
import '../constants/learning_widget_spacing.dart';

/// 연속학습 위젯 V2 - 개선된 UI/UX
///
/// 주요 기능:
/// 1. 월별 날짜 스크롤 (한 달 단위)
/// 2. 선택된 날짜 표시
/// 3. 학습 완료 상태 표시 (그라데이션 박스)
/// 4. 숙제 마감일 표시 (책 아이콘)
/// 5. 연속 학습일 연결선 표시
///
/// 데이터 소스 우선순위:
/// 1. dailyStatusMap (새 구조, 권장)
/// 2. monthlyStatusUseCase (새 구조, 권장)
/// 3. dateAssessments (하위 호환성, 추후 제거 예정)
/// 4. completedDates (하위 호환성, 추후 제거 예정)
///
/// 힌트 박스 정렬 기준:
/// - 힌트 박스는 DateItem의 1:1 박스(AspectRatio) 기준 중앙에 정렬됩니다.
/// - DateItem의 텍스트 영역은 힌트 정렬에 영향을 주지 않습니다.
/// - Stack 높이는 itemWidth(cardWidth)로 설정되어 박스 높이와 일치합니다.
class ContinuousLearningWidgetV2 extends StatefulWidget {
  final int consecutiveDays;
  final Set<String> homeworkDeadlines;
  final Function(DateTime)? onDateSelected;
  final DateTime? selectedDate;

  // 새 구조 (권장)
  final Map<DateTime, DailyLearningStatus>? dailyStatusMap;
  final GetMonthlyLearningStatusUseCase? monthlyStatusUseCase;

  // 하위 호환성 (추후 제거 예정)
  @Deprecated('Use dailyStatusMap or monthlyStatusUseCase instead')
  final Set<String> completedDates;
  @Deprecated('Use dailyStatusMap or monthlyStatusUseCase instead')
  final Map<String, List<Assessment>>? dateAssessments;

  const ContinuousLearningWidgetV2({
    super.key,
    required this.consecutiveDays,
    this.homeworkDeadlines = const {},
    this.onDateSelected,
    this.selectedDate,
    // 새 구조
    this.dailyStatusMap,
    this.monthlyStatusUseCase,
    // 하위 호환성
    @Deprecated('Use dailyStatusMap or monthlyStatusUseCase instead')
    this.completedDates = const {},
    @Deprecated('Use dailyStatusMap or monthlyStatusUseCase instead')
    this.dateAssessments,
  });

  @override
  State<ContinuousLearningWidgetV2> createState() =>
      _ContinuousLearningWidgetV2State();
}

class _ContinuousLearningWidgetV2State
    extends State<ContinuousLearningWidgetV2> {
  late DateTime _selectedDate;
  final ScrollController _dateScrollController = ScrollController();

  // 현재 표시 중인 월/년도
  late DateTime _currentMonth; // 현재 표시 중인 월의 첫 날 (예: 2025-11-01)

  // 월 전환 중복 방지
  bool _isChangingMonth = false;

  // 마지막 월 변경 시간 (2초 쿨다운용)
  DateTime? _lastMonthChangeTime;

  // 힌트 표시 관련
  bool _showNextMonthHint = false; // 다음 달 힌트 표시 여부
  bool _showPrevMonthHint = false; // 이전 달 힌트 표시 여부

  // 아이템 너비 (한 곳에서 정의)
  double? _itemWidth;

  // 현재 월의 상태 캐시 (UseCase 사용 시)
  Map<DateTime, DailyLearningStatus>? _currentMonthStatuses;

  /// 아이템 너비 getter (저장된 값 반환)
  ///
  /// itemWidth는 didChangeDependencies에서 계산되며,
  /// 이 getter는 저장된 값을 반환합니다.
  /// null인 경우 에러가 발생합니다.
  double get itemWidth {
    assert(
      _itemWidth != null,
      'itemWidth must be initialized in didChangeDependencies',
    );
    return _itemWidth!;
  }

  // 월 전환 트리거 관련 상수
  // 오버스크롤 임계값: 스크롤이 끝을 넘어서 일정 거리 이상 오버스크롤했을 때만 전환
  static const double _monthChangeOverScrollThreshold =
      0.3; // 아이템 0.3개 너비 이상 오버스크롤 (더 유연하게)

  // 경계 월 제한 (추후 비즈니스 룰에 따라 주입 가능)
  DateTime? _minMonth;
  DateTime? _maxMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    // 현재 월의 첫 날로 초기화
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);

    // 다음 달 이동 제한: 현재 달로부터 다음 달까지만 이동 가능
    // 예: 11월이면 12월까지만 이동 가능, 13월은 불가
    _maxMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    // 이전 달 이동은 제한 없음 (_minMonth는 null로 유지)

    // UseCase가 있으면 현재 월 데이터 로드
    if (widget.monthlyStatusUseCase != null) {
      _loadMonthlyStatuses();
    }

    // 오늘 날짜가 오른쪽 끝에 오도록 스크롤 위치 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToDateInCurrentMonth(_selectedDate, jump: true);
      }
    });
  }

  /// UseCase로 현재 월의 학습 상태 로드
  ///
  /// 동기화 시점:
  /// - initState: 위젯 초기화 시 현재 월 데이터 로드
  /// - didChangeDependencies: 다른 페이지에서 돌아올 때 최신 데이터로 동기화
  /// - didUpdateWidget: monthlyStatusUseCase 변경 시 새로 로드
  /// - _changeMonth: 월 변경 시 새 월의 데이터 로드
  Future<void> _loadMonthlyStatuses() async {
    if (widget.monthlyStatusUseCase == null) return;

    try {
      final statuses = await widget.monthlyStatusUseCase!.call(_currentMonth);
      if (mounted) {
        setState(() {
          _currentMonthStatuses = {
            for (var status in statuses)
              DailyLearningStatus.normalizeDate(status.date): status,
          };
        });
      }
    } catch (e) {
      // 에러 발생 시 빈 상태 유지
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 아이템 너비를 한 곳에서 정의 (캐싱)
    // itemWidth와 cardWidth를 통일하기 위해 screenWidth / 7 사용
    if (_itemWidth == null) {
      final screenWidth = MediaQuery.of(context).size.width;
      _itemWidth = screenWidth / 7;
    }

    // 다른 페이지에서 돌아올 때 현재 월의 학습 상태를 최신 정보로 동기화
    // (예: 숙제 완료 상태 변경 등)
    if (widget.monthlyStatusUseCase != null) {
      _loadMonthlyStatuses();
    }
  }

  @override
  void didUpdateWidget(covariant ContinuousLearningWidgetV2 oldWidget) {
    super.didUpdateWidget(oldWidget);

    // monthlyStatusUseCase가 변경되었거나 추가되었을 때 상태 로드
    if (widget.monthlyStatusUseCase != null &&
        (oldWidget.monthlyStatusUseCase == null ||
            oldWidget.monthlyStatusUseCase != widget.monthlyStatusUseCase)) {
      _loadMonthlyStatuses();
    }

    // dailyStatusMap이 변경되었을 때는 자동으로 반영됨 (widget.dailyStatusMap 사용)

    final newSelected = widget.selectedDate ?? DateTime.now();
    if (!_isSameDay(newSelected, _selectedDate)) {
      setState(() {
        _selectedDate = newSelected;
      });
      // 외부에서 selectedDate 변경 시: _setMonthAndScroll 사용 (월+스크롤 모두 책임)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setMonthAndScroll(newSelected);
        }
      });
    }
  }

  /// 월 변경 + 스크롤을 함께 처리하는 상위 메서드
  ///
  /// 책임: 월 변경과 스크롤을 순서대로 처리하여 복잡도 감소
  void _setMonthAndScroll(DateTime targetDate) {
    final targetMonth = DateTime(targetDate.year, targetDate.month, 1);

    // 월이 다르면 먼저 변경
    if (_currentMonth.year != targetMonth.year ||
        _currentMonth.month != targetMonth.month) {
      // targetDate를 selectedDate로 전달하여 해당 날짜로 이동
      _changeMonth(targetMonth, selectedDate: targetDate);
      // _changeMonth 내부에서 이미 스크롤 처리됨
      return;
    }

    // 같은 월이면 스크롤만
    _scrollToDateInCurrentMonth(targetDate, jump: false);
  }

  /// 현재 월 내에서 날짜로 스크롤 (책임: 스크롤 위치만 조정)
  void _scrollToDateInCurrentMonth(DateTime date, {bool jump = false}) {
    // 선택된 날짜가 현재 표시 중인 월에 속하는지 확인
    if (date.year != _currentMonth.year || date.month != _currentMonth.month) {
      // 다른 월이면 월을 먼저 변경 (상위 메서드 호출)
      _setMonthAndScroll(date);
      return;
    }

    if (!_dateScrollController.hasClients) return;

    final targetIndex = date.day - 1; // 1일부터 시작하므로 -1
    final offset = targetIndex * itemWidth; // getter 사용

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

  /// 다음 달로 이동
  void _navigateToNextMonth() {
    // 2초 쿨다운 체크
    final now = DateTime.now();
    if (_lastMonthChangeTime != null) {
      final timeSinceLastChange = now.difference(_lastMonthChangeTime!);
      if (timeSinceLastChange.inSeconds < 4) {
        return; // 4초가 지나지 않았으면 이동 불가
      }
    }

    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);

    // 경계 체크
    if (_maxMonth != null && nextMonth.isAfter(_maxMonth!)) {
      return;
    }

    // 다음 달 첫 날로 이동
    final targetDate = DateTime(nextMonth.year, nextMonth.month, 1);

    _lastMonthChangeTime = now;
    _changeMonth(nextMonth, selectedDate: targetDate);
  }

  /// 이전 달로 이동
  void _navigateToPreviousMonth() {
    // 2초 쿨다운 체크
    final now = DateTime.now();
    if (_lastMonthChangeTime != null) {
      final timeSinceLastChange = now.difference(_lastMonthChangeTime!);
      if (timeSinceLastChange.inSeconds < 4) {
        return; // 4초가 지나지 않았으면 이동 불가
      }
    }

    // 이전 달의 마지막 날 계산
    // DateTime(year, month, 0)은 이전 달의 마지막 날을 반환합니다
    // 예: DateTime(2025, 11, 0) → 2025년 10월 31일
    final prevMonthLastDay = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      0,
    );
    final prevMonthFirstDay = DateTime(
      prevMonthLastDay.year,
      prevMonthLastDay.month,
      1,
    );

    // 경계 체크 (첫 날 기준으로 체크)
    if (_minMonth != null && prevMonthFirstDay.isBefore(_minMonth!)) {
      return;
    }

    // 이전 달의 마지막 날로 이동
    _lastMonthChangeTime = now;
    _changeMonth(prevMonthFirstDay, selectedDate: prevMonthLastDay);
  }

  /// 월 변경 (책임: 월 상태만 변경)
  ///
  /// [newMonth]: 새 월의 첫 날
  /// [selectedDate]: 선택할 날짜 (null이면 현재 일자를 새 월로 변환)
  void _changeMonth(DateTime newMonth, {DateTime? selectedDate}) {
    // 같은 월이면 무시
    if (_currentMonth.year == newMonth.year &&
        _currentMonth.month == newMonth.month) {
      return;
    }

    if (_isChangingMonth) return;

    _isChangingMonth = true;

    setState(() {
      _currentMonth = newMonth;
      // 선택된 날짜 설정
      if (selectedDate != null) {
        // 명시적으로 전달된 날짜 사용
        _selectedDate = selectedDate;
      } else {
        // selectedDate가 없으면 현재 선택된 날짜의 일자를 새 월로 변환 시도
        final currentDay = _selectedDate.day;
        final newMonthLastDay = DateTime(
          newMonth.year,
          newMonth.month + 1,
          0,
        ).day;
        final targetDay = currentDay <= newMonthLastDay
            ? currentDay
            : newMonthLastDay;
        _selectedDate = DateTime(newMonth.year, newMonth.month, targetDay);
      }
    });

    // 새 월의 학습 상태 로드
    if (widget.monthlyStatusUseCase != null) {
      _loadMonthlyStatuses();
    }

    // 스크롤 위치 조정: _currentMonth와 _selectedDate가 이미 동기화되어 있으므로 직접 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isChangingMonth = false;
        return;
      }

      if (!_dateScrollController.hasClients) {
        _isChangingMonth = false;
        return;
      }

      // _currentMonth와 _selectedDate가 이미 동기화되어 있으므로 직접 스크롤
      // 애니메이션 없이 즉시 이동 (jumpTo)하여 무한 루프 방지
      final targetIndex = _selectedDate.day - 1;
      final offset = targetIndex * itemWidth;
      _dateScrollController
          .animateTo(
            offset,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
          .then((_) {
            if (mounted) {
              _isChangingMonth = false;
            }
          });
    });
  }

  /// 스크롤 위치 업데이트하여 힌트 표시 여부 결정
  void _updateHintVisibility() {
    if (!_dateScrollController.hasClients || _isChangingMonth) {
      return;
    }

    final position = _dateScrollController.position;
    final pixels = position.pixels;
    final max = position.maxScrollExtent;
    final width = itemWidth;

    // 힌트 표시 임계값: 스크롤이 끝에 거의 도달했을 때만 표시
    // 오버스크롤(음수 또는 max 초과) 상태에서만 힌트 표시
    final hintThreshold = width * 0.2; // 0.2개 아이템 너비 (더 유연하게)

    // 다음 달 힌트 표시 조건: 오른쪽 끝을 넘어서 오버스크롤 상태
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final canMoveToNext =
        _maxMonth == null ||
        nextMonth.isBefore(_maxMonth!) ||
        nextMonth.isAtSameMomentAs(_maxMonth!);
    // max를 넘어서 오버스크롤했을 때만 힌트 표시
    final shouldShowNextHint = pixels > max + hintThreshold && canMoveToNext;

    // 이전 달 힌트 표시 조건: 왼쪽 끝을 넘어서 오버스크롤 상태
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    final canMoveToPrev =
        _minMonth == null ||
        prevMonth.isAfter(_minMonth!) ||
        prevMonth.isAtSameMomentAs(_minMonth!);
    // 0을 넘어서 오버스크롤했을 때만 힌트 표시
    final shouldShowPrevHint = pixels < -hintThreshold && canMoveToPrev;

    if (mounted) {
      setState(() {
        _showNextMonthHint = shouldShowNextHint;
        _showPrevMonthHint = shouldShowPrevHint;
      });
    }
  }

  /// ScrollNotification 처리
  ///
  /// ScrollUpdateNotification: 힌트 표시 업데이트
  /// ScrollEndNotification: 월 전환 판단
  bool _handleScrollNotification(ScrollNotification notification) {
    // 스크롤 업데이트 시 힌트 표시 업데이트
    if (notification is ScrollUpdateNotification) {
      _updateHintVisibility();
      return false; // 계속 전파
    }

    // 스크롤이 끝난 시점에만 월 전환 처리
    if (notification is! ScrollEndNotification) {
      return false; // 계속 전파
    }

    // 힌트 숨기기
    if (mounted) {
      setState(() {
        _showNextMonthHint = false;
        _showPrevMonthHint = false;
      });
    }

    if (!mounted || _isChangingMonth) {
      return false;
    }

    if (!_dateScrollController.hasClients) {
      return false;
    }

    final position = _dateScrollController.position;
    final pixels = position.pixels;
    final max = position.maxScrollExtent;
    final width = itemWidth; // getter 사용

    // 오른쪽 끝 근처에서 오버스크롤했을 때 → 다음 달
    // max를 넘어서 오버스크롤했거나, max 근처에서 스크롤이 끝났을 때 전환
    final nextMonthThreshold = width * _monthChangeOverScrollThreshold;
    if (pixels > max - nextMonthThreshold || pixels > max) {
      _navigateToNextMonth();
      return true; // 이벤트 소비
    }

    // 왼쪽 끝 근처에서 오버스크롤했을 때 → 이전 달
    // 0을 넘어서 오버스크롤했거나, 0 근처에서 스크롤이 끝났을 때 전환
    final prevMonthThreshold = width * _monthChangeOverScrollThreshold;
    if (pixels < prevMonthThreshold || pixels < 0) {
      _navigateToPreviousMonth();
      return true; // 이벤트 소비
    }

    return false; // 계속 전파
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
        // Stack 높이 = DateItem 전체 높이 (날짜 텍스트 + 간격 + 박스)
        // 날짜 텍스트: fontSize 11 * height 1.1 ≈ 12px, SizedBox: 3px
        // 힌트는 DateItem의 1:1 박스 기준 중앙에 정렬됩니다.
        SizedBox(
          height: itemWidth + 15, // 박스 높이 + 날짜 텍스트 높이(약 12px) + 간격(3px)
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: ListView.builder(
                  controller: _dateScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: LearningWidgetSpacing.getOuterPadding(context),
                  ),
                  itemExtent: itemWidth, // 카드 너비 (getter 사용)
                  itemCount: DateTime(
                    _currentMonth.year,
                    _currentMonth.month + 1,
                    0,
                  ).day,
                  itemBuilder: (context, index) {
                    // _currentMonth를 기준으로 날짜 생성
                    final date = DateTime(
                      _currentMonth.year,
                      _currentMonth.month,
                      index + 1,
                    );

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
                        nextDate.month == date.month &&
                        nextDate.year == date.year;

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
              // 힌트 표시 (오버레이)
              // 힌트는 DateItem의 1:1 박스 기준 중앙에 정렬됩니다.
              // 박스는 Stack 내에서 아래쪽에 위치하므로, top offset을 조정하여 박스 중앙에 맞춥니다.
              if (_showNextMonthHint)
                Positioned(
                  right: LearningWidgetSpacing.getOuterPadding(
                    context,
                  ), // ListView padding과 동일
                  top: 15, // 날짜 텍스트 + 간격 높이만큼 offset
                  child: SizedBox(
                    height: itemWidth, // 박스 높이와 동일
                    child: Center(
                      child: _buildMonthHint('더 드래그해서\n다음 달로', true),
                    ),
                  ),
                ),
              if (_showPrevMonthHint)
                Positioned(
                  left: LearningWidgetSpacing.getOuterPadding(
                    context,
                  ), // ListView padding과 동일
                  top: 15, // 날짜 텍스트 + 간격 높이만큼 offset
                  child: SizedBox(
                    height: itemWidth, // 박스 높이와 동일
                    child: Center(
                      child: _buildMonthHint('더 드래그해서\n이전 달로', false),
                    ),
                  ),
                ),
            ],
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
    // cardWidth는 itemWidth와 동일하게 설정 (통일)
    final cardWidth = itemWidth;

    // 박스 배경 (학습 완료 여부에 따라)
    // 로고 그라데이션: linear-gradient(121.67deg, #AC5BF8 19.64%, #636ACF 77.54%)
    final boxDecoration = isCompleted
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // 121.67deg ≈ 2.12 라디안
              // CSS: linear-gradient(121.67deg, #AC5BF8 19.64%, #636ACF 77.54%)
              colors: [
                Color(0xFFAC5BF8), // 19.64%
                Color(0xFF636ACF), // 77.54%
              ],
              stops: [0.1964, 0.7754],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFAC5BF8).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : BoxDecoration(
            color: const Color(0xFFE1E7ED), // 회색
            borderRadius: BorderRadius.circular(10),
          );

    // 날짜 텍스트 색상
    final dateColor = isSelected ? Colors.white : const Color(0xFF666666);

    // 책 아이콘 색상
    final bookIconColor = isCompleted ? Colors.white : const Color(0xFF7C3AED);

    return GestureDetector(
      onTap: () {
        // 날짜 탭 시: 같은 달만 바뀐다 → 월은 바꾸지 않고, 단순히 선택만 변경
        setState(() {
          _selectedDate = date;
        });
        if (widget.onDateSelected != null) {
          widget.onDateSelected!(date);
        }
        // 스크롤 애니메이션 제거: 날짜 선택 시 자동 스크롤하지 않음
      },
      child: SizedBox(
        width: cardWidth,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: LearningWidgetSpacing.getInnerPadding(context),
          ),
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
                      right: -LearningWidgetSpacing.getConnectorWidth(context),
                      top:
                          (cardWidth -
                              LearningWidgetSpacing.getConnectorWidth(
                                context,
                              )) /
                          2,
                      child: Container(
                        width: LearningWidgetSpacing.getConnectorWidth(context),
                        height: LearningWidgetSpacing.getConnectorWidth(
                          context,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
                            stops: [0.1964, 0.7754],
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
    final normalizedDate = DailyLearningStatus.normalizeDate(date);

    // 우선순위 1: dailyStatusMap 사용 (새 구조)
    if (widget.dailyStatusMap != null) {
      return widget.dailyStatusMap![normalizedDate]?.isCompleted ?? false;
    }

    // 우선순위 2: _currentMonthStatuses 사용 (UseCase 결과)
    if (_currentMonthStatuses != null) {
      return _currentMonthStatuses![normalizedDate]?.isCompleted ?? false;
    }

    // 우선순위 3: 기존 dateAssessments 사용 (하위 호환성, 추후 제거 예정)
    if (widget.dateAssessments != null) {
      final dateStr = _formatDate(date);
      final assessments = widget.dateAssessments![dateStr] ?? [];
      // 과제가 하나라도 있을 때, "모든 과제가 Y"인 날만 완료로 간주
      if (assessments.isEmpty) {
        return false;
      }
      return assessments.every((a) => a.assessStatus == 'Y');
    }

    // 우선순위 4: 기존 completedDates 사용 (하위 호환성, 추후 제거 예정)
    final dateStr = _formatDate(date);
    return widget.completedDates.contains(dateStr);
  }

  /// 월 전환 힌트 위젯 생성
  Widget _buildMonthHint(String text, bool isRight) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: isRight
            ? (_showNextMonthHint ? 1.0 : 0.0)
            : (_showPrevMonthHint ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LearningWidgetSpacing.hintOuterHorizontalPadding,
            vertical: LearningWidgetSpacing.hintOuterVerticalPadding,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: LearningWidgetSpacing.getHintInnerHorizontalPadding(
                context,
              ),
              vertical: LearningWidgetSpacing.getHintInnerVerticalPadding(
                context,
              ),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFAC5BF8).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAC5BF8).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
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
