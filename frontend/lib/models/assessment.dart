/// Assessment 데이터 모델
///
/// 서버에서 받아온 평가/과제 정보를 표현합니다.
class Assessment {
  final String bookId;
  final String bookCoverImage;
  final String assessName; // 숙제 이름 (assessChapter에서 변경)
  final String assessPage; // "15-25" 형식 (시작페이지-끝페이지)
  final String assessClass; // 클래스명 (assigneeId를 통해 API로 조회)
  // assessStatus 종류:
  // - 'N': No, 아직 숙제가 완료되지 않음
  // - 'Y': Yes, 숙제가 완료됨
  final String assessStatus;

  Assessment({
    required this.bookId,
    required this.bookCoverImage,
    required this.assessName,
    required this.assessPage,
    required this.assessClass,
    required this.assessStatus,
  });

  /// JSON에서 Assessment 객체 생성
  ///
  /// 두 가지 형식을 지원:
  /// 1. API 응답 형식 (camelCase): assessName, assessStartPage, assigneeId, book.bookId 등
  /// 2. 캐시 저장 형식 (snake_case): assess_name, assess_page, assess_class 등
  factory Assessment.fromJson(Map<String, dynamic> json) {

    // 1. assessPage 파싱 (두 가지 형식 지원)
    String assessPage;
    if (json.containsKey('assessStartPage') &&
        json.containsKey('assessEndPage')) {
      // API 응답 형식: assessStartPage, assessEndPage
      final startPage = json['assessStartPage']?.toString() ?? '0';
      final endPage = json['assessEndPage']?.toString() ?? '0';
      assessPage = '$startPage-$endPage';
    } else if (json.containsKey('assess_page')) {
      // 캐시 형식: assess_page (이미 "15-25" 형식)
      assessPage = json['assess_page']?.toString() ?? '0-0';
    } else {
      assessPage = '0-0';
    }

    // 2. assessClass 파싱 (두 가지 형식 지원)
    String assessClass;
    if (json.containsKey('assigneeId')) {
      // API 응답 형식: assigneeId
      assessClass = json['assigneeId']?.toString() ?? '';
    } else if (json.containsKey('assess_class')) {
      // 캐시 형식: assess_class (이미 className이거나 assigneeId)
      assessClass = json['assess_class']?.toString() ?? '';
    } else {
      assessClass = '';
    }

    // 3. book 정보 파싱 (두 가지 형식 지원)
    String bookId;
    String bookImageUrl;
    if (json.containsKey('book') && json['book'] is Map) {
      // API 응답 형식: book 객체
      final book = json['book'] as Map<String, dynamic>;
      bookId = book['bookId']?.toString() ?? '';
      bookImageUrl = book['bookImageUrl'] as String? ?? '';
    } else {
      // 캐시 형식: book_id, book_cover_image
      bookId = json['book_id']?.toString() ?? '';
      bookImageUrl = json['book_cover_image']?.toString() ?? '';
    }

    // 4. assessName 파싱 (두 가지 형식 지원)
    final assessName =
        json['assessName']?.toString() ?? json['assess_name']?.toString() ?? '';

    // 5. assessStatus 파싱 (두 가지 형식 지원)
    final assessStatus =
        json['assessStatus']?.toString() ??
        json['assess_status']?.toString() ??
        'N';


    return Assessment(
      bookId: bookId,
      bookCoverImage: bookImageUrl,
      assessName: assessName,
      assessPage: assessPage,
      assessClass: assessClass,
      assessStatus: assessStatus,
    );
  }

  /// 클래스명을 업데이트한 새 Assessment 인스턴스 생성
  Assessment copyWith({String? assessClass}) {
    return Assessment(
      bookId: bookId,
      bookCoverImage: bookCoverImage,
      assessName: assessName,
      assessPage: assessPage,
      assessClass: assessClass ?? this.assessClass,
      assessStatus: assessStatus,
    );
  }

  /// Assessment 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'book_cover_image': bookCoverImage,
      'assess_name': assessName,
      'assess_page': assessPage,
      'assess_class': assessClass,
      'assess_status': assessStatus,
    };
  }

  @override
  String toString() {
    return 'Assessment(bookId: $bookId, name: $assessName, status: $assessStatus)';
  }
}

/// 날짜별 Assessment 데이터
class DateAssessment {
  final String date; // 'YYYY-MM-DD' 형식
  final List<Assessment> assessments;

  DateAssessment({required this.date, required this.assessments});

  /// JSON에서 DateAssessment 객체 생성
  factory DateAssessment.fromJson(Map<String, dynamic> json) {
    return DateAssessment(
      date: json['date'] ?? '',
      assessments:
          (json['assessments'] as List<dynamic>?)
              ?.map((item) => Assessment.fromJson(item))
              .toList() ??
          [],
    );
  }

  /// DateAssessment 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'assessments': assessments.map((a) => a.toJson()).toList(),
    };
  }
}
