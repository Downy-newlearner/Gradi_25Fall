import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';
import 'chapter_detail_page.dart';
import '../../domain/student_answer/student_answer_repository.dart';
import '../../domain/student_answer/student_answer_query.dart';
import '../../domain/section_image/get_section_image_use_case.dart';
import '../../config/app_dependencies.dart';
import '../../utils/app_logger.dart';

/// 문제 상세 페이지
/// ChapterDetailPage에서 문제를 선택하면 표시되는 페이지
///
/// 구성:
/// 1. 헤더: 뒤로가기 버튼 + 문제 번호
/// 2. Section 이미지: AI가 인식한 문제 영역 이미지 (crop된 이미지)
/// 3. 채점 히스토리: 해당 문제의 과거 채점 기록
///    - 채점 일시
///    - 채점 결과 (정답/오답)
///    - 학생 답안 이미지
class QuestionDetailPage extends StatefulWidget {
  final int chapterId;
  final int academyUserId;
  final String workbookName;
  final String chapterName;
  final int questionNumber;
  final QuestionStatus status;
  final StudentAnswerRepository studentAnswerRepository;
  final GetSectionImageUseCase getSectionImageUseCase;

  QuestionDetailPage({
    super.key,
    required this.chapterId,
    required this.academyUserId,
    required this.workbookName,
    required this.chapterName,
    required this.questionNumber,
    required this.status,
    StudentAnswerRepository? studentAnswerRepository,
    GetSectionImageUseCase? getSectionImageUseCase,
  }) : studentAnswerRepository =
           studentAnswerRepository ?? AppDependencies.studentAnswerRepository,
       getSectionImageUseCase =
           getSectionImageUseCase ?? AppDependencies.getSectionImageUseCase;

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  /// Section 이미지 URL
  String? _sectionImageUrl;
  bool _isLoadingImage = false;
  String? _imageError;

  /// 채점 히스토리 목록
  /// TODO: 서버에서 가져오기 (나중에 구현)

