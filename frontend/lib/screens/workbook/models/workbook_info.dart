/// 문제집 정보 모델 (클래스 내부용, UI용)
/// 
/// 클래스 카드 내부에 표시되는 문제집 정보입니다.
class WorkbookInfo {
  final String name;
  final String lastStudyDate;
  final int progress;
  final String thumbnailPath;
  final int? bookId;
  final int academyUserId;

  WorkbookInfo({
    required this.name,
    required this.lastStudyDate,
    required this.progress,
    required this.thumbnailPath,
    this.bookId,
    required this.academyUserId,
  });
}

