import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../utils/app_logger.dart';
import 'auth_service.dart';
import 'academy_service.dart';

class UploadContext {
  final int academyUserId;
  final int userId;
  final int? classId; // TODO: class_id는 null일 수 있으므로 추후 구현 시 확인 필요
  final int academyId;

  const UploadContext({
    required this.academyUserId,
    required this.userId,
    this.classId, // nullable이므로 required 제거
    required this.academyId,
  });
}

/// Presigned URL 배치 응답 모델
class PresignedBatchResponse {
  final int studentResponseId;
  final List<String> presignedUrls;
  final String message;

  PresignedBatchResponse({
    required this.studentResponseId,
    required this.presignedUrls,
    required this.message,
  });

  factory PresignedBatchResponse.fromJson(Map<String, dynamic> json) {
    return PresignedBatchResponse(
      studentResponseId: json['studentResponseId'] as int,
      presignedUrls: (json['presignedUrls'] as List<dynamic>)
          .map((url) => url as String)
          .toList(),
      message: json['message'] as String? ?? 'success',
    );
  }
}

class UploadBatchService {
  final AuthService _authService;
  final AcademyService _academyService;

  UploadBatchService({AuthService? authService, AcademyService? academyService})
    : _authService = authService ?? AuthService(),
      _academyService = academyService ?? AcademyService();

  /// 현재 디폴트 학원 기준 UploadContext 생성
  Future<UploadContext> buildContext() async {
    final userIdStr = await _authService.getUserId();
    if (userIdStr == null) {
      throw Exception('사용자 ID를 가져올 수 없습니다.');
    }

    final academyCode = await _academyService.getDefaultAcademyCode();
    if (academyCode == null) {
      throw Exception('디폴트 학원 코드를 찾을 수 없습니다. 학원을 먼저 등록해주세요.');
    }

    appLog('[UploadBatchService] 디폴트 학원 코드: $academyCode');

    // 캐시에서 학원 정보 조회 시도
    var academy = await _academyService.getAcademyByCode(academyCode);
    appLog('[UploadBatchService] 캐시 조회 결과: ${academy != null ? "성공" : "실패"}');

    // 캐시에 없으면 API에서 가져와서 캐시에 저장
    if (academy == null) {
      appLog('[UploadBatchService] 캐시에 학원 정보가 없음. API에서 가져오는 중...');
      try {
        final academies = await _academyService.getUserAcademies(userIdStr);
        appLog('[UploadBatchService] API에서 ${academies.length}개의 학원을 가져옴');

        if (academies.isEmpty) {
          throw Exception('등록된 학원이 없습니다. 학원을 먼저 등록해주세요.');
        }

        // 등록완료된 학원만 필터링
        final registeredAcademies = academies
            .where((a) => a.registerStatus == 'Y')
            .toList();

        appLog('[UploadBatchService] 등록완료된 학원: ${registeredAcademies.length}개');

        if (registeredAcademies.isEmpty) {
          throw Exception('등록완료된 학원이 없습니다. 학원 등록을 완료해주세요.');
        }

        // 학원 코드 목록 로깅
        final academyCodes = registeredAcademies
            .map((a) => a.academyCode ?? 'null')
            .toList();
        appLog('[UploadBatchService] 등록완료된 학원 코드 목록: $academyCodes');
        appLog('[UploadBatchService] 찾는 학원 코드: $academyCode');

        // 해당 academyCode가 있는지 직접 확인
        final matchingAcademies = registeredAcademies
            .where((a) => a.academyCode == academyCode)
            .toList();

        UserAcademyResponse foundAcademy;
        if (matchingAcademies.isNotEmpty) {
          foundAcademy = matchingAcademies.first;
          appLog('[UploadBatchService] ✅ 디폴트 학원 코드($academyCode)를 찾았습니다.');
        } else {
          foundAcademy = registeredAcademies.first;
          appLog(
            '[UploadBatchService] ⚠️ 디폴트 학원 코드($academyCode)가 없어서 첫 번째 학원(${foundAcademy.academyCode})을 사용합니다.',
          );
        }

        await _academyService.saveAcademiesToCache(academies);

        // 찾은 학원 사용
        academy = foundAcademy;
        appLog('[UploadBatchService] 학원 정보 설정 완료: ${academy.academyName}');
      } catch (e) {
        appLog('[UploadBatchService] ❌ 학원 목록 갱신 실패: $e');
        rethrow; // 에러를 다시 던져서 상위에서 처리하도록
      }
    }

    // academy는 이 시점에서 항상 non-null이어야 함
    // (캐시에서 찾았거나, API에서 가져왔거나, 예외가 발생했을 것)
    // 하지만 방어적 프로그래밍을 위해 null 체크 유지
    // ignore: dead_code, unnecessary_null_comparison
    if (academy == null) {
      throw Exception('디폴트 학원 정보를 찾을 수 없습니다. 학원을 먼저 등록해주세요.');
    }

    final finalAcademy = academy;
    appLog('[UploadBatchService] 최종 학원 정보:');
    appLog('  - academyName: ${finalAcademy.academyName}');
    appLog('  - academyCode: ${finalAcademy.academyCode}');
    appLog('  - registerStatus: ${finalAcademy.registerStatus}');
    // TODO: class_id는 null일 수 있으므로 추후 구현 시 확인 필요
    if (finalAcademy.academy_user_id == null ||
        finalAcademy.academy_id == null ||
        finalAcademy.user_id == null) {
      appLog('[UploadBatchService] ❌ 학원 응답에 필요한 ID가 없음:');
      appLog('  - academy_user_id: ${finalAcademy.academy_user_id}');
      appLog('  - class_id: ${finalAcademy.class_id}');
      appLog('  - academy_id: ${finalAcademy.academy_id}');
      appLog('  - user_id: ${finalAcademy.user_id}');
      throw Exception('학원 응답에 필요한 ID가 없습니다. 학원 정보를 다시 확인해주세요.');
    }

    appLog('[UploadBatchService] ✅ UploadContext 생성 완료:');
    appLog('  - academyUserId: ${finalAcademy.academy_user_id}');
    appLog('  - userId: ${finalAcademy.user_id}');
    appLog('  - classId: ${finalAcademy.class_id}');
    appLog('  - academyId: ${finalAcademy.academy_id}');

    return UploadContext(
      academyUserId: finalAcademy.academy_user_id!,
      userId: finalAcademy.user_id!,
      classId: finalAcademy.class_id, // nullable이므로 null 체크 연산자 제거
      academyId: finalAcademy.academy_id!,
    );
  }

