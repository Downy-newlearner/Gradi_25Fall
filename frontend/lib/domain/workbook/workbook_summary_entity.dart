/// 문제집 요약 도메인 엔티티 (UI 표시용)
///
/// API 응답의 book 정보를 도메인 모델로 변환합니다.
class WorkbookSummaryEntity {
  final int? bookId;
  final String bookName;
  final String? coverImageUrl; // book_image_url
  final int totalPages; // book_page
  final int totalSolvedPages; // total_solved_pages
  final DateTime? lastStudyDate; // latest_updated_at
  final int academyUserId;
  final String? className; // 상위 레이어에서 주입
  final String? bookSemester; // book_semester

  WorkbookSummaryEntity({
    this.bookId,
    required this.bookName,
    this.coverImageUrl,
    required this.totalPages,
    required this.totalSolvedPages,
    this.lastStudyDate,
    required this.academyUserId,
    this.className,
    this.bookSemester,
  });

  /// 진행률 계산 (0~100)
  ///
  /// 규칙:
  /// - totalPages가 null/0이면 → 0 반환
  /// - totalSolvedPages / totalPages * 100 (소수점 반올림)
  int get progress {
    if (totalPages <= 0) return 0;
    return ((totalSolvedPages / totalPages) * 100).round().clamp(0, 100);
  }

  /// 마지막 학습일 포맷팅 (YYYY.MM.DD)
  String get formattedLastStudyDate {
    if (lastStudyDate == null) return '';
    final date = lastStudyDate!;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 썸네일 경로 결정 전략
  ///
  /// 1. coverImageUrl(book_image_url)이 있으면 → 네트워크 URL 반환
  /// 2. 없으면 → bookId 기반 asset 경로 매핑 (기본값)
  String get thumbnailPath {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      return coverImageUrl!;
    }
    // Asset 경로 매핑 (fallback)
    return _getAssetPathForBook(bookId);
  }

  /// bookId → asset 경로 매핑 (fallback용)
  String _getAssetPathForBook(int? bookId) {
    // TODO: bookId 기반 매핑 로직 (필요시)
    return 'assets/images/bookcovers/BookCover_Blacklabel.png';
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'book_name': bookName,
      'cover_image_url': coverImageUrl,
      'total_pages': totalPages,
      'total_solved_pages': totalSolvedPages,
      'last_study_date': lastStudyDate?.toIso8601String(),
      'academy_user_id': academyUserId,
      'class_name': className,
      'book_semester': bookSemester,
    };
  }

  factory WorkbookSummaryEntity.fromJson(Map<String, dynamic> json) {
    return WorkbookSummaryEntity(
      bookId: json['book_id'] as int?,
      bookName: json['book_name'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      totalPages: json['total_pages'] as int? ?? 0,
      totalSolvedPages: json['total_solved_pages'] as int? ?? 0,
      lastStudyDate: json['last_study_date'] != null
          ? DateTime.parse(json['last_study_date']).toLocal()
          : null,
      academyUserId: json['academy_user_id'] as int? ?? 0,
      className: json['class_name'] as String?,
      bookSemester: json['book_semester'] as String?,
    );
  }
}
