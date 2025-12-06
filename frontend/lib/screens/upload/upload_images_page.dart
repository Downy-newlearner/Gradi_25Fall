import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../services/upload_batch_service.dart';
import '../../services/upload_sse_service.dart';
import '../../services/academy_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_header_title.dart';
import '../../widgets/app_header_menu_button.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_logger.dart';

enum ProblemType {
  newProblem, // 새로 풀기
  correctMistakes, // 오답 수정
}

enum UploadPageAcademyState {
  checking, // 학원 정보 확인 중
  hasAcademy,
  noAcademy,
  error, // 학원 정보를 불러오지 못함
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
  final getIt = GetIt.instance;

  late final UploadSseService _sseService = getIt<UploadSseService>();
  late final AcademyService _academyService = getIt<AcademyService>();
  late final AuthService _authService = getIt<AuthService>();
  final Queue<XFile> _pendingUploads = Queue<XFile>();

  bool _isSseConnecting = false;
  bool _isUploading = false;
  String? _uploadError;
  String? _uploadSuccessMessage;
  int? _uploadedCount;
  int? _totalCount;
  UploadPageAcademyState _academyState = UploadPageAcademyState.checking;

  /// 메인 네비게이션에서 탭을 다시 선택했을 때
  /// 업로드 페이지 상태를 초기화하기 위한 메서드
  void refresh() {
    setState(() {
      _selectedImages = [];
      _selectedType = null;
      _pendingUploads.clear();
      _isUploading = false;
      _uploadError = null;
      _uploadSuccessMessage = null;
      _uploadedCount = null;
      _totalCount = null;
      _academyState = UploadPageAcademyState.checking;
    });

    // 학원 정보 다시 확인
    _checkAcademyState();
  }

  @override
  void initState() {
    super.initState();
    _checkAcademyState();
    _connectSse();
  }

  @override
  void dispose() {
    _sseService.dispose();
    super.dispose();
  }

