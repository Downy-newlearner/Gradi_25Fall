import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/assessment_repository.dart';
import '../../services/academy_service.dart';
import '../../services/auth_service.dart';
import '../../utils/academy_utils.dart';
import '../../routes/app_routes.dart';
import '../../widgets/back_button.dart';
import '../../widgets/empty_state_message.dart';

enum HomeworkStatusViewState {
  loading,
  normal, // 숙제 목록 정상 표시
  noAcademy, // 학원이 하나도 없음
  error, // 기타 에러
}

/// 숙제 현황 페이지
/// 할당된 숙제 목록과 제출 현황을 보여주는 페이지
class HomeworkStatusPage extends StatefulWidget {
  const HomeworkStatusPage({super.key});

  @override
  State<HomeworkStatusPage> createState() => _HomeworkStatusPageState();
}

class _HomeworkStatusPageState extends State<HomeworkStatusPage> {
  final getIt = GetIt.instance;

  late final AssessmentRepository _assessmentRepository =
      getIt<AssessmentRepository>();
  late final AcademyService _academyService = getIt<AcademyService>();
  late final AuthService _authService = getIt<AuthService>();

  HomeworkStatusViewState _viewState = HomeworkStatusViewState.loading;
  String? _errorMessage;
  List<HomeworkItem> _homeworks = [];

  // Invariants:
  // - when _viewState == HomeworkStatusViewState.error, _errorMessage != null (best-effort)
  // - when _viewState == HomeworkStatusViewState.noAcademy, _homeworks is always empty

  @override
  Widget build(BuildContext context) {
    final pendingHomeworks = _homeworks.where((h) => !h.isCompleted).toList();
    final completedHomeworks = _homeworks.where((h) => h.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildBody(
                pendingHomeworks: pendingHomeworks,
                completedHomeworks: completedHomeworks,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required List<HomeworkItem> pendingHomeworks,
    required List<HomeworkItem> completedHomeworks,
  }) {
    if (_viewState == HomeworkStatusViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewState == HomeworkStatusViewState.error) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: EmptyStateMessage(
            icon: Icons.error_outline,
            title: '숙제 정보를 불러오지 못했습니다.',
            description: _errorMessage,
            primaryActionLabel: '다시 시도',
            onPrimaryAction: _loadAssessments,
          ),
        ),
      );
    }

    if (_viewState == HomeworkStatusViewState.noAcademy) {
      return const Center(
        child: EmptyStateMessage.academy(
          title: '등록된 학원이 없어요.',
          description: '마이페이지에서 학원을 먼저 등록해주세요.',
        ),
      );
    }

    // 여기까지 왔으면 normal 상태
    if (_homeworks.isEmpty) {
      return const Center(
        child: EmptyStateMessage.homework(
          title: '등록된 숙제가 없어요.',
        ),
      );
    }

    return SingleChildScrollView(
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

    return GestureDetector(
      onTap: () => _navigateToHomeDate(homework.dueDate),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: homework.isCompleted ? const Color(0xFFF8F9FA) : Colors.white,
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
      ),
    );
  }

  void _navigateToHomeDate(DateTime dueDate) {
    final targetDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.mainNavigation,
      (route) => false,
      arguments: {'targetDate': _formatRouteDate(targetDate)},
    );
  }

  String _formatRouteDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _viewState = HomeworkStatusViewState.loading;
      _errorMessage = null;
    });

    try {
      final defaultAcademyCode = await _academyService.getDefaultAcademyCode();
      if (defaultAcademyCode == null) {
        throw Exception('디폴트 학원을 찾을 수 없습니다.');
      }

      String? userAcademyId = await getUserAcademyId(
        academyService: _academyService,
        academyCode: defaultAcademyCode,
      );
      if (userAcademyId == null) {
        final userId = await _authService.getUserId();
        if (userId != null) {
          try {
            final academies = await _academyService.getUserAcademies(userId);
            if (academies.isNotEmpty) {
              await _academyService.saveAcademiesToCache(academies);
              userAcademyId = await getUserAcademyId(
                academyService: _academyService,
                academyCode: defaultAcademyCode,
                registeredAcademies: academies
                    .where((academy) => academy.registerStatus == 'Y')
                    .toList(),
              );
            }
          } catch (e) {
            print('[HomeworkStatusPage] 학원 목록 갱신 실패: $e');
          }
        }
      }
      if (userAcademyId == null) {
        // 등록된 학원이 전혀 없는 경우
        setState(() {
          _viewState = HomeworkStatusViewState.noAcademy;
          _homeworks = [];
        });
        return;
      }

      final now = DateTime.now();
      final monthStart = DateTime.utc(now.year, now.month, 1);
      print(
        '[HomeworkStatusPage] 숙제 데이터 조회 시작 | 학원 코드: $defaultAcademyCode, 학원 사용자 ID: $userAcademyId, 기준 월: $monthStart',
      );
      final data = await _assessmentRepository.getForMonth(
        academyId: userAcademyId,
        dateTime: monthStart,
      );
      print('[HomeworkStatusPage] 레포지토리에서 ${data.length}개의 날짜 데이터를 수신');

      final mapped = <HomeworkItem>[];
      data.forEach((dateString, assessments) {
        final parsedDate = DateTime.tryParse(dateString);
        final dueDate = parsedDate ?? DateTime.now();

        for (final assessment in assessments) {
          mapped.add(
            HomeworkItem(
              title: assessment.assessName,
              dueDate: dueDate,
              isCompleted: assessment.assessStatus.toUpperCase() == 'Y',
              assignedBy: assessment.assessClass.isNotEmpty
                  ? assessment.assessClass
                  : '담당 선생님 미지정',
            ),
          );
        }
      });
      mapped.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      setState(() {
        _homeworks = mapped;
        _viewState = HomeworkStatusViewState.normal;
      });
    } catch (e) {
      print('[HomeworkStatusPage] 숙제 데이터를 불러오지 못했습니다: $e');
      setState(() {
        _errorMessage = e.toString();
        _viewState = HomeworkStatusViewState.error;
      });
    }
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
