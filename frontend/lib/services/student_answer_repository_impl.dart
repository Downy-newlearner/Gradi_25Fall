import 'dart:developer' as developer;
import '../domain/student_answer/student_answer_entity.dart';
import '../domain/student_answer/student_answer_repository.dart';
import '../domain/student_answer/student_answer_update.dart';
import '../domain/student_answer/student_answer_query.dart';
import 'student_answer_api.dart';
import 'student_answer_mapper.dart';

/// Student Answer Repository 구현체
class StudentAnswerRepositoryImpl implements StudentAnswerRepository {
  final StudentAnswerApi _api;
  final StudentAnswerMapper _mapper;

  StudentAnswerRepositoryImpl({
    StudentAnswerApi? api,
    StudentAnswerMapper? mapper,
  }) : _api = api ?? StudentAnswerApi(),
       _mapper = mapper ?? StudentAnswerMapper();

  @override
  Future<List<StudentAnswerEntity>> getStudentAnswersByResponseId(
    int studentResponseId,
  ) async {
    try {
      // 1. API 호출
      final apiResponses = await _api.fetchStudentAnswers(studentResponseId);

      // 2. Mapper로 엔티티 변환
      return _mapper.fromApi(apiResponses);
    } catch (e) {
      developer.log('❌ [StudentAnswerRepository] API 호출 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateStudentAnswers(List<StudentAnswerUpdate> updates) async {
    try {
      // StudentAnswerUpdate → Map 변환 (API 레이어는 낮은 수준의 타입만 받음)
      final payload = updates.map((update) {
        return {
          'student_answer_id': update.studentAnswerId,
          'answer': update.newAnswer,
        };
      }).toList();

      await _api.updateStudentAnswers(payload);
    } catch (e) {
      developer.log('❌ [StudentAnswerRepository] 답안 수정 실패: $e');
      rethrow;
    }
  }

  @override
  Future<List<StudentAnswerEntity>> getStudentAnswers(
    StudentAnswerQuery query,
  ) async {
    try {
      List<StudentAnswerApiResponse> apiResponses;

      if (query is ChapterAndAcademyQuery) {
        // Grass API 호출
        apiResponses = await _api.fetchStudentAnswersByChapterAndAcademy(
          query.chapterId,
          query.academyUserId,
        );
      } else if (query is ResponseIdQuery) {
        // 기존 Response API 호출
        apiResponses = await _api.fetchStudentAnswers(query.studentResponseId);
      } else {
        throw ArgumentError('지원하지 않는 Query 타입입니다.');
      }

      // Mapper로 엔티티 변환
      return _mapper.fromApi(apiResponses);
    } catch (e) {
      developer.log('❌ [StudentAnswerRepository] 답안 조회 실패: $e');
      rethrow;
    }
  }
}
