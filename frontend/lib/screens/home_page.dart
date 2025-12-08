import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../routes/app_routes.dart';
import '../widgets/app_header.dart';
import '../widgets/app_header_menu_button.dart';
import '../widgets/continuous_learning_widget_v2.dart';
import '../services/assessment_repository.dart';
import '../services/academy_service.dart';
import '../services/auth_service.dart';
import '../services/daily_learning_service.dart';
import '../domain/learning/get_monthly_learning_status_use_case.dart';
import '../models/assessment.dart';
import '../utils/academy_utils.dart';
import '../utils/app_logger.dart';
import 'dart:developer' as developer;

/// 홈 화면 - 개선된 UI/UX
///
/// 주요 기능:
/// 1. 연속학습 위젯 - 날짜 기반 스와이프 캘린더
/// 2. 오늘의 숙제 - 문제집 표지 + 상세 정보 카드
/// 3. 누적 학습량 - 2단계 프로그레스 바

/// 학원 상태 enum
enum AcademyState {
  loading, // 초기화 중
  none, // 학원 없음
  ready, // 학원 있음, 데이터 로드 완료
  error, // 에러 발생
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GetIt _getIt = GetIt.instance;

  late final AssessmentRepository _assessmentRepository;
  late final AcademyService _academyService;
  late final AuthService _authService;
  final Map<String, List<Assessment>> _dateAssessments = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingAssessments = false;

  // UseCase 인스턴스 (DI에서 주입)
  late final GetMonthlyLearningStatusUseCase _monthlyStatusUseCase;

  // 학원 상태 관리 (enum 사용)
  AcademyState _academyState = AcademyState.loading;
  String _academyName = '학원';
  List<UserAcademyResponse> _registeredAcademies = []; // 등록완료된 학원 목록

  // 선택된 날짜의 학습 데이터
  DailyLearningResult? _selectedDateLearningResult;
  bool _isLoadingSelectedDateLearning = false;

  @override
  void initState() {
    super.initState();
    _assessmentRepository = _getIt<AssessmentRepository>();
    _academyService = _getIt<AcademyService>();
    _authService = _getIt<AuthService>();
    _monthlyStatusUseCase = _getIt<GetMonthlyLearningStatusUseCase>();
    _academyService.defaultAcademyVersion.addListener(_onDefaultAcademyChanged);
    // 단일 진입점만 호출
    _initializeAcademyData(forceRefresh: false);
  }

  @override
  void dispose() {
    _academyService.defaultAcademyVersion.removeListener(
      _onDefaultAcademyChanged,
    );
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 페이지에서 돌아올 때 강제 새로고침
    _initializeAcademyData(forceRefresh: true);
  }

  /// 오늘의 숙제 정보 동기화
  /// 다른 페이지에서 돌아올 때 선택된 날짜의 Assessment 데이터를 최신 정보로 갱신
  Future<void> _synchronizeTodayHomework() async {
    if (_academyState != AcademyState.ready) return;

    // _loadDateData를 forceRefresh로 호출하여 최신 데이터 가져오기
    await _loadDateData(_selectedDate, forceRefresh: true);
  }

  /// 외부에서 호출 가능한 새로고침 메서드
  /// 탭 전환 시 MainNavigationPage에서 호출
  void refresh() {
    developer.log('🔄 [HomePage] refresh() called from external');
    _initializeAcademyData(forceRefresh: true);
  }

