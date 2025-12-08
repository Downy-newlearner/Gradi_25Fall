/// 채점 히스토리 도메인 엔티티
///
/// API 응답의 student response 정보를 도메인 모델로 변환합니다.
class GradingHistoryEntity {
  final int studentResponseId;
  final int academyUserId;
  final int? bookId;
  final String? bookName;
  final String? bookCoverImageUrl; // book_image_url
  final int startPage; // response_start_page
  final int endPage; // response_end_page
  final String? className; // Repository에서 주입
  final DateTime gradingDate; // created_at 파싱 후 toLocal()

  // 선택적 필드 (현재 UI에서 사용 안 하지만 향후 확장 가능성)
  final int? assessId;
  final int unrecognizedResponseCount;

  const GradingHistoryEntity({
    required this.studentResponseId,
    required this.academyUserId,
    this.bookId,
    this.bookName,
    this.bookCoverImageUrl,
    required this.startPage,
    required this.endPage,
    this.className,
    required this.gradingDate,
    this.assessId,
    this.unrecognizedResponseCount = 0,
  });

  /// ⚠️ 서버 API 응답이 아니라, SharedPreferences 캐시 전용 JSON 스키마입니다.
  ///
  /// API 응답은 GradingHistoryApiResponse → UseCase → GradingHistoryEntity로 변환되며,
  /// 이 메서드는 캐시에서 복원할 때만 사용됩니다.
  ///
  /// 캐시 스키마:
  /// - book_cover_image_url (API: book_image_url)
  /// - start_page (API: response_start_page)
  /// - end_page (API: response_end_page)
  /// - grading_date (API: created_at)
  factory GradingHistoryEntity.fromCacheJson(Map<String, dynamic> json) {
    return GradingHistoryEntity(
      studentResponseId: json['student_response_id'] as int? ?? 0,
      academyUserId: json['academy_user_id'] as int? ?? 0,
      bookId: json['book_id'] as int?,
      bookName: json['book_name'] as String?,
      bookCoverImageUrl: json['book_cover_image_url'] as String?,
      startPage: json['start_page'] as int? ?? 0,
      endPage: json['end_page'] as int? ?? 0,
      className: json['class_name'] as String?,
      gradingDate: _parseGradingDate(json['grading_date']),
      assessId: json['assess_id'] as int?,
      unrecognizedResponseCount:
          json['unrecognized_response_count'] as int? ?? 0,
    );
  }

  /// ⚠️ 서버 API 응답이 아니라, SharedPreferences 캐시 전용 JSON 스키마입니다.
  ///
  /// 캐시 저장 시 사용되며, API 스키마와는 다른 키 이름을 사용합니다.
  Map<String, dynamic> toCacheJson() {
    return {
      'student_response_id': studentResponseId,
      'academy_user_id': academyUserId,
      'book_id': bookId,
      'book_name': bookName,
      'book_cover_image_url': bookCoverImageUrl,
      'start_page': startPage,
      'end_page': endPage,
      'class_name': className,
      'grading_date': gradingDate.toIso8601String(),
      'assess_id': assessId,
      'unrecognized_response_count': unrecognizedResponseCount,
    };
  }

  /// 캐시에서 grading_date를 안전하게 파싱
  ///
  /// 스키마 변경이나 손상된 캐시 데이터에 대비한 방어 로직
  static DateTime _parseGradingDate(dynamic value) {
    if (value == null) {
      // 값이 없으면 과거 고정값 반환 (정렬 시 뒤로 가도록)
      return DateTime(1970, 1, 1);
    }

    if (value is! String) {
      return DateTime(1970, 1, 1);
    }

    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      // 파싱 실패 시 과거 고정값 반환
      return DateTime(1970, 1, 1);
    }
  }
}
