import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';

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
  final String workbookName;
  final String chapterName;
  final int solvedCount;
  final int totalCount;

  const ChapterDetailPage({
    super.key,
    required this.workbookName,
    required this.chapterName,
    required this.solvedCount,
    required this.totalCount,
  });

  @override
  State<ChapterDetailPage> createState() => _ChapterDetailPageState();
}

class _ChapterDetailPageState extends State<ChapterDetailPage> {
  // TODO: 서버에서 문제 데이터 가져오기
  // 임시 데이터
  final List<QuestionInfo> _questions = [
    QuestionInfo(questionNumber: 1, status: QuestionStatus.correct),
    QuestionInfo(questionNumber: 2, status: QuestionStatus.correct),
    QuestionInfo(questionNumber: 3, status: QuestionStatus.incorrect),
    QuestionInfo(questionNumber: 4, status: QuestionStatus.correct),
    QuestionInfo(questionNumber: 5, status: QuestionStatus.unsolved),
    QuestionInfo(questionNumber: 6, status: QuestionStatus.unsolved),
    QuestionInfo(questionNumber: 7, status: QuestionStatus.incorrect),
    QuestionInfo(questionNumber: 8, status: QuestionStatus.correct),
    QuestionInfo(questionNumber: 9, status: QuestionStatus.unsolved),
    QuestionInfo(questionNumber: 10, status: QuestionStatus.unsolved),
  ];

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

                    // 챕터 정보
                    _buildChapterInfo(),

                    const SizedBox(height: 24),

                    // 문제 목록
                    _buildQuestionGrid(),

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
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        return _buildQuestionCard(_questions[index]);
      },
    );
  }

  /// 개별 문제 카드
  Widget _buildQuestionCard(QuestionInfo question) {
    Color backgroundColor;
    Color textColor;

    switch (question.status) {
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
            'workbookName': widget.workbookName,
            'chapterName': widget.chapterName,
            'questionNumber': question.questionNumber,
            'status': question.status,
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
            question.questionNumber.toString(),
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

  // 통계 계산 헬퍼 메서드
  int _getCorrectCount() {
    return _questions.where((q) => q.status == QuestionStatus.correct).length;
  }

  int _getIncorrectCount() {
    return _questions.where((q) => q.status == QuestionStatus.incorrect).length;
  }

  int _getUnsolvedCount() {
    return _questions.where((q) => q.status == QuestionStatus.unsolved).length;
  }
}

/// 문제 풀이 상태
enum QuestionStatus {
  correct, // 맞음
  incorrect, // 틀림
  unsolved, // 안 풀음
}

/// 문제 정보 모델
class QuestionInfo {
  final int questionNumber;
  final QuestionStatus status;

  QuestionInfo({required this.questionNumber, required this.status});
}