  /// /upload-url/batch 호출하여 presigned URL 목록 받기
  Future<PresignedBatchResponse> requestPresignedUrls({
    required UploadContext context,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('업로드할 이미지가 없습니다.');
    }

    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 업로드 URL 배치를 요청할 수 없습니다.');
    }

    final uri = ApiConfig.getUploadUrlBatchUri();

    final body = images.map((image) {
      final segments = image.path.split('/');
      final fileName = segments.isNotEmpty ? segments.last : 'image.png';
      return {
        'academy_user_id': context.academyUserId,
        'user_id': context.userId,
        'class_id': context.classId,
        'academy_id': context.academyId,
        'file_name': fileName,
        'url': null,
      };
    }).toList();

    appLog('[UploadBatchService] POST $uri');
    appLog('[UploadBatchService] body: $body');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    appLog(
      '[UploadBatchService] status=${response.statusCode}, body=${response.body}',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload URL batch 요청 실패: ${response.statusCode}');
    }

    try {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      final presignedResponse = PresignedBatchResponse.fromJson(jsonResponse);
      appLog(
        '[UploadBatchService] ✅ Presigned URLs 받음: ${presignedResponse.presignedUrls.length}개',
      );
      return presignedResponse;
    } catch (e) {
      appLog('[UploadBatchService] ❌ 응답 파싱 실패: $e');
      throw Exception('Presigned URL 응답 파싱 실패: $e');
    }
  }

  /// 파일 확장자로 Content-Type 결정
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // 기본값
    }
  }

  /// Presigned URL로 단일 이미지 업로드
  Future<void> uploadToPresignedUrl({
    required XFile file,
    required String presignedUrl,
    String? contentType,
  }) async {
    try {
      // 파일명에서 Content-Type 결정
      final fileName = file.path.split('/').last;
      final finalContentType = contentType ?? _getContentType(fileName);

      appLog(
        '[UploadBatchService] S3 업로드 시작: $fileName (Content-Type: $finalContentType)',
      );

      // 파일 바이트 읽기
      final bytes = await file.readAsBytes();
      appLog('[UploadBatchService] 파일 크기: ${bytes.length} bytes');

      // Presigned URL로 PUT 요청
      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {'Content-Type': finalContentType},
        body: bytes,
      );

      appLog('[UploadBatchService] S3 업로드 응답: status=${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'S3 업로드 실패: HTTP ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      appLog('[UploadBatchService] ✅ S3 업로드 성공: $fileName');
    } catch (e) {
      appLog('[UploadBatchService] ❌ S3 업로드 실패: $e');
      rethrow;
    }
  }

  /// 기존 메서드 호환성을 위한 래퍼 (deprecated)
  @Deprecated('uploadImages를 사용하세요')
  Future<void> requestBatch({
    required UploadContext context,
    required List<XFile> images,
  }) async {
    await requestPresignedUrls(context: context, images: images);
  }
}