  final List<GradingHistory> _gradingHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSectionImage();
  }

  /// Section 이미지 로드
  ///
  /// chapterId, academyUserId, questionNumber로 답안을 조회하여
  /// studentResponseId를 찾고, 그것으로 이미지를 조회합니다.
  Future<void> _loadSectionImage() async {
    setState(() {
      _isLoadingImage = true;
      _imageError = null;
    });

    try {
      // 1. 답안 조회하여 studentResponseId 찾기
      final answers = await widget.studentAnswerRepository.getStudentAnswers(
        StudentAnswerQuery.byChapter(
          chapterId: widget.chapterId,
          academyUserId: widget.academyUserId,
        ),
      );

      // 2. 해당 문제 번호의 답안 찾기 (subQuestionNumber는 0 우선, 없으면 첫 번째)
      final matchingAnswers = answers
          .where((a) => a.questionNumber == widget.questionNumber)
          .toList();

      if (matchingAnswers.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingImage = false;
          _imageError = '답안 정보를 찾을 수 없습니다.';
        });
        return;
      }

      // subQuestionNumber가 0인 답안을 우선 선택, 없으면 첫 번째 답안
      final answer = matchingAnswers.firstWhere(
        (a) => a.subQuestionNumber == 0,
        orElse: () => matchingAnswers.first,
      );

      if (!mounted) return;

      // 3. 이미지 조회
      // 답안의 questionNumber와 subQuestionNumber를 사용
      // (답안이 실제로 저장된 문제 번호를 사용해야 함)
      final imageQuestionNumber = answer.questionNumber;
      final imageSubQuestionNumber = answer.subQuestionNumber;

      appLog(
        '[question_detail_page] 이미지 조회 시작 - questionNumber: $imageQuestionNumber, subQuestionNumber: $imageSubQuestionNumber, studentResponseId: ${answer.studentResponseId}',
      );

      final imageEntity = await widget.getSectionImageUseCase.call(
        academyUserId: widget.academyUserId,
        studentResponseId: answer.studentResponseId,
        questionNumber: imageQuestionNumber,
        subQuestionNumber: imageSubQuestionNumber,
      );

      if (!mounted) return;

      setState(() {
        _sectionImageUrl = imageEntity?.imageUrl;
        _isLoadingImage = false;
        if (imageEntity == null) {
          _imageError = '이미지를 찾을 수 없습니다.';
          appLog('[question_detail_page] 이미지 엔티티가 null입니다.');
        } else {
          appLog('[question_detail_page] 이미지 URL 설정됨: ${imageEntity.imageUrl}');
        }
      });
    } catch (e) {
      appLog('[question_detail_page] 이미지 로드 실패: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingImage = false;
        _imageError = '이미지를 불러오지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Section 이미지 (문제 영역)
                    _buildSectionImage(),

                    const SizedBox(height: 24),

                    // 채점 히스토리 섹션
                    _buildGradingHistorySection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CustomBackButton(),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              children: [
                Text(
                  '문제 ${widget.questionNumber}',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 문제 상태 배지
  Widget _buildStatusBadge() {
    String text;
    Color backgroundColor;
    Color textColor;

    switch (widget.status) {
      case QuestionStatus.correct:
        text = '정답';
        backgroundColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        break;
      case QuestionStatus.incorrect:
        text = '오답';
        backgroundColor = const Color(0xFFF44336);
        textColor = Colors.white;
        break;
      case QuestionStatus.unsolved:
        text = '미풀이';
        backgroundColor = const Color(0xFFE9ECEF);
        textColor = const Color(0xFF666666);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }

  /// Section 이미지 (AI가 인식한 문제 영역)
  /// TODO: 실제 서버에서 가져온 이미지 표시
  Widget _buildSectionImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '문제 영역',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border.all(color: const Color(0xFFE9ECEF)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildImageContent(),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    // 로딩 중
    if (_isLoadingImage) {
      return const Center(child: CircularProgressIndicator());
    }

    // 에러 상태
    if (_imageError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              size: 48,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 8),
            Text(
              _imageError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
    }

    // 이미지 표시
    if (_sectionImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _sectionImageUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            appLog('[question_detail_page] 이미지 로드 에러: $error');
            appLog('[question_detail_page] 이미지 URL: $_sectionImageUrl');
            appLog('[question_detail_page] StackTrace: $stackTrace');
            return _buildPlaceholder('이미지를 불러오지 못했습니다.');
          },
        ),
      );
    }

    // 이미지 없음
    return _buildPlaceholder('이미지가 없습니다.');
  }

  Widget _buildPlaceholder([String? message]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 8),
          Text(
            message ?? '이미지가 없습니다.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  /// 채점 히스토리 섹션
  Widget _buildGradingHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '채점 히스토리',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),

        _gradingHistory.isEmpty
            ? _buildEmptyHistory()
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gradingHistory.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildHistoryCard(_gradingHistory[index], index + 1);
                },
              ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '아직 채점 기록이 없습니다',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  /// 개별 채점 히스토리 카드
  Widget _buildHistoryCard(GradingHistory history, int attemptNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 시도 번호 + 결과
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$attemptNumber번째 시도',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: history.isCorrect
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  history.isCorrect ? '정답' : '오답',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 채점 일시
          Text(
            _formatDateTime(history.gradingDate),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 12),

          // 피드백
          if (history.feedback != null)
            Text(
              history.feedback!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),

          // TODO: 학생 답안 이미지 표시
          // if (history.studentAnswerImagePath != null)
          //   _buildStudentAnswerImage(history.studentAnswerImagePath!),
        ],
      ),
    );
  }

  /// 날짜 포맷팅
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 채점 히스토리 모델
class GradingHistory {
  final DateTime gradingDate;
  final bool isCorrect;
  final String? studentAnswerImagePath;
  final String? feedback;

  GradingHistory({
    required this.gradingDate,
    required this.isCorrect,
    this.studentAnswerImagePath,
    this.feedback,
  });
}
