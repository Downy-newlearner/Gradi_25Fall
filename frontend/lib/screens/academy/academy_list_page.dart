import 'package:flutter/material.dart';
import '../widgets/back_button.dart';

class AcademyListPage extends StatefulWidget {
  const AcademyListPage({super.key});

  @override
  State<AcademyListPage> createState() => _AcademyListPageState();
}

class _AcademyListPageState extends State<AcademyListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AcademyData> _filteredAcademies = [];
  List<AcademyData> _allAcademies = [];

  @override
  void initState() {
    super.initState();
    _initializeAcademies();
    _filteredAcademies = _allAcademies;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  // TODO: Implement logic to fetch information of 20 nearby academies from the database.
  // Details:
  // - The academies should be displayed in order of proximity.
  // - Implement a search functionality where typing "이투스" in the search bar
  //   will display all academies with "이투스" in their name.

  void _initializeAcademies() {
    _allAcademies = [
      AcademyData(
        name: '정다훈 영어학원',
        distance: '0.5km',
        address: '경기도 용인시 기흥구 죽전로 152',
        thumbnail: 'assets/images/academy1.jpg',
      ),
      AcademyData(
        name: '청담어학원 죽전캠퍼스',
        distance: '0.8km',
        address: '경기도 용인시 기흥구 죽전로 200',
        thumbnail: 'assets/images/academy2.jpg',
      ),
      AcademyData(
        name: '메가스터디 영어학원',
        distance: '1.2km',
        address: '경기도 용인시 기흥구 죽전로 300',
        thumbnail: 'assets/images/academy3.jpg',
      ),
      AcademyData(
        name: '대성마이맥 영어학원',
        distance: '1.5km',
        address: '경기도 용인시 기흥구 신갈로 100',
        thumbnail: 'assets/images/academy4.jpg',
      ),
      AcademyData(
        name: '이투스 영어학원',
        distance: '2.0km',
        address: '경기도 용인시 기흥구 신갈로 200',
        thumbnail: 'assets/images/academy5.jpg',
      ),
      AcademyData(
        name: '청심영어학원',
        distance: '2.3km',
        address: '경기도 용인시 기흥구 보정로 50',
        thumbnail: 'assets/images/academy6.jpg',
      ),
      AcademyData(
        name: '윤선생 영어학원',
        distance: '2.8km',
        address: '경기도 용인시 기흥구 보정로 150',
        thumbnail: 'assets/images/academy7.jpg',
      ),
      AcademyData(
        name: '파고다 영어학원',
        distance: '3.1km',
        address: '경기도 용인시 기흥구 보정로 250',
        thumbnail: 'assets/images/academy8.jpg',
      ),
      AcademyData(
        name: 'YBM 영어학원',
        distance: '3.5km',
        address: '경기도 용인시 기흥구 구갈로 100',
        thumbnail: 'assets/images/academy9.jpg',
      ),
      AcademyData(
        name: '스터디포스 영어학원',
        distance: '4.0km',
        address: '경기도 용인시 기흥구 구갈로 200',
        thumbnail: 'assets/images/academy10.jpg',
      ),
      AcademyData(
        name: '글로벌어학원',
        distance: '4.2km',
        address: '경기도 용인시 기흥구 신갈로 300',
        thumbnail: 'assets/images/academy11.jpg',
      ),
      AcademyData(
        name: '어학원 스카이',
        distance: '4.8km',
        address: '경기도 용인시 기흥구 신갈로 400',
        thumbnail: 'assets/images/academy12.jpg',
      ),
      AcademyData(
        name: '영어마을학원',
        distance: '5.1km',
        address: '경기도 용인시 기흥구 죽전로 500',
        thumbnail: 'assets/images/academy13.jpg',
      ),
      AcademyData(
        name: '토익마스터 학원',
        distance: '5.5km',
        address: '경기도 용인시 기흥구 죽전로 600',
        thumbnail: 'assets/images/academy14.jpg',
      ),
      AcademyData(
        name: '토플전문학원',
        distance: '6.0km',
        address: '경기도 용인시 기흥구 죽전로 700',
        thumbnail: 'assets/images/academy15.jpg',
      ),
    ];
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

                    // 학원 목록
                    _buildAcademyList(),

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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyList() {
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
      onTap: () {
        Navigator.pushNamed(context, '/academy/detail', arguments: academy);
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

  AcademyData({
    required this.name,
    required this.distance,
    required this.address,
    required this.thumbnail,
  });
}
