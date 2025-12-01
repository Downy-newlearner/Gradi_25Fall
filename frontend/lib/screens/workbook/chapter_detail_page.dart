import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../widgets/back_button.dart';
import '../../services/get_chapter_question_statuses_use_case.dart';
import '../../services/models/question_status_model.dart';

/// 문제 풀이 상태 (UI 전용 enum, Domain에 없음)
enum QuestionStatus {
  correct, // isCorrect == true
  incorrect, // isCorrect == false
  unsolved, // isCorrect == null
}

/// 챕터 상세 페이지
/// WorkbookDetailPage에서 챕터를 선택하면 표시되는 페이지
///
/// 구성:
/// 1. 헤더: 뒤로가기 버튼 + 챕터명
/// 2. 문제 목록: 각 문제의 풀이 상태를 색상으로 표시
///    - 초록색: 풀고 맞은 문제
///    - 빨간색: 풀고 틀린 문제
///    - 회색: 풀지 않은 문제
class ChapterDetailPage extends StatefulWidget {
  final int chapterId;
  final int academyUserId;
  final String workbookName;
  final String chapterName;
  final GetChapterQuestionStatusesUseCase getChapterQuestionStatusesUseCase;

  const ChapterDetailPage({
    super.key,
    required this.chapterId,
    required this.academyUserId,
    required this.workbookName,
    required this.chapterName,
    required this.getChapterQuestionStatusesUseCase,
  });

  @override
  State<ChapterDetailPage> createState() => _ChapterDetailPageState();
}

class _ChapterDetailPageState extends State<ChapterDetailPage> {
  List<QuestionStatusModel> _questionStatuses = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestionStatuses();
  }

  Future<void> _loadQuestionStatuses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statuses = await widget.getChapterQuestionStatusesUseCase.call(
        chapterId: widget.chapterId,
        academyUserId: widget.academyUserId,
      );

      if (!mounted) return;

      setState(() {
        _questionStatuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('❌ [ChapterDetailPage] 문제 상태 로드 실패: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = '문제 정보를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  /// UI 정책: isCorrect? -> QuestionStatus 변환
  QuestionStatus _getQuestionStatus(QuestionStatusModel model) {
    final isCorrect = model.isCorrect;

    if (isCorrect == null) {
      return QuestionStatus.unsolved; // UI에서 판단
    } else if (isCorrect) {
      return QuestionStatus.correct;
    } else {
      return QuestionStatus.incorrect;
    }
  }

  // 통계 계산 (UI 레이어에서 처리)
  int _getCorrectCount() {
    return _questionStatuses.where((model) => model.isCorrect == true).length;
  }

  int _getIncorrectCount() {
    return _questionStatuses.where((model) => model.isCorrect == false).length;
  }

  int _getUnsolvedCount() {
    return _questionStatuses.where((model) => model.isCorrect == null).length;
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
            Expanded(child: _buildContent()),
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
            child: Text(
              widget.chapterName,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF333333),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // 로딩 상태
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 에러 상태
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF6B6B),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFFFF6B6B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestionStatuses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 빈 상태
    if (_questionStatuses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            '등록된 문제가 없습니다.',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ),
      );
    }

    // 정상 상태
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // 챕터 정보
          _buildChapterInfo(),

          const SizedBox(height: 24),

          // 문제 목록
          _buildQuestionGrid(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 챕터 정보 (진행 상태)
  Widget _buildChapterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusIndicator('맞은 문제', Colors.green, _getCorrectCount()),
          _buildStatusIndicator('틀린 문제', Colors.red, _getIncorrectCount()),
          _buildStatusIndicator('안 푼 문제', Colors.grey, _getUnsolvedCount()),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color, int count) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// 문제 그리드 (4열)
  Widget _buildQuestionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _questionStatuses.length,
      itemBuilder: (context, index) {
        final model = _questionStatuses[index];
        final status = _getQuestionStatus(model);
        return _buildQuestionCard(model.questionNumber, status);
      },
    );
  }

  /// 개별 문제 카드
  Widget _buildQuestionCard(int questionNumber, QuestionStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case QuestionStatus.correct:
        backgroundColor = const Color(0xFF4CAF50); // 초록색
        textColor = Colors.white;
        break;
      case QuestionStatus.incorrect:
        backgroundColor = const Color(0xFFF44336); // 빨간색
        textColor = Colors.white;
        break;
      case QuestionStatus.unsolved:
        backgroundColor = const Color(0xFFE9ECEF); // 회색
        textColor = const Color(0xFF666666);
        break;
    }

    return GestureDetector(
      onTap: () {
        // TODO: QuestionDetailPage로 이동
        Navigator.pushNamed(
          context,
          '/workbook/question-detail',
          arguments: {
            'chapterId': widget.chapterId,
            'academyUserId': widget.academyUserId,
            'workbookName': widget.workbookName,
            'chapterName': widget.chapterName,
            'questionNumber': questionNumber,
            'status': status,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            questionNumber.toString(),
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
