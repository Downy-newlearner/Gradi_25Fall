/// 문제집 데이터 모델 (문제집 순 페이지용, UI용)
/// 
/// 문제집 순 뷰에서 표시되는 문제집 정보입니다.
class WorkbookData {
  final String workbookName;
  final String lastStudyDate;
  final int progress;
  final String thumbnailPath;
  final String className;
  final int? bookId;
  final int academyUserId;

  WorkbookData({
    required this.workbookName,
    required this.lastStudyDate,
    required this.progress,
    required this.thumbnailPath,
    required this.className,
    this.bookId,
    required this.academyUserId,
  });
}

