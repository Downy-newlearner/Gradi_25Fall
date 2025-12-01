import 'package:flutter/material.dart';
import '../../domain/student_answer/get_student_answers_for_response_use_case.dart';
import '../../domain/student_answer/update_student_answers_use_case.dart';
import '../../domain/student_answer/student_answer_update.dart';
import '../../domain/section_image/get_section_image_use_case.dart';
import 'models/grading_result.dart';

class EditGradingResultPage extends StatefulWidget {
  final int studentResponseId; // 필수 파라미터
  final int academyUserId; // 추가
  final GetStudentAnswersForResponseUseCase getStudentAnswersUseCase;
  final UpdateStudentAnswersUseCase updateStudentAnswersUseCase;
  final GetSectionImageUseCase getSectionImageUseCase; // 추가

  const EditGradingResultPage({
    super.key,
    required this.studentResponseId,
    required this.academyUserId, // 추가
    required this.getStudentAnswersUseCase,
    required this.updateStudentAnswersUseCase,
    required this.getSectionImageUseCase, // 추가
  });

  @override
  State<EditGradingResultPage> createState() => _EditGradingResultPageState();
}

class _EditGradingResultPageState extends State<EditGradingResultPage> {
  // 상태 변수
  bool _isLoading = false;
  bool _isSaving = false; // 저장 중 상태 추가
  String? _errorMessage;
  List<GradingResult> _results = [];
  List<GradingResult> _originalResults = []; // 원본 데이터 (수정 여부 판단용)

  // UI 상태
  int? _selectedProblemIndex;
  final TextEditingController _answerController = TextEditingController();
  bool _isEditingAnswer = false;

  // Section 이미지 캐싱 및 상태 관리
  final Map<String, String?> _sectionImageUrls = {}; // 캐시: cacheKey -> imageUrl
  final Map<String, bool> _imageLoadingStates = {}; // 로딩 상태
  final Map<String, String?> _imageErrors = {}; // 에러 메시지

