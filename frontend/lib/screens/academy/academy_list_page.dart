import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';
import '../../services/location_service.dart';
import '../../services/academy_service.dart';
import 'dart:developer' as developer;

class AcademyListPage extends StatefulWidget {
  const AcademyListPage({super.key});

  @override
  State<AcademyListPage> createState() => _AcademyListPageState();
}

class _AcademyListPageState extends State<AcademyListPage> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final AcademyService _academyService = AcademyService();

  List<AcademyData> _filteredAcademies = [];
  List<AcademyData> _allAcademies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNearbyAcademies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 근처 학원 리스트 조회
  Future<void> _fetchNearbyAcademies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 현재 위치 가져오기
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '위치 정보를 가져올 수 없습니다. 위치 권한을 확인해주세요.';
        });
        return;
      }

      // API 호출하여 근처 학원 리스트 가져오기
      final academies = await _academyService.getNearbyAcademies(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // 응답 데이터를 AcademyData로 변환
      _allAcademies = academies.map((academy) {
        return AcademyData(
          name: academy.academyName,
          distance: '${academy.distanceKm.toStringAsFixed(1)}km',
          address: academy.academyRoadAddress,
          thumbnail: 'assets/images/academy1.jpg', // 기본 썸네일
          academyId: academy.academyId,
        );
      }).toList();

      // 거리순으로 정렬 (이미 서버에서 정렬되어 있을 수 있지만 확실히 하기 위해)
      _allAcademies.sort((a, b) {
        final distanceA = double.parse(a.distance.replaceAll('km', ''));
        final distanceB = double.parse(b.distance.replaceAll('km', ''));
        return distanceA.compareTo(distanceB);
      });

      setState(() {
        _filteredAcademies = _allAcademies;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching nearby academies: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAcademies = _allAcademies;
      } else {
        _filteredAcademies = _allAcademies
            .where(
              (academy) =>
                  academy.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
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
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.03,
                    ),

                    // 검색바
                    _buildSearchBar(),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.03,
                    ),

                    // 학원 목록 또는 로딩/에러 상태
                    _isLoading
                        ? _buildLoadingState()
                        : _errorMessage != null
                        ? _buildErrorState()
                        : _buildAcademyList(),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.025,
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.05,
        MediaQuery.of(context).size.height * 0.021,
        MediaQuery.of(context).size.width * 0.05,
        MediaQuery.of(context).size.height * 0.012,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CustomBackButton(),
              const SizedBox(width: 20),
              const Text(
                '학원 등록하기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF333333)),
            onPressed: () {
              // TODO: 메뉴 기능 구현
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('메뉴 기능 구현 예정')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.045,
        minHeight: 30,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: const InputDecoration(
          hintText: '학원 이름을 등록해주세요',
          hintStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Color(0xFF666666),
          ),
          prefixIcon: Icon(Icons.search, color: Color(0xFF666666), size: 23),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '근처 학원을 찾는 중...',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFADADAD)),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '오류가 발생했습니다',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchNearbyAcademies,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademyList() {
    if (_filteredAcademies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text(
            '근처에 학원이 없습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        const Text(
          '현위치 근처에 있는 학원이에요',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF333333),
          ),
        ),

        const SizedBox(height: 16),

        // 학원 카드 목록
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredAcademies.length,
          separatorBuilder: (context, index) =>
              Container(height: MediaQuery.of(context).size.height * 0.02),
          itemBuilder: (context, index) {
            return _buildAcademyCard(_filteredAcademies[index]);
          },
        ),
      ],
    );
  }

  Widget _buildAcademyCard(AcademyData academy) {
    return GestureDetector(
      onTap: () async {
        // 학원 상세 페이지로 이동하고 등록 성공 여부를 받음
        final result = await Navigator.pushNamed(
          context,
          '/academy/detail',
          arguments: academy,
        );
        // 등록 성공 시 academy_page의 캐시 갱신을 위해 결과 전달
        if (result == true && mounted) {
          // academy_list_page에서 academy_page로 결과 전달
          Navigator.of(context).pop(true);
        }
      },
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // 학원 썸네일
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.25,
                minWidth: 80,
                maxHeight: MediaQuery.of(context).size.width * 0.25,
                minHeight: 80,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF666666),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 40),
            ),

            Container(width: MediaQuery.of(context).size.width * 0.04),

            // 학원 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 학원명
                  Text(
                    academy.name,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.035),

                  // 거리와 주소
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        academy.distance,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xFFADADAD),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.005,
                      ),
                      Text(
                        academy.address,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xFFADADAD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AcademyData {
  final String name;
  final String distance;
  final String address;
  final String thumbnail;
  final int? academyId; // 학원 ID

  AcademyData({
    required this.name,
    required this.distance,
    required this.address,
    required this.thumbnail,
    this.academyId,
  });
}
