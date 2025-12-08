import 'workbook_api.dart';
import 'academy_service.dart';
import 'auth_service.dart';
import '../utils/kst_date_factory.dart';
import '../utils/app_logger.dart';
import 'dart:developer' as developer;

/// 일일 학습 데이터 조회 결과
class DailyLearningResult {
  final List<WorkbookApiResponse> data;
  final bool hasError;
  final String? errorMessage;

  DailyLearningResult({
    required this.data,
    this.hasError = false,
    this.errorMessage,
  });

  /// 성공 결과
  factory DailyLearningResult.success(List<WorkbookApiResponse> data) {
    return DailyLearningResult(data: data);
  }

  /// 에러 결과
  factory DailyLearningResult.error(String message) {
    return DailyLearningResult(
      data: [],
      hasError: true,
      errorMessage: message,
    );
  }

  /// 빈 결과 (학습 기록 없음)
  factory DailyLearningResult.empty() {
    return DailyLearningResult(data: []);
  }

  /// 데이터가 있는지 확인
  bool get hasData => data.isNotEmpty && 
      data.any((response) => response.books.any((b) => b.bookId != null));
}

/// 일일 학습 데이터 조회 서비스
/// 
/// HomePage와 ContinuousLearningDetailPage에서 공통으로 사용하는 로직을 분리
class DailyLearningService {
  DailyLearningService({
    required WorkbookApi workbookApi,
    required AcademyService academyService,
    required AuthService authService,
  })  : _workbookApi = workbookApi,
        _academyService = academyService,
        _authService = authService;

  final WorkbookApi _workbookApi;
  final AcademyService _academyService;
  final AuthService _authService;

  /// 특정 날짜의 학습 데이터 조회
  /// 
  /// [date]: 조회할 날짜 (어떤 타임존이든 상관없음, KST로 변환됨)
  /// 
  /// 반환값: DailyLearningResult (성공/에러/빈 상태 구분)
  /// 
  /// 주의: date는 KST로 변환되어 WorkbookApi에 전달됩니다.
  /// WorkbookApi 내부에서는 추가 변환을 수행하지 않습니다.
  Future<DailyLearningResult> getDailyLearningData(DateTime date) async {
    try {
      // 1. 사용자 ID 확인
      final userId = await _authService.getUserId();
      if (userId == null) {
        return DailyLearningResult.error('사용자 정보를 가져올 수 없습니다.');
      }

      // 2. 학원 목록 조회
      final academies = await _academyService.getUserAcademies(userId);
      final academyUserIds = academies
          .where((a) => a.registerStatus == 'Y')
          .map((a) => a.academy_user_id)
          .whereType<int>()
          .toList();

      if (academyUserIds.isEmpty) {
        return DailyLearningResult.empty();
      }

      // 3. KST 날짜로 변환 (한 번만 수행)
      final kstDate = KstDateFactory.toKstDate(date);

      // 4. API 호출 (kstDate는 이미 KST로 변환된 상태)
      final data = await _workbookApi.fetchWorkbooksByDateRange(
        academyUserIds: academyUserIds,
        startDate: kstDate, // 이미 KST로 변환됨
        endDate: kstDate,   // 이미 KST로 변환됨
      );

      // 5. 결과 반환
      return DailyLearningResult.success(data);
    } on Exception catch (e) {
      appLog('[daily_learning:daily_learning_service] 조회 실패: $e');
      developer.log('❌ [DailyLearningService] 조회 실패: $e');
      return DailyLearningResult.error('학습 데이터를 불러오는데 실패했습니다.');
    } catch (e) {
      appLog('[daily_learning:daily_learning_service] 예상치 못한 오류: $e');
      developer.log('❌ [DailyLearningService] 예상치 못한 오류: $e');
      return DailyLearningResult.error('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 오늘의 학습 데이터 조회
  /// 
  /// 반환값: DailyLearningResult (성공/에러/빈 상태 구분)
  Future<DailyLearningResult> getTodayLearningData() async {
    final todayKst = KstDateFactory.getTodayKst();
    return getDailyLearningData(todayKst);
  }

  /// 학습 데이터에서 모든 책 목록 추출
  /// 
  /// [result]: DailyLearningResult
  /// 반환값: BookData 리스트 (bookId가 null이 아닌 것만)
  static List<BookData> extractBooks(DailyLearningResult result) {
    if (!result.hasData) return [];

    final allBooks = <BookData>[];
    for (var response in result.data) {
      allBooks.addAll(response.books.where((b) => b.bookId != null));
    }
    return allBooks;
  }

  /// 가장 많이 학습한 책 선택
  /// 
  /// [books]: BookData 리스트
  /// 반환값: 가장 많이 학습한 책 (totalSolvedPages 기준), 없으면 null
  static BookData? selectMostLearnedBook(List<BookData> books) {
    if (books.isEmpty) return null;

    // totalSolvedPages가 가장 많은 책 선택
    books.sort((a, b) => b.totalSolvedPages.compareTo(a.totalSolvedPages));
    return books.first;
  }
}