  Future<void> _connectSse() async {
    setState(() {
      _isSseConnecting = true;
    });
    try {
      await _sseService.connect();
      _sseService.uploadUrlStream.listen(_onUploadUrlReceived);
    } catch (e) {
      debugPrint('SSE connect error: $e');
      setState(() {
        _uploadError = '실시간 업로드 채널 연결에 실패했습니다. 다시 시도해주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSseConnecting = false;
        });
      }
    }
  }

  Future<void> _onUploadUrlReceived(String url) async {
    if (_pendingUploads.isEmpty) {
      debugPrint('Upload URL received but no pending images. url=$url');
      return;
    }

    final file = _pendingUploads.removeFirst();
    try {
      final bytes = await file.readAsBytes();
      final response = await http.put(
        Uri.parse(url),
        headers: {
          // 서버에서 별도 Content-Type 요구 시 확장자 기반으로 조정 가능
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      );

      debugPrint('Uploaded ${file.path} → ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('이미지 업로드 실패 (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        _uploadError = '이미지 업로드 중 오류가 발생했습니다: $e';
      });
      debugPrint('Upload error: $e');
    } finally {
      if (_pendingUploads.isEmpty && mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (!mounted) return;

    setState(() {
      _selectedImages = images;
    });
  }

  /// 문제 등록 성공 다이얼로그 표시
  Future<void> _showSuccessDialog() async {
    if (!mounted) return;

    final timestamp = DateTime.now().toIso8601String();
    appLog('[UploadImagesPage][timecheck][$timestamp] 문제 등록 완료 팝업 표시');

    await showDialog(
      context: context,
      barrierDismissible: false, // 배경 탭으로 닫기 방지
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '문제 등록 완료',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            '문제 등록이 완료되었습니다. 채점이 완료되면 알림으로 알려드릴게요!',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.mainNavigation,
                      (route) => false, // 모든 이전 라우트 제거
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAC5BF8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '네, 알겠어요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerProblems() async {
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

    if (_academyState == UploadPageAcademyState.checking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학원 정보를 확인하는 중입니다. 잠시만 기다려주세요.')),
      );
      return;
    }

    if (_academyState == UploadPageAcademyState.noAcademy) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('학원 등록을 먼저 해주세요.')));
      return;
    }

    if (_isSseConnecting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업로드 채널을 준비 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    appLog(
      '[UploadImagesPage][timecheck][$timestamp] 문제 등록 요청 시작 - imageCount=${_selectedImages.length}, type=$_selectedType',
    );

    setState(() {
      _uploadError = null;
      _uploadSuccessMessage = null;
      _uploadedCount = 0;
      _totalCount = _selectedImages.length;
      _isUploading = true;
    });

    try {
      debugPrint(
        '[UploadImagesPage] 🚀 업로드 시작: ${_selectedImages.length}개 이미지',
      );

      // uploadImages 외부 함수 사용 (진행 상황 콜백 포함)
      final response = await uploadImages(
        images: _selectedImages,
        onProgress: (uploadedCount, totalCount) {
          debugPrint(
            '[UploadImagesPage] 📤 업로드 진행: $uploadedCount/$totalCount',
          );
          if (mounted) {
            setState(() {
              _uploadedCount = uploadedCount;
              _totalCount = totalCount;
            });
          }
        },
      );

      appLog(
        '[UploadImagesPage][timecheck] ✅ 업로드 완료 - studentResponseId=${response.studentResponseId}, total=${_selectedImages.length}',
      );

      debugPrint(
        '[UploadImagesPage] ✅ 업로드 완료: studentResponseId=${response.studentResponseId}',
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadedCount = _selectedImages.length;
        });

        // 성공 팝업 표시
        _showSuccessDialog();
      }
    } on NoAcademyException catch (e) {
      debugPrint('[UploadImagesPage] ❌ 업로드 실패(학원 없음): $e');
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _academyState = UploadPageAcademyState.noAcademy;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('[UploadImagesPage] ❌ 업로드 실패: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('문제 등록 요청에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAcademyState() async {
    setState(() {
      _academyState = UploadPageAcademyState.checking;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _academyState = UploadPageAcademyState.error;
        });
        return;
      }

      final academies = await _academyService.getUserAcademies(userId);
      final registered = academies
          .where((a) => a.registerStatus == 'Y')
          .toList();

      if (!mounted) return;
      setState(() {
        _academyState = registered.isEmpty
            ? UploadPageAcademyState.noAcademy
            : UploadPageAcademyState.hasAcademy;
      });
    } catch (e) {
      debugPrint('[UploadImagesPage] 학원 상태 조회 실패: $e');
      if (!mounted) return;
      setState(() {
        _academyState = UploadPageAcademyState.error;
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
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  refresh();
                },
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Pull-to-refresh를 위해 항상 스크롤 가능하도록
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.015),
                      _buildImageGrid(screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_academyState == UploadPageAcademyState.noAcademy) ...[
                const Text(
                  '학원 등록을 먼저 해주세요.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF7F818E),
                  ),
                ),
              ] else if (_academyState == UploadPageAcademyState.error) ...[
                const Text(
                  '학원 정보를 불러오지 못했어요.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF7F818E),
                  ),
                ),
              ] else if (_academyState == UploadPageAcademyState.checking) ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 8),
                const Text(
                  '학원 정보를 확인하는 중입니다...',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF7F818E),
                  ),
                ),
              ] else ...[
                const Text(
                  '이미지를 선택해주세요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF7F818E),
                  ),
                ),
              ],
              if (_uploadError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _uploadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFFFF4258),
                  ),
                ),
              ],
              if (_uploadSuccessMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _uploadSuccessMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
              if (_isUploading && _totalCount != null) ...[
                const SizedBox(height: 8),
                Text(
                  '업로드 중: ${_uploadedCount ?? 0}/$_totalCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFFAC5BF8),
                  ),
                ),
              ],
            ],
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
                    () {
                      if (_selectedImages.isEmpty) {
                        if (_academyState == UploadPageAcademyState.noAcademy) {
                          return '학원 등록 필요';
                        }
                        if (_academyState == UploadPageAcademyState.checking) {
                          return '학원 정보 확인 중...';
                        }
                        if (_academyState == UploadPageAcademyState.error) {
                          return '다시 시도';
                        }
                        return '이미지 가져오기';
                      }

                      if (_isUploading) {
                        if (_uploadedCount != null && _totalCount != null) {
                          return '업로드 중... ($_uploadedCount/$_totalCount)';
                        }
                        return '업로드 중...';
                      }

                      return '문제 등록';
                    }(),
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
