import '../../domain/workbook/workbook_summary_entity.dart';
import '../../services/workbook_api.dart';
import '../../screens/workbook/models/class_data.dart';
import '../../screens/workbook/models/workbook_info.dart';
import '../../screens/workbook/models/workbook_data.dart';

/// Workbook 데이터 변환 Mapper
///
/// API 응답을 도메인 엔티티 및 UI 모델로 변환하는 책임만을 가집니다.
class WorkbookMapper {
  /// API 응답을 WorkbookSummaryEntity로 변환
  ///
  /// [apiResponses]: API 응답 리스트 (여러 academyUserId)
  /// [classNameMap]: academyUserId → className 매핑 (Repository에서 조회됨)
  Future<Map<int, List<WorkbookSummaryEntity>>> convertApiResponsesToSummaries(
    List<WorkbookApiResponse> apiResponses,
    Map<int, String?> classNameMap,
  ) async {
    final summariesMap = <int, List<WorkbookSummaryEntity>>{};

    for (final apiResponse in apiResponses) {
      final summaries = <WorkbookSummaryEntity>[];
      final className = classNameMap[apiResponse.academyUserId];

      for (final bookData in apiResponse.books) {
        // latest_updated_at 파싱
        DateTime? lastStudyDate;
        if (bookData.latestUpdatedAt != null &&
            bookData.latestUpdatedAt!.isNotEmpty) {
          try {
            lastStudyDate = DateTime.parse(bookData.latestUpdatedAt!).toLocal();
          } catch (e) {
            // 파싱 실패 시 null 유지
          }
        }

        // WorkbookSummaryEntity 생성
        final summary = WorkbookSummaryEntity(
          bookId: bookData.bookId,
          bookName: bookData.bookName ?? '알 수 없는 문제집',
          coverImageUrl: bookData.bookImageUrl,
          totalPages: bookData.bookPage, // book_page 사용
          totalSolvedPages: bookData.totalSolvedPages,
          lastStudyDate: lastStudyDate,
          academyUserId: apiResponse.academyUserId,
          className: className,
          bookSemester: bookData.bookSemester,
        );

        summaries.add(summary);
      }

      summariesMap[apiResponse.academyUserId] = summaries;
    }

    return summariesMap;
  }

  /// WorkbookSummaryEntity 리스트를 ClassData로 변환
  ///
  /// DateTime 기준으로 정렬 후 문자열 변환합니다.
  List<ClassData> convertToClassData(
    Map<int, List<WorkbookSummaryEntity>> summariesByAcademyUserId,
  ) {
    final classDataList = <ClassData>[];

    summariesByAcademyUserId.forEach((academyUserId, summaries) {
      if (summaries.isEmpty) return;

      final className = summaries.first.className ?? '알 수 없는 클래스';

      // DateTime 기준으로 최신 날짜 찾기
      final lastStudyDate = _getLatestDateTime(summaries);

      // WorkbookInfo 리스트 생성
      final workbooks = summaries.map((summary) {
        return WorkbookInfo(
          name: summary.bookName,
          lastStudyDate: summary.formattedLastStudyDate,
          progress: summary.progress,
          thumbnailPath: summary.thumbnailPath,
          bookId: summary.bookId,
          academyUserId: summary.academyUserId,
        );
      }).toList();

      classDataList.add(
        ClassData(
          className: className,
          lastStudyDate: _formatDateTime(lastStudyDate),
          workbooks: workbooks,
        ),
      );
    });

    // DateTime 기준 정렬 후 문자열 변환
    classDataList.sort((a, b) {
      final dateA = _parseFormattedDate(a.lastStudyDate);
      final dateB = _parseFormattedDate(b.lastStudyDate);
      return dateB.compareTo(dateA); // 최신순
    });

    return classDataList;
  }

  /// WorkbookSummaryEntity 리스트를 WorkbookData로 변환
  ///
  /// DateTime 기준으로 정렬 후 문자열 변환합니다.
  List<WorkbookData> convertToWorkbookData(
    Map<int, List<WorkbookSummaryEntity>> summariesByAcademyUserId,
  ) {
    final workbookDataList = <WorkbookData>[];

    summariesByAcademyUserId.forEach((academyUserId, summaries) {
      for (final summary in summaries) {
        workbookDataList.add(
          WorkbookData(
            workbookName: summary.bookName,
            lastStudyDate: summary.formattedLastStudyDate,
            progress: summary.progress,
            thumbnailPath: summary.thumbnailPath,
            className: summary.className ?? '알 수 없는 클래스',
            bookId: summary.bookId,
            academyUserId: summary.academyUserId,
          ),
        );
      }
    });

    // DateTime 기준 정렬 후 문자열 변환
    workbookDataList.sort((a, b) {
      final dateA = _parseFormattedDate(a.lastStudyDate);
      final dateB = _parseFormattedDate(b.lastStudyDate);
      return dateB.compareTo(dateA); // 최신순
    });

    return workbookDataList;
  }

  /// summaries에서 가장 최근 DateTime 찾기
  DateTime? _getLatestDateTime(List<WorkbookSummaryEntity> summaries) {
    DateTime? latest;
    for (final summary in summaries) {
      if (summary.lastStudyDate != null) {
        if (latest == null || summary.lastStudyDate!.isAfter(latest)) {
          latest = summary.lastStudyDate;
        }
      }
    }
    return latest;
  }

  /// DateTime을 YYYY.MM.DD 형식으로 변환
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// YYYY.MM.DD 형식 문자열을 DateTime으로 파싱
  DateTime _parseFormattedDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime(1970, 1, 1); // 기본값
    try {
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (e) {
      // 파싱 실패 시 기본값
    }
    return DateTime(1970, 1, 1);
  }
}


