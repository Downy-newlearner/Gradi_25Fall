import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';

/// 계정 관리 페이지
/// 개인정보 수정, 비밀번호 변경, 계정 설정 등을 관리하는 페이지
class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  // TODO: 서버에서 사용자 정보 가져오기
  String _email = 'user@example.com';
  String _phoneNumber = '010-1234-5678';
  String _birthDate = '2005.03.15';

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

                    // 개인정보 섹션
                    _buildSectionTitle('개인정보'),
                    const SizedBox(height: 12),
                    _buildInfoItem('이메일', _email, Icons.email_outlined),
                    _buildInfoItem('전화번호', _phoneNumber, Icons.phone_outlined),
                    _buildInfoItem(
                      '생년월일',
                      _birthDate,
                      Icons.cake_outlined,
                    ),

                    const SizedBox(height: 32),

                    // 보안 섹션
                    _buildSectionTitle('보안'),
                    const SizedBox(height: 12),
                    _buildActionItem(
                      '비밀번호 변경',
                      Icons.lock_outlined,
                      () {
                        // TODO: 비밀번호 변경 페이지로 이동
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('비밀번호 변경 기능 구현 예정'),
                          ),
                        );
                      },
                    ),
                    _buildActionItem(
                      '2단계 인증',
                      Icons.security_outlined,
                      () {
                        // TODO: 2단계 인증 설정 페이지로 이동
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('2단계 인증 기능 구현 예정'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // 계정 작업
                    _buildSectionTitle('계정 작업'),
                    const SizedBox(height: 12),
                    _buildActionItem(
                      '로그아웃',
                      Icons.logout_outlined,
                      () {
                        _showLogoutDialog();
                      },
                      isDestructive: false,
                    ),
                    _buildActionItem(
                      '회원 탈퇴',
                      Icons.person_remove_outlined,
                      () {
                        _showDeleteAccountDialog();
                      },
                      isDestructive: true,
                    ),

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
            '계정 관리',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF666666)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDestructive
                    ? const Color(0xFFF44336)
                    : const Color(0xFFE9ECEF),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isDestructive
                      ? const Color(0xFFF44336)
                      : const Color(0xFF666666),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDestructive
                          ? const Color(0xFFF44336)
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: isDestructive
                      ? const Color(0xFFF44336)
                      : const Color(0xFF999999),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 로그아웃 로직 구현
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 되었습니다')),
              );
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 회원 탈퇴 로직 구현
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('회원 탈퇴 기능 구현 예정')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF44336),
            ),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }
}

