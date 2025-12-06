/// API 설정 관리
///
/// 환경별 서버 URL 및 엔드포인트를 중앙에서 관리합니다.
/// TODO: 환경별로 분리 (개발/프로덕션)
class ApiConfig {
  // 기본 서버 URL
  static const String baseUrl = 'https://3.34.214.133';

  // ========== 엔드포인트 정의 ==========

  // 사용자 정보
  static const String meEndpoint = '/me';

  // 인증 관련
  static const String signInEndpoint = '/sign-in';
  static const String signUpEndpoint = '/sign-up';
  static const String refreshTokenEndpoint = '/refresh-token';

  // 계정 관리
  static const String checkAccountIdEndpoint = '/users/check-accountId';
  static const String resetPasswordEndpoint = '/users/reset-password';
  static const String changeResetPasswordEndpoint = '/change/reset_password';
  static const String signOutEndpoint = '/sign-out';
  static const String uploadStreamEndpoint = '/storage/upload-stream';
  static const String uploadUrlBatchEndpoint = '/storage/upload-url/batch';

  // 인증 코드 발송
  static const String sendCodeSignUpEndpoint = '/send-code/sign_up';
  static const String sendCodeResetPasswordEndpoint =
      '/send-code/reset_password';
  static const String sendCodeFindAccountEndpoint = '/send-code/find_account';

  // 인증 코드 확인
  static const String verifySignUpEndpoint = '/verify/sign_up';
  static const String verifyResetPasswordEndpoint = '/verify/reset_password';
  static const String verifyFindAccountEndpoint = '/verify/find_account';

  // Assessment 관련
  static const String assessmentsAssigneeEndpoint =
      '/grading/assessments/assignee';

  // Academy 관련
  static const String academyClassesEndpoint = '/academy/academy-users/classes';

  // ========== URI 생성 헬퍼 메서드 ==========

  // 사용자 정보
  static Uri getMeUri() => Uri.parse('$baseUrl$meEndpoint');

  // 인증 관련
  static Uri getSignInUri() => Uri.parse('$baseUrl$signInEndpoint');
  static Uri getSignUpUri() => Uri.parse('$baseUrl$signUpEndpoint');
  static Uri getRefreshTokenUri() => Uri.parse('$baseUrl$refreshTokenEndpoint');

  // 계정 관리
  static Uri getCheckAccountIdUri(String accountId) =>
      Uri.parse('$baseUrl$checkAccountIdEndpoint?accountId=$accountId');
  static Uri getResetPasswordUri() =>
      Uri.parse('$baseUrl$resetPasswordEndpoint');
  static Uri getChangeResetPasswordUri() =>
      Uri.parse('$baseUrl$changeResetPasswordEndpoint');
  static Uri getSignOutUri() => Uri.parse('$baseUrl$signOutEndpoint');
  static Uri getUploadStreamUri() => Uri.parse('$baseUrl$uploadStreamEndpoint');
  static Uri getUploadUrlBatchUri() =>
      Uri.parse('$baseUrl$uploadUrlBatchEndpoint');

  // 인증 코드 발송
  static Uri getSendCodeSignUpUri() =>
      Uri.parse('$baseUrl$sendCodeSignUpEndpoint');
  static Uri getSendCodeResetPasswordUri() =>
      Uri.parse('$baseUrl$sendCodeResetPasswordEndpoint');
  static Uri getSendCodeFindAccountUri() =>
      Uri.parse('$baseUrl$sendCodeFindAccountEndpoint');

  // 인증 코드 확인
  static Uri getVerifySignUpUri() => Uri.parse('$baseUrl$verifySignUpEndpoint');
  static Uri getVerifyResetPasswordUri() =>
      Uri.parse('$baseUrl$verifyResetPasswordEndpoint');
  static Uri getVerifyFindAccountUri() =>
      Uri.parse('$baseUrl$verifyFindAccountEndpoint');

  // Assessment 관련
  static Uri getAssessmentsAssigneeUri(
    String userAcademyId, {
    DateTime? dateTime, // ISO 8601 형식으로 변환할 DateTime
    String? iso8601String, // 직접 ISO 8601 문자열 전달 (선택사항)
  }) {
    // 새로운 방식: DateTime을 ISO 8601 형식으로 변환
    if (dateTime != null) {
      final monthStart = DateTime.utc(dateTime.year, dateTime.month, 1);
      final iso8601Str = monthStart.toIso8601String().split('.').first;
      final encodedIso8601 = Uri.encodeComponent(iso8601Str);
      return Uri.parse(
        '$baseUrl$assessmentsAssigneeEndpoint/$userAcademyId/$encodedIso8601',
      );
    }

    // 직접 ISO 8601 문자열 전달
    if (iso8601String != null) {
      final encodedIso8601 = Uri.encodeComponent(iso8601String);
      return Uri.parse(
        '$baseUrl$assessmentsAssigneeEndpoint/$userAcademyId/$encodedIso8601',
      );
    }

    // dateTime과 iso8601String이 모두 null이면 예외 발생
    throw ArgumentError('dateTime 또는 iso8601String 중 하나는 필수입니다.');
  }

  // Academy 관련
  static Uri getAcademyClassesUri(List<String> assigneeIds) {
    final idsParam = assigneeIds.join(',');
    return Uri.parse('$baseUrl$academyClassesEndpoint?ids=$idsParam');
  }
}
