import 'package:flutter/material.dart';

class AcademyPage extends StatefulWidget {
  const AcademyPage({super.key});

  @override
  State<AcademyPage> createState() => _AcademyPageState();
}

class _AcademyPageState extends State<AcademyPage> {
  // TODO: 서버에서 등록된 학원 목록을 불러오는 로직 구현
  // 임시로 빈 리스트 사용
  final List<AcademyItem> _registeredAcademies = [];

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
                  children: [
                    const SizedBox(height: 18),

                    // 학원 목록 또는 빈 상태
                    _registeredAcademies.isEmpty
                        ? _buildEmptyState()
                        : _buildAcademyList(),

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
      padding: const EdgeInsets.fromLTRB(30, 17, 30, 17),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 24), // 시각적 균형을 위한 공간
          const Text(
            '학원',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF585B69),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF585B69), size: 24),
            onPressed: () {
              // TODO: 메뉴 기능 구현
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('메뉴 기능 구현 예정')));
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        // "등록된 학원이 없습니다." 카드
        Container(
          width: double.infinity,
          height: 81,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border.all(color: const Color(0xFFE1E7ED)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              '등록된 학원이 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF585B69),
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // "+" 버튼 카드
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/academy/list');
          },
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: const Color(0xFFE1E7ED)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.add, size: 24, color: Color(0xFF585B69)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademyList() {
    return Column(
      children: [
        // 등록된 학원 카드 목록
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _registeredAcademies.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildAcademyCard(_registeredAcademies[index]);
          },
        ),

        const SizedBox(height: 16),

        // "+" 버튼 카드
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/academy/list');
          },
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(color: const Color(0xFFE1E7ED)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.add, size: 24, color: Color(0xFF585B69)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademyCard(AcademyItem academy) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE1E7ED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // 학원 썸네일
          Container(
            width: 97,
            height: 97,
            decoration: BoxDecoration(
              color: const Color(0xFFE1E7ED),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 40),
          ),

          const SizedBox(width: 15),

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
                    color: Color(0xFF585B69),
                  ),
                ),

                const SizedBox(height: 28),

                // 거리
                Text(
                  academy.distance,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF585B69),
                  ),
                ),

                const SizedBox(height: 4),

                // 주소
                Text(
                  academy.address,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF585B69),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AcademyItem {
  final String name;
  final String distance;
  final String address;
  final String? thumbnail;

  AcademyItem({
    required this.name,
    required this.distance,
    required this.address,
    this.thumbnail,
  });
}
