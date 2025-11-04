import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// 임시 채점 결과 데이터 모델
class GradingResult {
  final int problemNumber;
  String recognizedAnswer; // final 제거 - 수정 가능하도록
  final String correctStatus; // '정답', '오답', '인식 실패'
  bool isUnrecognized;

  GradingResult({
    required this.problemNumber,
    required this.recognizedAnswer,
    required this.correctStatus,
    this.isUnrecognized = false,
  });
}

class EditGradingResultPage extends StatefulWidget {
  const EditGradingResultPage({super.key});

  @override
  State<EditGradingResultPage> createState() => _EditGradingResultPageState();
}

class _EditGradingResultPageState extends State<EditGradingResultPage> {
  List<XFile>? _images;
  int? _selectedProblemIndex;
  final TextEditingController _answerController = TextEditingController();
  bool _isEditingAnswer = false;

  // TODO: 채점 API 구현 후 실제 데이터로 교체
  // 임시 예시 데이터 (Figma 참고)
  final List<GradingResult> _results = [
    GradingResult(problemNumber: 1, recognizedAnswer: '1', correctStatus: '정답'),
    GradingResult(problemNumber: 2, recognizedAnswer: '3', correctStatus: '오답'),
    GradingResult(problemNumber: 3, recognizedAnswer: '2', correctStatus: '정답'),
    GradingResult(problemNumber: 4, recognizedAnswer: '5', correctStatus: '정답'),
    GradingResult(
      problemNumber: 5,
      recognizedAnswer: '2,5',
      correctStatus: '정답',
    ),
    GradingResult(problemNumber: 6, recognizedAnswer: '8', correctStatus: '정답'),
    GradingResult(
      problemNumber: 7,
      recognizedAnswer: '42',
      correctStatus: '정답',
    ),
    GradingResult(
      problemNumber: 8,
      recognizedAnswer: '82',
      correctStatus: '정답',
    ),
    GradingResult(
      problemNumber: 9,
      recognizedAnswer: '90',
      correctStatus: '정답',
    ),
    GradingResult(
      problemNumber: 10,
      recognizedAnswer: '3.5',
      correctStatus: '오답',
    ),
    GradingResult(
      problemNumber: 11,
      recognizedAnswer: '2',
      correctStatus: '정답',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _images = args['images'] as List<XFile>?;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _saveAnswers() {
    // TODO: 채점 결과를 API로 POST 구현
    // - 수정된 답안들을 서버에 전송
    // - 성공 응답을 받으면 홈으로 이동

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '저장 완료',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          '답안이 저장되었습니다.',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false); // 홈으로 이동
            },
            child: const Text(
              '확인',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                color: Color(0xFFAC5BF8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateAnswer() {
    if (_selectedProblemIndex != null && _answerController.text.isNotEmpty) {
      setState(() {
        _results[_selectedProblemIndex!].recognizedAnswer =
            _answerController.text;
        _isEditingAnswer = false;
        _answerController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(screenWidth, screenHeight),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.015),
                    _buildResultsTable(screenWidth, screenHeight),
                    if (_selectedProblemIndex != null) ...[
                      SizedBox(height: screenHeight * 0.02),
                      _buildProblemDetail(screenWidth, screenHeight),
                    ],
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
            _buildBottomButton(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.075,
        screenHeight * 0.021,
        screenWidth * 0.075,
        screenHeight * 0.012,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Color(0xFF5C5C5C),
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              '채점 결과',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF585B69),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable(double screenWidth, double screenHeight) {
    final unrecognizedCount = _results.where((r) => r.isUnrecognized).length;

    return Container(
      width: screenWidth * 0.9,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인식하지 못한 답: ${unrecognizedCount.toString().padLeft(2, '0')}개',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF585B69),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.047,
              vertical: screenHeight * 0.017,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: const Color(0xFFE1E7ED)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableColumn(
                  '문제 번호',
                  _results.map((r) => r.problemNumber.toString()).toList(),
                  const Color(0xFF585B69),
                ),
                Container(
                  width: 1,
                  height: screenHeight * 0.293, // 256/874
                  color: const Color(0xFFE1E7ED),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.087),
                ),
                _buildTableColumn(
                  '인식한 답',
                  _results.map((r) => r.recognizedAnswer).toList(),
                  const Color(0xFF7F818E),
                ),
                Container(
                  width: 1,
                  height: screenHeight * 0.293,
                  color: const Color(0xFFE1E7ED),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.087),
                ),
                _buildTableColumn(
                  '정답 여부',
                  _results.map((r) => r.correctStatus).toList(),
                  const Color(0xFF7F818E),
                  highlightWrong: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableColumn(
    String header,
    List<String> items,
    Color textColor, {
    bool highlightWrong = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: highlightWrong ? null : () {},
            child: Text(
              header,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF585B69),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(items.length, (index) {
            final isWrong = highlightWrong && items[index] == '오답';
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedProblemIndex = index;
                  _isEditingAnswer = false;
                  _answerController.clear();
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Text(
                  items[index],
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: highlightWrong
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 12,
                    color: isWrong ? const Color(0xFFFF4258) : textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProblemDetail(double screenWidth, double screenHeight) {
    if (_selectedProblemIndex == null) return const SizedBox.shrink();

    return Container(
      width: screenWidth * 0.9,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_results[_selectedProblemIndex!].problemNumber}번 문제',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF585B69),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditingAnswer = !_isEditingAnswer;
                    if (_isEditingAnswer) {
                      _answerController.text =
                          _results[_selectedProblemIndex!].recognizedAnswer;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    border: Border.all(color: const Color(0xFFE1E7ED)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '답안 재입력',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFF585B69),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.013),

          // 문제 이미지 표시
          if (_images != null && _selectedProblemIndex! < _images!.length)
            Container(
              width: screenWidth * 0.9,
              constraints: BoxConstraints(maxHeight: screenHeight * 0.3),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                border: Border.all(color: const Color(0xFFE1E7ED)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_images![_selectedProblemIndex!].path),
                  fit: BoxFit.contain,
                ),
              ),
            ),

          // 답안 입력 폼
          if (_isEditingAnswer) ...[
            SizedBox(height: screenHeight * 0.01),
            Container(
              width: screenWidth * 0.9,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFAC5BF8), width: 2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        hintText: '답안을 입력하세요',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF585B69),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _updateAnswer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '수정',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButton(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth * 0.851, // 342/402
      height: screenHeight * 0.057, // 50/874
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.075,
        vertical: screenHeight * 0.015,
      ),
      child: GestureDetector(
        onTap: () {
          if (_selectedProblemIndex != null && _isEditingAnswer) {
            _updateAnswer();
          } else {
            _saveAnswers();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
              begin: Alignment(0.0, -1.0),
              end: Alignment(0.0, 1.0),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: Text(
              (_selectedProblemIndex != null && _isEditingAnswer)
                  ? '답 수정하기'
                  : '답 저장하기',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