  @override
  void initState() {
    super.initState();
    _loadStudentAnswers();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  /// API로 학생 답안 데이터 로드
  Future<void> _loadStudentAnswers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entities = await widget.getStudentAnswersUseCase.call(
        widget.studentResponseId,
      );

      if (!mounted) return;

      // Entity를 UI 모델로 변환
      final results = entities
          .map((entity) => GradingResult.fromEntity(entity))
          .toList();

      // 정렬: (questionNumber, subQuestionNumber) 튜플 정렬
      results.sort((a, b) {
        final questionCompare = a.questionNumber.compareTo(b.questionNumber);
        if (questionCompare != 0) return questionCompare;
        return a.subQuestionNumber.compareTo(b.subQuestionNumber);
      });

      setState(() {
        _results = results;
        _originalResults = results
            .map(
              (r) => GradingResult(
                questionNumber: r.questionNumber,
                subQuestionNumber: r.subQuestionNumber,
                studentAnswerId: r.studentAnswerId,
                recognizedAnswer: r.recognizedAnswer,
                correctStatus: r.correctStatus,
              ),
            )
            .toList(); // 깊은 복사
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '답안 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.';
        _isLoading = false;
      });
    }
  }

  /// 수정된 답안들을 서버에 저장
  Future<void> _saveAnswers() async {
    // 수정된 항목만 추려서 payload 생성
    final updates = <StudentAnswerUpdate>[];
    for (int i = 0; i < _results.length; i++) {
      final current = _results[i];
      final original = _originalResults[i];

      if (current.recognizedAnswer != original.recognizedAnswer) {
        updates.add(
          StudentAnswerUpdate(
            studentAnswerId: current.studentAnswerId,
            newAnswer: current.recognizedAnswer,
          ),
        );
      }
    }

    if (updates.isEmpty) {
      // 수정된 항목이 없으면 그냥 닫기
      Navigator.of(context).pop();
      return;
    }

    // 저장 중 상태 설정
    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    try {
      await widget.updateStudentAnswersUseCase.call(updates);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      // 성공 시 다이얼로그 표시 후 닫기
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
                Navigator.of(context).pop(); // Edit 페이지 닫기
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      // 에러 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('저장 실패'),
          content: Text('답안 저장에 실패했습니다. 잠시 후 다시 시도해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
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

  /// Section 이미지 로드
  ///
  /// 문제 번호를 클릭했을 때 호출됩니다.
  /// 캐시에 있으면 재요청하지 않고, 로딩 중이면 중복 요청을 방지합니다.
  Future<void> _loadSectionImage(
    int questionNumber,
    int subQuestionNumber,
  ) async {
    // 캐시 키 생성: subQuestionNumber가 0이면 questionNumber만, 아니면 "questionNumber-subQuestionNumber"
    final cacheKey = subQuestionNumber == 0
        ? questionNumber.toString()
        : '$questionNumber-$subQuestionNumber';

    // 이미 캐시에 있거나 로딩 중이면 스킵
    if (_sectionImageUrls.containsKey(cacheKey) ||
        _imageLoadingStates[cacheKey] == true) {
      return;
    }

    // 로딩 상태 설정
    if (!mounted) return;
    setState(() {
      _imageLoadingStates[cacheKey] = true;
      _imageErrors[cacheKey] = null;
    });

    try {
      // UseCase 호출
      final entity = await widget.getSectionImageUseCase.call(
        academyUserId: widget.academyUserId,
        studentResponseId: widget.studentResponseId,
        questionNumber: questionNumber,
        subQuestionNumber: subQuestionNumber,
      );

      if (!mounted) return;

      setState(() {
        _imageLoadingStates[cacheKey] = false;
        if (entity == null) {
          // 이미지가 없는 경우 (404) - 정상 케이스
          _imageErrors[cacheKey] = '이미지가 없습니다.';
        } else {
          // 이미지 URL 저장
          _sectionImageUrls[cacheKey] = entity.imageUrl;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _imageLoadingStates[cacheKey] = false;
        _imageErrors[cacheKey] = '이미지를 불러오지 못했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 로딩 상태 (초기 로딩)
    if (_isLoading && _results.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 에러 상태
    if (_errorMessage != null && _results.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              ElevatedButton(
                onPressed: _loadStudentAnswers,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
            // 저장 중 오버레이
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
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
    final unrecognizedCount = _results.where((r) => r.isEmptyAnswer).length;

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
                  _results
                      .map((r) => r.displayNumber)
                      .toList(), // displayNumber 사용
                  const Color(0xFF585B69),
                ),
                Container(
                  width: 1,
                  height: screenHeight * 0.293,
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
                // 문제 번호 컬럼에서만 이미지 로드
                if (!highlightWrong) {
                  final result = _results[index];
                  _loadSectionImage(
                    result.questionNumber,
                    result.subQuestionNumber,
                  );
                }
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
                '${_results[_selectedProblemIndex!].displayNumber}번 문제',
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

          // 문제 이미지 표시 (네트워크 이미지)
          Builder(
            builder: (context) {
              final result = _results[_selectedProblemIndex!];
              final cacheKey = result.subQuestionNumber == 0
                  ? result.questionNumber.toString()
                  : '${result.questionNumber}-${result.subQuestionNumber}';

              final imageUrl = _sectionImageUrls[cacheKey];
              final isLoading = _imageLoadingStates[cacheKey] == true;
              final errorMessage = _imageErrors[cacheKey];

              // 로딩 중
              if (isLoading) {
                return Container(
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    border: Border.all(color: const Color(0xFFE1E7ED)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              // 에러 (이미지 없음 또는 로드 실패)
              if (errorMessage != null) {
                return Container(
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    border: Border.all(color: const Color(0xFFE1E7ED)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Color(0xFF999999),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 이미지 표시
              if (imageUrl != null) {
                return Container(
                  width: screenWidth * 0.9,
                  constraints: BoxConstraints(maxHeight: screenHeight * 0.3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    border: Border.all(color: const Color(0xFFE1E7ED)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF8F9FA),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Color(0xFF999999),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '이미지를 불러오지 못했습니다.',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }

              // 이미지가 아직 로드되지 않음 (초기 상태)
              return const SizedBox.shrink();
            },
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
      width: screenWidth * 0.851,
      height: screenHeight * 0.057,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.075,
        vertical: screenHeight * 0.015,
      ),
      child: GestureDetector(
        onTap: _isSaving
            ? null // 저장 중에는 클릭 불가
            : () {
                if (_selectedProblemIndex != null && _isEditingAnswer) {
                  _updateAnswer();
                } else {
                  _saveAnswers();
                }
              },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSaving
                  ? [Colors.grey, Colors.grey] // 저장 중에는 회색
                  : const [Color(0xFFAC5BF8), Color(0xFF636ACF)],
              begin: const Alignment(0.0, -1.0),
              end: const Alignment(0.0, 1.0),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: Text(
              _isSaving
                  ? '저장 중...'
                  : (_selectedProblemIndex != null && _isEditingAnswer)
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