/// 파일 확장자로 Content-Type 결정 (외부 함수)
String getContentTypeFromFileName(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg'; // 기본값
  }
}

/// Presigned URL로 단일 이미지 업로드 (외부 함수)
Future<void> uploadToPresignedUrl({
  required XFile file,
  required String presignedUrl,
  String? contentType,
}) async {
  try {
    // 파일명에서 Content-Type 결정
    final fileName = file.path.split('/').last;
    final finalContentType =
        contentType ?? getContentTypeFromFileName(fileName);

    appLog(
      '[UploadBatchService] S3 업로드 시작: $fileName (Content-Type: $finalContentType)',
    );

    // 파일 바이트 읽기
    final bytes = await file.readAsBytes();
    appLog('[UploadBatchService] 파일 크기: ${bytes.length} bytes');

    // Presigned URL로 PUT 요청
    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: {'Content-Type': finalContentType},
      body: bytes,
    );

    appLog('[UploadBatchService] S3 업로드 응답: status=${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'S3 업로드 실패: HTTP ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    appLog('[UploadBatchService] ✅ S3 업로드 성공: $fileName');
  } catch (e) {
    appLog('[UploadBatchService] ❌ S3 업로드 실패: $e');
    rethrow;
  }
}

/// 전체 업로드 흐름: Presigned URL 요청 → S3 업로드 (외부 함수)
///
/// 다른 코드에서도 사용할 수 있도록 외부 함수로 제공됩니다.
/// UploadBatchService 인스턴스를 자동으로 생성하여 사용합니다.
///
/// [onProgress] 콜백은 각 이미지 업로드 완료 시 호출됩니다.
/// (uploadedCount, totalCount) 형태로 진행 상황을 전달합니다.
Future<PresignedBatchResponse> uploadImages({
  required List<XFile> images,
  UploadBatchService? uploadService,
  void Function(int uploadedCount, int totalCount)? onProgress,
}) async {
  if (images.isEmpty) {
    throw Exception('업로드할 이미지가 없습니다.');
  }

  // UploadBatchService 인스턴스 생성 (없으면 기본 인스턴스 사용)
  final service = uploadService ?? UploadBatchService();

  appLog('[UploadBatchService] 🚀 이미지 업로드 시작: ${images.length}개');

  // 1. UploadContext 생성
  final context = await service.buildContext();
  appLog('[UploadBatchService] ✅ UploadContext 생성 완료');

  // 2. Presigned URL 배치 요청
  final presignedResponse = await service.requestPresignedUrls(
    context: context,
    images: images,
  );

  if (presignedResponse.presignedUrls.length != images.length) {
    throw Exception(
      'Presigned URL 개수 불일치: 이미지 ${images.length}개, URL ${presignedResponse.presignedUrls.length}개',
    );
  }

  // 3. 각 Presigned URL로 이미지 업로드
  appLog('[UploadBatchService] 📤 S3 업로드 시작...');
  for (int i = 0; i < images.length; i++) {
    final file = images[i];
    final presignedUrl = presignedResponse.presignedUrls[i];

    appLog(
      '[UploadBatchService] 업로드 중: ${i + 1}/${images.length} - ${file.path.split('/').last}',
    );

    await uploadToPresignedUrl(file: file, presignedUrl: presignedUrl);

    // 진행 상황 콜백 호출
    onProgress?.call(i + 1, images.length);
  }

  appLog('[UploadBatchService] ✅ 모든 이미지 업로드 완료!');
  return presignedResponse;
}
