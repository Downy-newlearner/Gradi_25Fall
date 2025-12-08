import '../../domain/grading_history/grading_history_entity.dart';
import '../../services/grading_history_api.dart';

/// Grading History Mapper
///
/// API 응답을 도메인 엔티티로 변환하는 책임만을 가집니다.
class GradingHistoryMapper {
  /// API 응답 리스트를 도메인 엔티티 리스트로 변환
  ///
  /// [responses]: API 응답 리스트 (flat array)
  /// [classNameMap]: academyUserId → className 매핑
  ///
  /// 반환값: 도메인 엔티티 리스트 (정렬 없음, 순수 변환만)
  /// 정렬은 UI 레이어에서 처리합니다.
  List<GradingHistoryEntity> convertApiResponsesToEntities(
    List<GradingHistoryApiResponse> responses,
    Map<int, String?> classNameMap,
  ) {
    return responses.map((response) {
      // 1. createdAt 파싱 (UTC → 로컬 변환, 방어 로직 포함)
      final createdAt = _parseCreatedAt(response.createdAt);

      // 2. className 주입
      final className = classNameMap[response.academyUserId];

      // 3. 엔티티 생성
      return GradingHistoryEntity(
        studentResponseId: response.studentResponseId,
        academyUserId: response.academyUserId,
        bookId: response.bookId,
        bookName: response.bookName,
        bookCoverImageUrl: response.bookImageUrl,
        startPage: response.responseStartPage,
        endPage: response.responseEndPage,
        className: className,
        gradingDate: createdAt,
        assessId: response.assessId,
        unrecognizedResponseCount: response.unrecognizedResponseCount,
      );
    }).toList();
  }

  /// createdAt 문자열을 DateTime으로 안전하게 파싱
  ///
  /// 빈 문자열이거나 파싱 실패 시 과거 고정값 반환 (정렬 시 뒤로 가도록)
  ///
  /// 규칙:
  /// - created_at은 서버에서 UTC 기준 ISO 문자열로 내려온다는 전제 하에 toLocal() 적용
  /// - 만약 서버가 이미 KST로 내려주면 toLocal() 제거 필요
  /// - 파싱 실패 시 DateTime(1970, 1, 1) 반환 (정렬 시 가장 뒤로)
  DateTime _parseCreatedAt(String value) {
    if (value.isEmpty) {
      // 빈 문자열이면 과거 고정값 반환 (정렬 시 뒤로 가도록)
      return DateTime(1970, 1, 1);
    }

    try {
      // created_at은 서버에서 UTC 기준 ISO 문자열로 내려온다는 전제 하에 toLocal() 적용
      // 만약 서버가 이미 KST로 내려주면 toLocal() 제거 필요
      return DateTime.parse(value).toLocal();
    } catch (_) {
      // 파싱 실패 시 과거 고정값 반환 (정렬 시 가장 뒤로)
      return DateTime(1970, 1, 1);
    }
  }
}


