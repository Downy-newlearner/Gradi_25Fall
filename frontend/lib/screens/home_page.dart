import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../widgets/app_header.dart';
import '../widgets/app_header_menu_button.dart';
import '../widgets/continuous_learning_widget_v2.dart';
import '../services/assessment_repository.dart';
import '../services/academy_service.dart';
import '../services/auth_service.dart';
import '../services/get_monthly_learning_status_use_case_impl.dart';
import '../services/learning_completion_service_impl.dart';
import '../services/grading_history_repository_impl.dart';
import '../domain/learning/get_monthly_learning_status_use_case.dart';
import '../models/assessment.dart';
import '../utils/academy_utils.dart';
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
  final AssessmentRepository _assessmentRepository = AssessmentRepository();
  final AcademyService _academyService = AcademyService();
  final AuthService _authService = AuthService();
  final Map<String, List<Assessment>> _dateAssessments = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingAssessments = false;

  // UseCase 인스턴스 (한 번만 생성)
  // 필드 초기화에서 생성하여 initState 전에 접근 가능하도록 보장
  final GetMonthlyLearningStatusUseCase _monthlyStatusUseCase = GetMonthlyLearningStatusUseCaseImpl(
    assessmentRepository: AssessmentRepository(),
    gradingHistoryRepository: GradingHistoryRepositoryImpl(),
    completionService: const LearningCompletionServiceImpl(),
  );

  // 숙제 완료 상태 관리 (UI 상태용)
  final Map<String, bool> _homeworkStatus = {};

  // 학원 상태 관리 (enum 사용)
  AcademyState _academyState = AcademyState.loading;
  String _academyName = '학원';
  List<UserAcademyResponse> _registeredAcademies = []; // 등록완료된 학원 목록

  // 헬퍼 getter
  bool get _hasAcademy => _academyState == AcademyState.ready;
  bool get _isCheckingAcademy => _academyState == AcademyState.loading;

  @override
  void initState() {
    super.initState();
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
    _homeworkStatus.clear();
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
    }
  }

  /// 학원명만 다시 로드 (외부에서 defaultAcademyCode가 변경된 경우에만 사용)
  ///
  /// 주의: 초기화 시에는 _initializeAcademyData를 사용하세요.
  /// 이 메서드는 "이미 초기화된 상태에서 코드만 바뀐 경우"에만 사용합니다.
  Future<void> _loadAcademyName() async {
    try {
      final academyCode = await _academyService.getDefaultAcademyCode();
      if (academyCode == null) {
        if (mounted) {
          setState(() {
            _academyState = AcademyState.none;
          });
        }
        return;
      }

      // 메모리 우선 확인 (null-aware 연산자 활용)
      UserAcademyResponse? academy = _registeredAcademies
          .where((a) => a.academyCode == academyCode)
          .firstOrNull;

      // 메모리에 없으면 캐시에서 찾기
      academy ??= await _academyService.getAcademyByCode(academyCode);

      if (academy != null && mounted) {
        setState(() {
          _academyName = academy!.academyName;
          // _academyState는 변경하지 않음 (이미 ready 상태일 것으로 가정)
        });
      }
    } catch (e) {
      developer.log('⚠️ 학원명 로드 실패: $e');
    }
  }

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

      // 다음 달 계산 (set 함수 사용)
      final nextMonthStart = _getNextMonth(currentMonthStart);

      // 캐시 초기화 (메모리 캐시와 SharedPreferences)
      await _assessmentRepository.clearAll();
      developer.log('🔄 [HomePage] Assessment 캐시 초기화 완료');

      // 현재 달과 다음 달 데이터를 병렬로 가져오기
      final results = await Future.wait([
        _assessmentRepository.getForMonth(
          academyId: userAcademyId,
          dateTime: currentMonthStart,
        ),
        _assessmentRepository.getForMonth(
          academyId: userAcademyId,
          dateTime: nextMonthStart,
        ),
      ]);

      // 두 달의 데이터를 합치기
      setState(() {
        _dateAssessments.addAll(results[0]);
        _dateAssessments.addAll(results[1]);
      });

      developer.log('✅ [HomePage] 이번 달과 다음 달 Assessment 데이터 로드 완료');
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

  /// 날짜 선택 시 호출
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    // 선택된 날짜의 데이터가 없으면 로드
    final dateStr = _formatDate(date);
    if (!_dateAssessments.containsKey(dateStr)) {
      _loadDateData(date);
    }
  }

  /// 특정 날짜 데이터 로드
  Future<void> _loadDateData(DateTime date) async {
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
      );

      setState(() {
        _dateAssessments[dateStr] = assessments;
      });
    } catch (e) {
      developer.log('⚠️ 날짜 데이터 로드 실패: $e');
      // 에러 발생 시 빈 리스트 설정
      setState(() {
        _dateAssessments[dateStr] = [];
      });
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
      if (assessments.any((a) => a.assessStatus == 'Y')) {
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
        return SingleChildScrollView(
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

    // 학원이 2개 이상일 때만 드롭다운 활성화
    final canShowDropdown = _registeredAcademies.length > 1;

    return AppHeader(
      titleAlignment: 'left',
      title: canShowDropdown
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
                      final statusKey = '$bookId-$index';
                      final isCompleted =
                          _homeworkStatus[statusKey] ??
                          (assessment.assessStatus == 'Y');

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
    // 선택된 날짜의 Assessment 데이터 가져오기
    final dateStr = _formatDate(_selectedDate);
    final assessments = _dateAssessments[dateStr] ?? [];

    // Assessment가 없으면 빈 상태 표시
    if (assessments.isEmpty) {
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

    // 완료된 Assessment 중 첫 번째 선택, 없으면 첫 번째 Assessment 사용
    Assessment? completedAssessment;
    try {
      completedAssessment = assessments.firstWhere(
        (a) => a.assessStatus == 'Y',
      );
    } catch (e) {
      // 완료된 것이 없으면 첫 번째 Assessment 사용
      completedAssessment = assessments.first;
    }

    // TODO: 실제 페이지 진행률 계산 (현재는 더미 데이터)
    const currentPage = 148;
    const totalPages = 300;
    const todayPages = 25;

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
            child: completedAssessment.bookCoverImage.startsWith('http')
                ? Image.network(
                    completedAssessment.bookCoverImage,
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
                : Image.asset(
                    completedAssessment.bookCoverImage,
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
                // 문제집명 (bookId 표시 또는 추후 bookName 필드 추가)
                Text(
                  '문제집 ${completedAssessment.bookId}',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),

                // 숙제 이름
                Text(
                  completedAssessment.assessName,
                  style: const TextStyle(
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
                  _formatAssessPage(completedAssessment.assessPage),
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '상태: ${_getStatusText(completedAssessment.assessStatus)}',
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

  String _getStatusText(String status) {
    // assessStatus는 'N' 또는 'Y'
    if (status == 'Y') {
      return '완료';
    } else if (status == 'N') {
      return '미완료';
    }
    return '알 수 없음';
  }
}
