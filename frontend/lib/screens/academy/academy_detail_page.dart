import 'package:flutter/material.dart';
import 'academy_list_page.dart';
import '../../services/academy_service.dart';
import '../../services/auth_service.dart';
import 'dart:developer' as developer;

class AcademyDetailPage extends StatefulWidget {
  final AcademyData academy;

  const AcademyDetailPage({super.key, required this.academy});

  @override
  State<AcademyDetailPage> createState() => _AcademyDetailPageState();
}

class _AcademyDetailPageState extends State<AcademyDetailPage> {
  final AcademyService _academyService = AcademyService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(context),

            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 학원 이미지
                    _buildAcademyImage(),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 학원 기본 정보 카드
                          _buildAcademyInfo(),

                          const SizedBox(height: 16),

                          // 학원 소개
                          _buildAcademyDescription(),

                          const SizedBox(height: 32),

                          // 등록 버튼
                          _buildRegisterButton(context),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 10),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF333333),
              size: 24,
            ),
          ),

          // 제목 - 학원명과 ID
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.academy.name,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF333333),
                  ),
                ),
                TextSpan(
                  text: ' #DF850',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // 햄버거 메뉴
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF333333)),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('메뉴 기능 구현 예정')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAcademyImage() {
    return Container(
      width: double.infinity,
      height: 200,
      color: const Color(0xFFE0E5EB),
      child: const Center(
        child: Text(
          '학원 이미지 영역',
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

  Widget _buildAcademyInfo() {
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
          // 주소 섹션
          _buildInfoRow(Icons.location_on, '주소', widget.academy.address),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE9ECEF), height: 1),
          const SizedBox(height: 16),

          // 과목 섹션
          _buildInfoRow(Icons.menu_book, '과목', '초·중등 수학, 영어, 논술'),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE9ECEF), height: 1),
          const SizedBox(height: 16),

          // 영업시간 섹션
          _buildOperatingHours(),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE9ECEF), height: 1),
          const SizedBox(height: 16),

          // 연락처 섹션
          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF666666), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHours() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.access_time, color: Color(0xFF666666), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '영업시간',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '월요일 - 금요일 : 9:00 AM - 8:00 PM',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '토요일 : 10:00 AM - 6:00 PM',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '일요일 : 12:00 PM - 5:00 PM',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.phone, color: Color(0xFF666666), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '연락처',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Phone: (555) 123-4567',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Email: info@grandlibrary.org',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Website: www.grandlibrary.org',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademyDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${widget.academy.name}은(는) 입시와 공무원 시험에 특화된 전문 교육 기관입니다. 체계적인 커리큘럼과 1:1 맞춤형 학습 관리로 높은 합격률을 자랑합니다. 단국대학교 죽전캠퍼스에서 ${widget.academy.distance} 거리에 위치하고 있습니다.',
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Color(0xFF666666),
          height: 1.6,
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // academyId가 없는 경우 처리
    if (widget.academy.academyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학원 정보가 올바르지 않습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // user_id 가져오기
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다. 다시 로그인해주세요.');
      }

      // 학원 등록 요청
      // [2025.11.12]
      // - class_id: 어떤 반인지 (반 정보) - 현재는 0으로 설정 (추후 입력 필드 추가 예정)
      // - learner_id: 학번 (학원에서 학번을 제공하는 경우 사용할 예정) - 현재는 0으로 설정 (추후 입력 필드 추가 예정)
      await _academyService.joinAcademyRequest(
        academyId: widget.academy.academyId!,
        classId: 0, // TODO: 추후 반 선택 UI 추가 필요
        userId: int.parse(userId),
        learnerId: 0, // TODO: 추후 학번 입력 UI 추가 필요
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.academy.name} 등록 요청이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 등록 성공 후 이전 페이지로 돌아가기 (성공 여부 전달)
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      developer.log('Error registering academy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRegisterButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '학원 등록하기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
