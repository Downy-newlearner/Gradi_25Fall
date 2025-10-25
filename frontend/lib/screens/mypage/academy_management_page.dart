import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';

/// 학원 관리 페이지
/// 등록된 학원 관리, 학원 추가/삭제, 학원 전환 등을 관리하는 페이지
class AcademyManagementPage extends StatefulWidget {
  const AcademyManagementPage({super.key});

  @override
  State<AcademyManagementPage> createState() => _AcademyManagementPageState();
}

class _AcademyManagementPageState extends State<AcademyManagementPage> {
  // TODO: 서버에서 학원 데이터 가져오기
  final List<RegisteredAcademy> _academies = [
    RegisteredAcademy(
      name: '정다훈 학원',
      address: '서울시 강남구 테헤란로 123',
      isActive: true,
      joinDate: DateTime(2025, 1, 15),
    ),
    RegisteredAcademy(
      name: '수학의 정석 학원',
      address: '서울시 서초구 서초대로 456',
      isActive: false,
      joinDate: DateTime(2024, 9, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // 등록된 학원 목록
                    const Text(
                      '등록된 학원',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._academies.map((academy) => _buildAcademyCard(academy)),

                    const SizedBox(height: 24),

                    // 학원 추가 버튼
                    _buildAddAcademyButton(),

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
        children: const [
          CustomBackButton(),
          SizedBox(width: 20),
          Text(
            '학원 관리',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademyCard(RegisteredAcademy academy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: academy.isActive
              ? const Color(0xFFAC5BF8)
              : const Color(0xFFE9ECEF),
          width: academy.isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  academy.name,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              if (academy.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAC5BF8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '활성',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF999999),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  academy.address,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '등록일: ${_formatDate(academy.joinDate)}',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!academy.isActive)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        // 다른 학원 비활성화
                        for (var a in _academies) {
                          a.isActive = false;
                        }
                        // 현재 학원 활성화
                        academy.isActive = true;
                      });
                      // TODO: 서버에 활성 학원 변경 요청
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFAC5BF8),
                      side: const BorderSide(color: Color(0xFFAC5BF8)),
                    ),
                    child: const Text('활성화'),
                  ),
                ),
              if (!academy.isActive) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showDeleteDialog(academy);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF44336),
                    side: const BorderSide(color: Color(0xFFF44336)),
                  ),
                  child: const Text('삭제'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddAcademyButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // TODO: 학원 검색/추가 페이지로 이동
          Navigator.pushNamed(context, '/academy/list');
        },
        icon: const Icon(Icons.add),
        label: const Text('학원 추가하기'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: const Color(0xFFAC5BF8),
          side: const BorderSide(color: Color(0xFFAC5BF8)),
        ),
      ),
    );
  }

  void _showDeleteDialog(RegisteredAcademy academy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학원 삭제'),
        content: Text('${academy.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _academies.remove(academy);
              });
              Navigator.pop(context);
              // TODO: 서버에 삭제 요청
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('학원이 삭제되었습니다')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF44336),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class RegisteredAcademy {
  final String name;
  final String address;
  bool isActive;
  final DateTime joinDate;

  RegisteredAcademy({
    required this.name,
    required this.address,
    required this.isActive,
    required this.joinDate,
  });
}

