import '../../../../domain/grading_history/grading_history_entity.dart';

/// 채점 히스토리 UI 모델
///
/// 기존 grading_history_page.dart의 GradingHistoryItem을 완전히 대체합니다.
class GradingHistoryItem {
  final int studentResponseId;
  final int academyUserId; // 추가
  final String workbookName; // bookName
  final String? className;
  final int startPage;
  final int endPage;
  final String? bookCoverImageUrl;
  final DateTime gradingDate;

  /// 페이지 범위 문자열 (예: "14-20")
  String get pageRange => '$startPage-$endPage';

  const GradingHistoryItem({
    required this.studentResponseId,
    required this.academyUserId, // 추가
    required this.workbookName,
    this.className,
    required this.startPage,
    required this.endPage,
    this.bookCoverImageUrl,
    required this.gradingDate,
  });

  /// 도메인 엔티티에서 UI 모델로 변환
  factory GradingHistoryItem.fromEntity(GradingHistoryEntity entity) {
    return GradingHistoryItem(
      studentResponseId: entity.studentResponseId,
      academyUserId: entity.academyUserId, // 추가
      workbookName: entity.bookName ?? '책 이름 없음',
      className: entity.className,
      startPage: entity.startPage,
      endPage: entity.endPage,
      bookCoverImageUrl: entity.bookCoverImageUrl,
      gradingDate: entity.gradingDate,
    );
  }
}
