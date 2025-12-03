import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'academy_list_page.dart';
import '../../services/academy_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_logger.dart';

class AcademyDetailPage extends StatefulWidget {
  final AcademyData academy;

  const AcademyDetailPage({super.key, required this.academy});

  @override
  State<AcademyDetailPage> createState() => _AcademyDetailPageState();
}

class _AcademyDetailPageState extends State<AcademyDetailPage> {
  final GetIt _getIt = GetIt.instance;

  late final AcademyService _academyService;
  late final AuthService _authService;
  bool _isLoading = false;

  // 학원 스케줄 관련 상태
  AcademyScheduleResponse? _academySchedule;
  bool _isLoadingSchedule = false;
  String? _scheduleError;

  // 학원 이미지 관련 상태
  List<String> _academyImageUrls = [];
  bool _isLoadingImages = false;
  String? _imageError;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _academyService = _getIt<AcademyService>();
    _authService = _getIt<AuthService>();
    _loadAcademySchedule();
    _loadAcademyImages();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  /// 학원 스케줄 데이터 로드
  Future<void> _loadAcademySchedule() async {
    appLog('[academy:academy_detail_page] _loadAcademySchedule 시작');

    // academyCode null 체크 (String? 타입이므로 필요)
    if (widget.academy.academyCode == null) {
      appLog('[academy:academy_detail_page] academyCode가 null');
      if (!mounted) return;
      setState(() {
        _scheduleError = '학원 코드가 없습니다.';
      });
      return;
    }

    appLog(
      '[academy:academy_detail_page] academyCode: ${widget.academy.academyCode}',
    );

    if (!mounted) return;
    setState(() {
      _isLoadingSchedule = true;
      _scheduleError = null;
    });

    try {
      final schedule = await _academyService.getAcademySchedule(
        widget.academy.academyCode!,
      );

      appLog(
        '[academy:academy_detail_page] API 호출 완료 - academyName: ${schedule.academy.academyName}, schedules 개수: ${schedule.schedules.length}',
      );

      // 스케줄 상세 로그
      for (final s in schedule.schedules) {
        appLog(
          '[academy:academy_detail_page]   Schedule - dayOfWeek: ${s.dayOfWeek} (${s.dayName}), startTime: ${s.startTime}, endTime: ${s.endTime}',
        );
      }

      if (!mounted) return;
      setState(() {
        _academySchedule = schedule;
        _isLoadingSchedule = false;
      });

      appLog('[academy:academy_detail_page] UI 업데이트 완료');
    } catch (e) {
      appLog('[academy:academy_detail_page] 에러 발생: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingSchedule = false;
        // 사용자용 간단한 메시지 (상세 에러는 로그에만)
        _scheduleError = '학원 정보를 가져오지 못했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  /// 학원 이미지 데이터 로드
  Future<void> _loadAcademyImages() async {
    // academyCode null 체크
    if (widget.academy.academyCode == null) {
      if (!mounted) return;
      setState(() {
        _imageError = '학원 코드가 없습니다.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingImages = true;
      _imageError = null;
    });

    try {
      final imageResponse = await _academyService.getAcademyImages(
        widget.academy.academyCode!,
      );

      if (!mounted) return;
      setState(() {
        _academyImageUrls = imageResponse.academyImageUrls;
        _isLoadingImages = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingImages = false;
        _imageError = '이미지를 가져오지 못했습니다.';
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
                if (widget.academy.academyCode != null)
                  TextSpan(
                    text: ' #${widget.academy.academyCode}',
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
    // 로딩 상태
    if (_isLoadingImages) {
      return Container(
        width: double.infinity,
        height: 200,
        color: const Color(0xFFE0E5EB),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 에러 상태 또는 이미지가 없는 경우
    if (_imageError != null || _academyImageUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        color: const Color(0xFFE0E5EB),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 48,
                color: Color(0xFF999999),
              ),
              const SizedBox(height: 8),
              Text(
                _imageError ?? '이미지가 없습니다.',
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

    // 이미지가 1개인 경우 슬라이더 없이 표시
    if (_academyImageUrls.length == 1) {
      return Container(
        width: double.infinity,
        height: 200,
        child: Image.network(
          _academyImageUrls[0],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFE0E5EB),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Color(0xFF999999),
                ),
              ),
            );
          },
        ),
      );
    }

    // 이미지가 여러 개인 경우 슬라이더로 표시
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Stack(
        children: [
          // 이미지 슬라이더
          PageView.builder(
            controller: _imagePageController,
            itemCount: _academyImageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                _academyImageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE0E5EB),
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Color(0xFF999999),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // 인디케이터 (하단 중앙)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_academyImageUrls.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
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
          _buildInfoRow(
            Icons.location_on,
            '주소',
            _academySchedule?.academy != null
                ? '${_academySchedule!.academy.academyRoadAddress} ${_academySchedule!.academy.academyDetailAddress}'
                      .trim()
                : widget.academy.address,
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE9ECEF), height: 1),
          const SizedBox(height: 16),

          // 소개 섹션
          _buildInfoRow(
            Icons.info_outline,
            '소개',
            _academySchedule?.academy != null &&
                    _academySchedule!.academy.academyDescription.isNotEmpty
                ? _academySchedule!.academy.academyDescription
                : '${widget.academy.name}에 대한 소개 정보가 없습니다.',
          ),

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
    // 로딩 상태
    if (_isLoadingSchedule) {
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
                  '영업시간을 불러오는 중입니다...',
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

    // 에러 상태
    if (_scheduleError != null) {
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
                  '영업시간 정보를 가져오지 못했습니다.',
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

    // 스케줄이 없는 경우
    if (_academySchedule == null || _academySchedule!.schedules.isEmpty) {
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
                  '등록된 영업시간이 없습니다.',
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

    // 스케줄 그룹핑 및 정렬
    final schedules = _academySchedule!.schedules;

    // dayOfWeek 기준으로 그룹핑
    final Map<int, List<Schedule>> groupedByDay = {};
    for (final schedule in schedules) {
      if (schedule.dayOfWeek >= 0 && schedule.dayOfWeek <= 6) {
        groupedByDay.putIfAbsent(schedule.dayOfWeek, () => []);
        groupedByDay[schedule.dayOfWeek]!.add(schedule);
      }
    }

    // 요일별로 startTime 오름차순 정렬 (문자열 비교, HH:MM:SS 포맷 전제)
    groupedByDay.forEach((day, daySchedules) {
      daySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    // 요일 순서: 월요일(1) ~ 토요일(6), 일요일(0)은 마지막
    final sortedDays = groupedByDay.keys.toList()
      ..sort((a, b) {
        if (a == 0) return 1; // 일요일은 뒤로
        if (b == 0) return -1;
        return a.compareTo(b);
      });

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
              // 요일별로 표시
              ...sortedDays.map((day) {
                final daySchedules = groupedByDay[day]!;
                final dayName = daySchedules.first.dayName;
                final timeRanges = daySchedules
                    .map(
                      (s) => '${s.formattedStartTime} - ${s.formattedEndTime}',
                    )
                    .join(', ');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '$dayName : $timeRanges',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    final academy = _academySchedule?.academy;
    final phone = (academy?.academyPhone.isNotEmpty == true)
        ? academy!.academyPhone
        : '전화 정보가 없습니다.';
    final email = (academy?.academyEmail.isNotEmpty == true)
        ? academy!.academyEmail
        : '이메일 정보가 없습니다.';
    final website = (academy?.academyWebsite.isNotEmpty == true)
        ? academy!.academyWebsite
        : '웹사이트 정보가 없습니다.';

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
              Text(
                'Phone: $phone',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Email: $email',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Website: $website',
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

  Future<void> _handleRegister() async {
    // academyCode가 없는 경우 처리
    if (widget.academy.academyCode == null) {
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
      await _academyService.joinAcademyRequest(
        academy_id: widget.academy.academyCode!,
        user_id: int.parse(userId),
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
