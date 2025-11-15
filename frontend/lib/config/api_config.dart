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

  // 인증 코드 발송
  static const String sendCodeSignUpEndpoint = '/send-code/sign_up';
  static const String sendCodeResetPasswordEndpoint =
      '/send-code/reset_password';
  static const String sendCodeFindAccountEndpoint = '/send-code/find_account';

  // 인증 코드 확인
  static const String verifySignUpEndpoint = '/verify/sign_up';
  static const String verifyResetPasswordEndpoint = '/verify/reset_password';
  static const String verifyFindAccountEndpoint = '/verify/find_account';

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
}
