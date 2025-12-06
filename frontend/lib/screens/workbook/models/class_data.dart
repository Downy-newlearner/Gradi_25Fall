import 'workbook_info.dart';

/// 클래스 데이터 모델 (UI용)
/// 
/// 클래스별 문제집 목록을 표시하기 위한 UI 모델입니다.
class ClassData {
  final String className;
  final String lastStudyDate;
  final List<WorkbookInfo> workbooks;

  ClassData({
    required this.className,
    required this.lastStudyDate,
    required this.workbooks,
  });
}