  /// 외부에서 특정 날짜를 열도록 요청할 때 사용
  void focusOnDate(DateTime date) {
    developer.log('🎯 [HomePage] focusOnDate 요청: $date');
    final normalized = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDate = normalized;
    });
    _loadDateData(normalized);
  }

  void _onDefaultAcademyChanged() {
    if (!mounted) return;
    developer.log('🔁 [HomePage] 디폴트 학원 변경 감지, 데이터 재초기화');
    _dateAssessments.clear();
    _initializeAcademyData(forceRefresh: true);
  }

  /// 학원 관련 전체 초기화 (단일 진입점)
  ///
  /// 모든 학원 관련 로직의 진입점:
  /// - initState에서 호출
  /// - didChangeDependencies에서 호출
  /// - 수동 새로고침 시 호출
  Future<void> _initializeAcademyData({bool forceRefresh = false}) async {
    // 1. 상태 초기화 (항상 명시적으로)
    if (mounted) {
      setState(() {
        _academyState = AcademyState.loading;
      });
    }

    try {
      // 2. 학원 목록 로드 (API or 캐시)
      List<UserAcademyResponse>? academies;

      if (forceRefresh) {
        // API 호출
        final userId = await _authService.getUserId();
        if (userId == null) {
          developer.log('⚠️ 사용자 ID를 가져올 수 없습니다.');
          // 사용자 ID 없음 → 캐시에서 로드
          academies = await _academyService.loadAcademiesFromCache();
        } else {
          try {
            academies = await _academyService.getUserAcademies(userId);
          } catch (e) {
            developer.log('⚠️ API 호출 실패, 캐시에서 로드 시도: $e');
            academies = await _academyService.loadAcademiesFromCache();
          }
        }
      } else {
        // 캐시에서만 로드
        academies = await _academyService.loadAcademiesFromCache();
      }

      // 3. early return 시 상태 정리 (명시적으로)
      if (academies == null) {
        if (mounted) {
          setState(() {
            _academyState = AcademyState.none;
            _registeredAcademies = [];
          });
        }
        return;
      }

      // 4. 학원 목록 처리
      await _processAcademyList(academies, shouldSaveCache: forceRefresh);
    } catch (e) {
      developer.log('❌ 학원 정보 초기화 실패: $e');
      if (mounted) {
        setState(() {
          _academyState = AcademyState.error;
          _registeredAcademies = [];
        });

        // 사용자 피드백
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('학원 정보를 불러오는데 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => _initializeAcademyData(forceRefresh: true),
            ),
          ),
        );
      }
    }
  }

  /// 학원 목록 처리 (캐시 저장 + 필터링 + 디폴트 학원 설정)
  ///
  /// [academies]: 전체 학원 목록 (registerStatus 'Y'/'P' 모두 포함)
  /// [shouldSaveCache]: 캐시에 저장할지 여부 (API에서 가져온 경우만 true)
  Future<void> _processAcademyList(
    List<UserAcademyResponse> academies, {
    required bool shouldSaveCache,
  }) async {
    // 1. 캐시 저장 (mounted와 무관하게 실행)
    if (shouldSaveCache) {
      await _academyService.saveAcademiesToCache(academies);
    }

    // 2. mounted 체크 (UI 업데이트 전에만)
    if (!mounted) return;

    // 3. 등록완료된 학원만 필터링
    final registeredAcademies = academies
        .where((academy) => academy.registerStatus == 'Y')
        .toList();

    setState(() {
      _registeredAcademies = registeredAcademies;
    });

    // 4. 디폴트 학원 설정
    if (registeredAcademies.isNotEmpty) {
      await _setupDefaultAcademy(registeredAcademies);
    } else {
      // 등록완료된 학원이 없음
      setState(() {
        _academyState = AcademyState.none;
      });
    }
  }

  /// 디폴트 학원 설정 및 관련 데이터 로드
  ///
  /// [academies]: 등록완료된 학원 목록 (registerStatus == 'Y')
  Future<void> _setupDefaultAcademy(List<UserAcademyResponse> academies) async {
    if (!mounted) return;

    // 1. 디폴트 학원 선택
    final defaultAcademyCode = await _academyService.selectDefaultAcademyAsync(
      academies,
    );

    if (defaultAcademyCode == null) {
      // 디폴트 학원을 선택할 수 없음 (로직 오류 가능성)
      developer.log('⚠️ 디폴트 학원 선택 실패: 학원 목록은 있지만 선택할 수 없음');
      if (mounted) {
        setState(() {
          _academyState = AcademyState.error;
          // _registeredAcademies는 유지 (디버깅용)
        });
      }
      return;
    }

    // 2. 디폴트 학원 저장
    await _academyService.saveDefaultAcademyCode(defaultAcademyCode);

    // 3. 학원명 설정 (메모리에서 찾기)
    final academy = academies.firstWhere(
      (a) => a.academyCode == defaultAcademyCode,
      orElse: () => academies.first, // fallback
    );

    if (mounted) {
      setState(() {
        _academyName = academy.academyName;
        _academyState = AcademyState.ready;
      });

      // 4. Assessment 데이터 로드
      await _loadRemainingMonthData();

      // 5. 선택된 날짜의 학습 데이터 로드
      await _loadSelectedDateLearningData(_selectedDate);

      // 6. 오늘의 숙제 정보 동기화 (최신 정보로 갱신)
      await _synchronizeTodayHomework();
    }
  }

  // _loadAcademyName, _hasAcademy, _isCheckingAcademy는
  // 이전 구조에서 사용되었으나 현재 로직에서는 사용되지 않아 제거했습니다.

  /// 이번 달과 다음 달 데이터 로드
  ///
  /// 변경: 월 단위로 데이터를 가져오도록 수정
  Future<void> _loadRemainingMonthData() async {
    if (_isLoadingAssessments) return;

    // 학원이 없으면 Assessment 호출 건너뛰기
    if (_academyState != AcademyState.ready) {
      developer.log('⚠️ 학원이 없어 Assessment 데이터 로드를 건너뜀');
      return;
    }

    setState(() {
      _isLoadingAssessments = true;
    });

    try {
      final userAcademyId = await getUserAcademyId(
        academyService: _academyService,
        registeredAcademies: _registeredAcademies,
      );

      // 학원 ID가 없으면 건너뛰기
      if (userAcademyId == null) {
        developer.log('⚠️ 학원 ID가 없어 Assessment 데이터 로드를 건너뜀');
        return;
      }

      final now = DateTime.now();

      // 현재 달의 첫 번째 날 (UTC)
      final currentMonthStart = DateTime.utc(now.year, now.month, 1);

      // 이전/다음 달 계산 (set 함수 사용)
      final previousMonthStart = _getPreviousMonth(currentMonthStart);
      final nextMonthStart = _getNextMonth(currentMonthStart);

      // 캐시 초기화 (메모리 캐시와 SharedPreferences)
      await _assessmentRepository.clearAll();
      developer.log('🔄 [HomePage] Assessment 캐시 초기화 완료');

      // 이전 달, 현재 달, 다음 달 데이터를 병렬로 가져오기
      final results = await Future.wait([
        _assessmentRepository.getForMonth(
          academyId: userAcademyId,
          dateTime: previousMonthStart,
        ),
        _assessmentRepository.getForMonth(
          academyId: userAcademyId,
          dateTime: currentMonthStart,
        ),
        _assessmentRepository.getForMonth(
          academyId: userAcademyId,
          dateTime: nextMonthStart,
        ),
      ]);

      // 세 달의 데이터를 합치기
      setState(() {
        _dateAssessments.addAll(results[0]); // 이전 달
        _dateAssessments.addAll(results[1]); // 현재 달
        _dateAssessments.addAll(results[2]); // 다음 달
      });

      developer.log('✅ [HomePage] 이전/이번/다음 달 Assessment 데이터 로드 완료');
      developer.log('📊 [HomePage] 현재 _dateAssessments 상태:');

      _dateAssessments.forEach((date, assessments) {
        developer.log('[HomePage]  - $date: ${assessments.length}개 과제');
        for (var assessment in assessments) {
          developer.log(
            '[HomePage]    • ${assessment.assessName} (${assessment.assessClass}) - 상태: ${assessment.assessStatus}',
          );
        }
      });
    } catch (e) {
      developer.log('⚠️ 이번 달 남은 날짜 데이터 로드 실패: $e');
    } finally {
      setState(() {
        _isLoadingAssessments = false;
      });
    }
  }

  /// 다음 달 계산 헬퍼 함수
  DateTime _getNextMonth(DateTime dateTime) {
    if (dateTime.month == 12) {
      return DateTime.utc(dateTime.year + 1, 1, 1);
    } else {
      return DateTime.utc(dateTime.year, dateTime.month + 1, 1);
    }
  }

  /// 이전 달 계산 헬퍼 함수
  DateTime _getPreviousMonth(DateTime dateTime) {
    if (dateTime.month == 1) {
      return DateTime.utc(dateTime.year - 1, 12, 1);
    } else {
      return DateTime.utc(dateTime.year, dateTime.month - 1, 1);
    }
  }

  /// 날짜 선택 시 호출
  /// 연속학습 위젯에서 날짜를 클릭하면 이 메서드가 호출됩니다
  void _onDateSelected(DateTime date) {
    final dateStr = _formatDate(date);
    appLog('[continuous_learning:home_page] 날짜 선택됨 - $dateStr (연속학습 위젯에서 클릭)');

    setState(() {
      _selectedDate = date;
    });

    // 날짜 선택 시 항상 최신 데이터로 동기화
    _loadDateData(date, forceRefresh: true);

    // 선택된 날짜의 학습 데이터 로드
    _loadSelectedDateLearningData(date);
  }

  /// 특정 날짜 데이터 로드
  ///
  /// [date]: 로드할 날짜
  /// [forceRefresh]: true면 캐시를 무시하고 서버에서 최신 데이터를 가져옵니다
  Future<void> _loadDateData(DateTime date, {bool forceRefresh = false}) async {
    final dateStr = _formatDate(date);

    // 학원이 없으면 건너뛰기
    if (_academyState != AcademyState.ready) {
      return;
    }

    try {
      final userAcademyId = await getUserAcademyId(
        academyService: _academyService,
        registeredAcademies: _registeredAcademies,
      );

      // 학원 ID가 없으면 빈 리스트 설정
      if (userAcademyId == null) {
        setState(() {
          _dateAssessments[dateStr] = [];
        });
        return;
      }

      final assessments = await _assessmentRepository.getForDate(
        academyId: userAcademyId,
        date: dateStr,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _dateAssessments[dateStr] = assessments;
      });

      if (forceRefresh) {
        developer.log(
          '✅ [HomePage] 날짜 데이터 강제 새로고침 완료: $dateStr - ${assessments.length}개 과제',
        );
      }
    } catch (e) {
      developer.log('⚠️ 날짜 데이터 로드 실패: $e');
      // 에러 발생 시 빈 리스트 설정
      setState(() {
        _dateAssessments[dateStr] = [];
      });
    }
  }

  /// 선택된 날짜의 학습 데이터 로드
  ///
  /// [date]: 조회할 날짜 (어떤 타임존이든 상관없음, KST로 변환됨)
  /// 기기 타임존과 무관하게 항상 KST 기준으로 조회됩니다.
  Future<void> _loadSelectedDateLearningData(DateTime date) async {
    if (_isLoadingSelectedDateLearning) return;
    if (_academyState != AcademyState.ready) return;

    // setState 한 번만 호출
    setState(() {
      _isLoadingSelectedDateLearning = true;
      _selectedDateLearningResult = null; // 이전 결과 초기화
    });

    try {
      final learningService = _getIt<DailyLearningService>();
      final result = await learningService.getDailyLearningData(date);

      // setState 한 번만 호출 (성공/실패 모두)
      if (mounted) {
        setState(() {
          _selectedDateLearningResult = result;
          _isLoadingSelectedDateLearning = false;
        });
      }
    } catch (e) {
      developer.log('⚠️ 선택된 날짜의 학습 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          _selectedDateLearningResult = DailyLearningResult.error(
            '데이터를 불러오는데 실패했습니다.',
          );
          _isLoadingSelectedDateLearning = false;
        });
      }
    }
  }

  /// 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 선택된 날짜의 완료된 날짜 Set 계산
  Set<String> _getCompletedDates() {
    final completedDates = <String>[];
    _dateAssessments.forEach((date, assessments) {
      // 과제가 하나라도 있을 때, "모든 과제가 Y"인 날만 완료로 간주
      if (assessments.isNotEmpty &&
          assessments.every((a) => a.assessStatus == 'Y')) {
        completedDates.add(date);
      }
    });
    return completedDates.toSet();
  }

  /// 선택된 날짜의 숙제 마감일 Set 계산
  Set<String> _getHomeworkDeadlines() {
    final deadlines = <String>[];
    _dateAssessments.forEach((date, assessments) {
      if (assessments.isNotEmpty) {
        deadlines.add(date);
      }
    });
    return deadlines.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(screenHeight)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(double screenHeight) {
    switch (_academyState) {
      case AcademyState.loading:
        return const Center(child: CircularProgressIndicator());

      case AcademyState.none:
        return _buildNoAcademyState();

      case AcademyState.error:
        return _buildErrorState();

      case AcademyState.ready:
        return RefreshIndicator(
          onRefresh: () async {
            await _initializeAcademyData(forceRefresh: true);
          },
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Pull-to-refresh를 위해 항상 스크롤 가능하도록
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.0297), // 26px → 2.97%
                ContinuousLearningWidgetV2(
                  consecutiveDays: _getConsecutiveDays(),
                  homeworkDeadlines: _getHomeworkDeadlines(),
                  onDateSelected: _onDateSelected,
                  selectedDate: _selectedDate,
                  // 새 구조: UseCase 사용
                  monthlyStatusUseCase: _monthlyStatusUseCase,
                  // 하위 호환성 (추후 제거 예정)
                  completedDates: _getCompletedDates(),
                  dateAssessments: _dateAssessments,
                ),
                SizedBox(height: screenHeight * 0.0297), // 26px → 2.97%
                _buildTodayHomeworkSection(),
                SizedBox(height: screenHeight * 0.0297), // 26px → 2.97%
                _buildAccumulatedLearningSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 24),
            const Text(
              '학원 정보를 불러올 수 없습니다',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _initializeAcademyData(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAC5BF8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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

    // 학원이 정상적으로 설정된 상태인지 여부
    final hasAcademy =
        _academyState == AcademyState.ready && _registeredAcademies.isNotEmpty;

    // 학원이 2개 이상일 때만 드롭다운 활성화 (단, 학원이 있을 때만)
    final canShowDropdown = hasAcademy && _registeredAcademies.length > 1;

    return AppHeader(
      titleAlignment: hasAcademy ? 'left' : 'center',
      title: !hasAcademy
          // 학원이 없을 때는 학원 이름("Gradi 학원" 등)을 표시하지 않고
          // 단순히 홈 타이틀만 표시
          ? const Text(
              '홈',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF333333),
              ),
            )
          : canShowDropdown
          ? PopupMenuButton<String>(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _academyName,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: const Color(0xFF333333),
                    size: iconSize,
                  ),
                ],
              ),
              itemBuilder: (context) {
                return _registeredAcademies.map((academy) {
                  return PopupMenuItem<String>(
                    value: academy.academyCode,
                    child: FutureBuilder<String?>(
                      future: _academyService.getDefaultAcademyCode(),
                      builder: (context, snapshot) {
                        final currentAcademyCode = snapshot.data;
                        final isSelected =
                            academy.academyCode == currentAcademyCode;

                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                academy.academyName,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFFAC5BF8)
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: Color(0xFFAC5BF8),
                                size: 20,
                              ),
                          ],
                        );
                      },
                    ),
                  );
                }).toList();
              },
              onSelected: (academyCode) {
                _onAcademySelected(academyCode);
              },
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _academyName,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color(0xFF333333),
                  size: iconSize,
                ),
              ],
            ),
      trailing: const AppHeaderMenuButton(),
    );
  }

  /// 학원 선택 시 호출 (드롭다운에서 선택)
  Future<void> _onAcademySelected(String academyCode) async {
    try {
      // 디폴트 학원 저장
      await _academyService.saveDefaultAcademyCode(academyCode);

      // 메모리에서 학원 찾기
      final academy = _registeredAcademies.firstWhere(
        (a) => a.academyCode == academyCode,
      );

      if (mounted) {
        setState(() {
          _academyName = academy.academyName;
          // _academyState는 ready 유지
        });

        // Assessment 데이터 다시 로드
        _dateAssessments.clear();
        await _loadRemainingMonthData();

        // 오늘의 숙제 정보 동기화
        await _synchronizeTodayHomework();

        developer.log('✅ 학원 변경 완료: ${academy.academyName}');
      }
    } catch (e) {
      developer.log('⚠️ 학원 선택 처리 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('학원 변경에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 학원이 없을 때 표시할 안내 위젯
  Widget _buildNoAcademyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 64,
              color: Color(0xFFADADAD),
            ),
            const SizedBox(height: 24),
            const Text(
              '학원을 등록해주세요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '학원을 등록하면 숙제와 학습 정보를\n확인할 수 있습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/academy/list');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAC5BF8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                '학원 등록하기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
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
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.homeworkStatus);
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
              ),
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
    // 메서드 호출 여부 확인
    developer.log('🔵 [HomePage] _buildHomeworkList() 호출됨');
    developer.log('🔵 [HomePage] _academyState: $_academyState');

    // 학원이 없을 때 안내 표시
    if (_academyState != AcademyState.ready) {
      developer.log('⚠️ [HomePage] _academyState가 ready가 아님. early return');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border.all(color: const Color(0xFFE1E7ED)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            '학원을 등록해주세요',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ),
      );
    }

    // 선택된 날짜의 Assessment 데이터 가져오기
    final dateStr = _formatDate(_selectedDate);
    final assessments = _dateAssessments[dateStr] ?? [];

    developer.log('📋 [HomePage] 선택된 날짜: $dateStr');
    developer.log('📋 [HomePage] 선택된 날짜의 과제 수: ${assessments.length}');
    developer.log(
      '📋 [HomePage] 선택된 날짜의 과제 목록: ${assessments.map((e) => e.assessName).toList()}',
    );
    developer.log(
      '📋 [HomePage] _dateAssessments 전체 키: ${_dateAssessments.keys.toList()}',
    );

    for (var assessment in assessments) {
      developer.log('📋 [HomePage] 과제 이름: ${assessment.assessName}');
      developer.log('📋 [HomePage] 과제 클래스: ${assessment.assessClass}');
      developer.log('📋 [HomePage] 과제 상태: ${assessment.assessStatus}');
      developer.log('📋 [HomePage] 과제 페이지: ${assessment.assessPage}');
      developer.log('📋 [HomePage] 과제 썸네일: ${assessment.bookCoverImage}');
    }

    if (assessments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border.all(color: const Color(0xFFE1E7ED)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            '해당 날짜에 숙제가 없습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ),
      );
    }

    // Assessment를 클래스명으로 먼저 그룹화, 그 다음 bookId로 그룹화
    final Map<String, Map<String, List<Assessment>>> groupedByClass = {};
    for (var assessment in assessments) {
      // 클래스명이 없으면 학원 이름 사용
      final className = assessment.assessClass.isNotEmpty
          ? assessment.assessClass
          : _academyName;

      if (!groupedByClass.containsKey(className)) {
        groupedByClass[className] = {};
      }

      final classGroup = groupedByClass[className]!;
      if (!classGroup.containsKey(assessment.bookId)) {
        classGroup[assessment.bookId] = [];
      }
      classGroup[assessment.bookId]!.add(assessment);
    }

    // 각 클래스별로 섹션 생성
    return Column(
      children: groupedByClass.entries.map((classEntry) {
        final className = classEntry.key;
        final bookGroups = classEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 클래스명 헤더
            Padding(
              padding: EdgeInsets.only(
                bottom: 12,
                top: classEntry == groupedByClass.entries.first ? 0 : 20,
              ),
              child: Text(
                className,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            // 각 문제집별로 카드 생성
            ...bookGroups.entries.map((entry) {
              final bookId = entry.key;
              final bookAssessments = entry.value;

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
                    // 문제집별 Assessment 목록
                    ...bookAssessments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final assessment = entry.value;
                      // 항상 서버에서 가져온 최신 상태를 사용
                      final isCompleted = assessment.assessStatus == 'Y';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildWorkbookItemFromAssessment(
                          assessment,
                          bookId,
                          index,
                          isCompleted,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  /// assessPage를 "P.15~P.25" 형식으로 변환
  String _formatAssessPage(String assessPage) {
    if (assessPage.isEmpty || !assessPage.contains('-')) {
      return assessPage;
    }

    final parts = assessPage.split('-');
    if (parts.length == 2) {
      final startPage = parts[0].trim();
      final endPage = parts[1].trim();
      return 'P.$startPage~P.$endPage';
    }

    return assessPage;
  }

  /// 문제집 아이템 (Assessment 기반)
  Widget _buildWorkbookItemFromAssessment(
    Assessment assessment,
    String bookId,
    int index,
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
          child: assessment.bookCoverImage.startsWith('http')
              ? Image.network(
                  assessment.bookCoverImage,
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
                )
              : Image.asset(
                  assessment.bookCoverImage,
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

        // 챕터 + 페이지 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                assessment.assessName,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatAssessPage(assessment.assessPage),
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

        // 체크박스 (사용자 조작 불가, assessStatus에 따라 자동으로 표시됨)
        Container(
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
              ? Icon(Icons.check, size: screenWidth * 0.04, color: Colors.white)
              : null,
        ),
      ],
    );
  }

  /// 오늘의 학습 섹션
  Widget _buildAccumulatedLearningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '오늘의 학습',
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
    // 로딩 중
    if (_isLoadingSelectedDateLearning) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border.all(color: const Color(0xFFE1E7ED)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 결과가 없음
    if (_selectedDateLearningResult == null) {
      return const SizedBox.shrink();
    }

    // 에러 상태
    if (_selectedDateLearningResult!.hasError) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border.all(color: const Color(0xFFE1E7ED)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 8),
            Text(
              _selectedDateLearningResult!.errorMessage ?? '데이터를 불러오는데 실패했습니다.',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFFF6B6B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 빈 상태 (학습 기록 없음)
    if (!_selectedDateLearningResult!.hasData) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border.all(color: const Color(0xFFE1E7ED)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            '해당 날짜에 학습 기록이 없습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ),
      );
    }

    // 데이터 있음 - 가장 많이 학습한 책 선택
    final books = DailyLearningService.extractBooks(
      _selectedDateLearningResult!,
    );
    final selectedBook = DailyLearningService.selectMostLearnedBook(books);

    if (selectedBook == null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border.all(color: const Color(0xFFE1E7ED)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            '학습 데이터를 표시할 수 없습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ),
      );
    }

    // Progress 계산
    final progress = selectedBook.bookPage > 0
        ? selectedBook.totalSolvedPages / selectedBook.bookPage
        : 0.0;

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
            child:
                selectedBook.bookImageUrl != null &&
                    selectedBook.bookImageUrl!.startsWith('http')
                ? Image.network(
                    selectedBook.bookImageUrl!,
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
                  )
                : Container(
                    width: thumbnailWidth,
                    height: thumbnailHeight,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.book,
                      color: Colors.grey,
                      size: thumbnailWidth * 0.57,
                    ),
                  ),
          ),
          const SizedBox(width: 15),

          // 학습 정보 및 프로그레스
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 문제집명
                Text(
                  selectedBook.bookName ?? '문제집 ${selectedBook.bookId}',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),

                // 프로그레스 바
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
                        // 진행률 (보라색)
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
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
                  '${selectedBook.totalSolvedPages} / ${selectedBook.bookPage} 페이지',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF333333),
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
    final completedDates = _getCompletedDates();
    if (completedDates.isEmpty) return 0;

    final completedSet = completedDates.toSet();
    DateTime today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);

    final todayKey = _formatDate(cursor);
    if (!completedSet.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (true) {
      final key = _formatDate(cursor);
      if (!completedSet.contains(key)) {
        break;
      }
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
