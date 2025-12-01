import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_header_title.dart';
import '../../widgets/back_button.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/academy_service.dart';
import '../../services/grading_history_repository_impl.dart';
import '../../domain/grading_history/grading_history_entity.dart';
import '../../config/app_dependencies.dart';
import 'edit_grading_result_page.dart';
import 'models/grading_history_item.dart';
import '../../utils/app_logger.dart';
import 'dart:developer' as developer;

/// 채점 히스토리 페이지
/// 사용자가 지금까지 채점한 모든 기록을 시간순으로 표시하는 페이지
///
/// 구성:
/// 1. 헤더: "채점 히스토리" 타이틀
/// 2. 채점 기록 목록: 날짜별 그룹핑, 문제집명, 클래스명, 페이지 범위, 채점 시간 등
class GradingHistoryPage extends StatefulWidget {
  const GradingHistoryPage({super.key});

  @override
  State<GradingHistoryPage> createState() => _GradingHistoryPageState();
}

class _GradingHistoryPageState extends State<GradingHistoryPage> {
  bool _isLoading = false;
  List<GradingHistoryItem> _historyItems = [];
  String? _errorMessage;

  // Services
  final AuthService _authService = AuthService();
  final AcademyService _academyService = AcademyService();
  final GradingHistoryRepositoryImpl _repository =
      GradingHistoryRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadGradingHistory();
  }

  /// 채점 히스토리 데이터 로드
  Future<void> _loadGradingHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. userId로 academyUserIds 조회
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }

      if (!mounted) return;

      final academies = await _academyService.getUserAcademies(userId);
      final academyUserIds = academies
          .where((a) => a.registerStatus == 'Y')
          .map((a) => a.academy_user_id)
          .whereType<int>()
          .toList();

      if (academyUserIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _historyItems = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Repository 호출 (Map<int, List<Entity>> 반환)
      final historiesMap = await _repository
          .getGradingHistoriesByAcademyUserIds(academyUserIds);

      if (!mounted) return;

      // 3. Map을 flat 리스트로 변환
      final allEntities = <GradingHistoryEntity>[];
      historiesMap.values.forEach((entities) {
        allEntities.addAll(entities);
      });

      // 4. 날짜순 정렬 (최신순) - UI 레이어에서 처리
      allEntities.sort((a, b) => b.gradingDate.compareTo(a.gradingDate));

      // 5. UI 모델로 변환
      final items = allEntities
          .map((entity) => GradingHistoryItem.fromEntity(entity))
          .toList();

      if (!mounted) return;

      setState(() {
        _historyItems = items;
        _isLoading = false;
      });
    } catch (e, stack) {
      // 상세 로그는 appLog/developer.log로만 남김
      appLog('[grading_history:grading_history_page] load error: $e\n$stack');
      developer.log('❌ [GradingHistoryPage] load error: $e\n$stack');

      if (!mounted) return;

      setState(() {
        // 사용자용 간단한 메시지만 표시
        _errorMessage = '채점 히스토리를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.';
        _isLoading = false;
      });
    }
  }

  /// 날짜별로 그룹핑
  Map<String, List<GradingHistoryItem>> _groupByDate(
    List<GradingHistoryItem> items,
  ) {
    final Map<String, List<GradingHistoryItem>> grouped = {};

    for (final item in items) {
      final dateKey = _formatDateKey(item.gradingDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    // 각 날짜 그룹 내에서 시간순 정렬 (최신순)
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.gradingDate.compareTo(a.gradingDate));
    }

    return grouped;
  }

  /// 날짜 키 포맷팅 (예: "2025년 11월 29일")
  String _formatDateKey(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  /// 날짜 헤더 포맷팅
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return '오늘';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return '어제';
    } else {
      return _formatDateKey(date);
    }
  }

  /// 시간을 한국어 오전/오후 형식으로 포맷팅
  /// 예: "오전 9:32", "오후 2:15"
  String _formatTimeToKoreanAmPm(DateTime date) {
    final isAm = date.hour < 12;
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final prefix = isAm ? '오전' : '오후';
    return '$prefix $hour12:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.whiteColor,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            AppHeader(
              leading: const CustomBackButton(),
              title: const AppHeaderTitle('채점 히스토리'),
            ),

            // 채점 히스토리 목록
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _historyItems.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            '채점 히스토리를 불러오는데 실패했습니다',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '알 수 없는 오류',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _loadGradingHistory();
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            '채점 기록이 없습니다',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 채점 히스토리 리스트
  Widget _buildHistoryList() {
    final grouped = _groupByDate(_historyItems);
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) {
        // 날짜 문자열을 파싱해서 비교 (최신순)
        final dateA = _parseDateKey(a);
        final dateB = _parseDateKey(b);
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final items = grouped[dateKey]!;
        final firstItem = items.first;
        final dateHeader = _formatDateHeader(firstItem.gradingDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 24 : 0),
              child: Text(
                dateHeader,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 해당 날짜의 채점 기록들
            ...items.map((item) => _buildHistoryItem(item)),
          ],
        );
      },
    );
  }

  /// 날짜 키 파싱
  DateTime _parseDateKey(String dateKey) {
    // "2025년 11월 29일" 형식을 파싱
    try {
      final parts = dateKey
          .replaceAll('년', '')
          .replaceAll('월', '')
          .replaceAll('일', '')
          .trim()
          .split(' ');
      if (parts.length >= 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // 파싱 실패 시 현재 날짜 반환
    }
    return DateTime.now();
  }

  /// 채점 히스토리 아이템 위젯
  Widget _buildHistoryItem(GradingHistoryItem item) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        // AppDependencies에서 UseCase 가져오기
        final getStudentAnswersUseCase =
            AppDependencies.getStudentAnswersForResponseUseCase;
        final updateStudentAnswersUseCase =
            AppDependencies.updateStudentAnswersUseCase;
        final getSectionImageUseCase = AppDependencies.getSectionImageUseCase;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditGradingResultPage(
              studentResponseId: item.studentResponseId,
              academyUserId: item.academyUserId,
              getStudentAnswersUseCase: getStudentAnswersUseCase,
              updateStudentAnswersUseCase: updateStudentAnswersUseCase,
              getSectionImageUseCase: getSectionImageUseCase,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 왼쪽: 책 표지 이미지
            Container(
              width: screenWidth * 0.15, // Figma 기준 상대 크기
              height: screenWidth * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppTheme.textSecondary.withOpacity(0.1),
              ),
              child:
                  item.bookCoverImageUrl != null &&
                      item.bookCoverImageUrl!.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item.bookCoverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.book,
                            color: AppTheme.textSecondary,
                          );
                        },
                      ),
                    )
                  : Icon(Icons.book, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 12),

            // 가운데: 4줄 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. workbookName
                  Text(
                    item.workbookName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 2. className
                  Text(
                    item.className ?? '클래스 정보 없음',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 3. pageRange
                  Text(
                    '${item.pageRange}페이지',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 4. gradingDate (오전/오후 형식)
                  Text(
                    _formatTimeToKoreanAmPm(item.gradingDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 오른쪽: chevron_right 아이콘
            Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 24),
          ],
        ),
      ),
    );
  }
}
