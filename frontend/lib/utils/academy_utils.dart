import 'dart:developer' as developer;

import '../services/academy_service.dart';

/// 공통 학원 유틸 함수 모음
Future<String?> getUserAcademyId({
  required AcademyService academyService,
  List<UserAcademyResponse>? registeredAcademies,
  String? academyCode,
}) async {
  final code = academyCode ?? await academyService.getDefaultAcademyCode();
  if (code == null) {
    developer.log('⚠️ [AcademyUtils] 기본 학원 코드를 찾을 수 없습니다.');
    return null;
  }

  UserAcademyResponse? academy;

  final cachedList = registeredAcademies;
  if (cachedList != null && cachedList.isNotEmpty) {
    try {
      academy = cachedList.firstWhere((a) => a.academyCode == code);
    } catch (_) {
      // ignore and fallback to cache lookup
    }
  }

  academy ??= await academyService.getAcademyByCode(code);

  if (academy == null) {
    developer.log('⚠️ [AcademyUtils] 학원 정보를 찾을 수 없습니다. code: $code');
    return null;
  }

  final userAcademyId = academy.academy_user_id?.toString();
  developer.log(
    '✅ [AcademyUtils] userAcademyId=$userAcademyId (academyCode: $code)',
  );
  return userAcademyId;
}
