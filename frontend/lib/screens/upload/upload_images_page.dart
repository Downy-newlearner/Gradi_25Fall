import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_header_title.dart';
import '../../widgets/app_header_menu_button.dart';

enum ProblemType {
  newProblem, // 새로 풀기
  correctMistakes, // 오답 수정
}

class UploadImagesPage extends StatefulWidget {
  const UploadImagesPage({super.key});

  @override
  State<UploadImagesPage> createState() => _UploadImagesPageState();
}

class _UploadImagesPageState extends State<UploadImagesPage> {
  List<XFile> _selectedImages = [];
  ProblemType? _selectedType;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (!mounted) return;

    setState(() {
      _selectedImages = images;
    });
  }

  void _registerProblems() {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지를 선택해주세요')));
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('문제 유형을 선택해주세요')));
      return;
    }

    // TODO: 채점 기능 구현 완료 후 API 호출 추가
    // - 선택된 이미지들을 서버에 전송
    // - 채점 결과를 받아서 EditGradingResultPage로 이동

    Navigator.pushNamed(
      context,
      '/upload/edit-result',
      arguments: {'images': _selectedImages, 'problemType': _selectedType},
    );
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.015),
                    _buildImageGrid(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const AppHeader(
      title: AppHeaderTitle('이미지 업로드', textAlign: TextAlign.center),
      trailing: AppHeaderMenuButton(),
    );
  }

  Widget _buildImageGrid(double screenWidth, double screenHeight) {
    if (_selectedImages.isEmpty) {
      return Container(
        width: screenWidth * 0.866, // 348/402
        height: screenHeight * 0.375, // 328/874
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.067),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1E7ED)),
        ),
        child: const Center(
          child: Text(
            '이미지를 선택해주세요',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF7F818E),
            ),
          ),
        ),
      );
    }

    // 4x4 그리드 레이아웃
    final gridWidth = screenWidth * 0.866; // 348/402
    final itemWidth = (gridWidth - 3 * 8) / 4; // 4개 열, 간격 8
    final itemHeight = itemWidth * 0.938; // 76/81 비율

    return Container(
      width: gridWidth,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.067),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          _selectedImages.length > 16 ? 16 : _selectedImages.length,
          (index) => Container(
            width: itemWidth,
            height: itemHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE1E7ED)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(_selectedImages[index].path),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(double screenWidth, double screenHeight) {
    final buttonHeight = screenHeight * 0.045; // 39/874

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.072,
        vertical: screenHeight * 0.015,
      ),
      child: Row(
        children: [
          // 새로 풀기 버튼
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = ProblemType.newProblem;
                });
              },
              child: Container(
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  border: Border.all(
                    color: _selectedType == ProblemType.newProblem
                        ? const Color(0xFFAC5BF8)
                        : const Color(0xFFE1E7ED),
                    width: _selectedType == ProblemType.newProblem ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Center(
                  child: Text(
                    '새로 풀기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF585B69),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.02),

          // 중앙 버튼 (이미지 가져오기 / 문제 등록)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _selectedImages.isEmpty ? _pickImages : _registerProblems,
              child: Container(
                height: buttonHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAC5BF8), Color(0xFF636ACF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    _selectedImages.isEmpty ? '이미지 가져오기' : '문제 등록',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFFF8F9FA),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.02),

          // 오답 수정 버튼
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = ProblemType.correctMistakes;
                });
              },
              child: Container(
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  border: Border.all(
                    color: _selectedType == ProblemType.correctMistakes
                        ? const Color(0xFFAC5BF8)
                        : const Color(0xFFE1E7ED),
                    width: _selectedType == ProblemType.correctMistakes ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Center(
                  child: Text(
                    '오답 수정',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF585B69),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
