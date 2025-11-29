import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../widgets/back_button.dart';

/// 계정 관리 페이지
/// 개인정보 수정, 비밀번호 변경, 계정 설정 등을 관리하는 페이지
class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  final UserService _userService = UserService();
  bool _isLoadingProfile = true;
  bool _isLoggingOut = false;
  String? _email;
  String? _phoneNumber;
  String? _birthDate;

  @override
  void initState() {
    super.initState();
    _userService.addListener(_handleUserUpdated);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _userService.removeListener(_handleUserUpdated);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final cachedUser = _userService.getUser();
    if (cachedUser != null) {
      setState(() {
        _applyUserData(cachedUser);
        _isLoadingProfile = false;
      });
    } else {
      setState(() {
        _isLoadingProfile = true;
      });
    }

    final fetchedUser = await _userService.fetchUserFromServer();
    if (!mounted) return;

    if (fetchedUser != null) {
      setState(() {
        _applyUserData(fetchedUser);
      });
    } else if (cachedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.')),
      );
    }

    setState(() {
      _isLoadingProfile = false;
    });
  }

  void _handleUserUpdated(User? user) {
    if (!mounted || user == null) return;
    setState(() {
      _applyUserData(user);
    });
  }

  void _applyUserData(User user) {
    _email = user.email;
    _phoneNumber = user.phoneNumber;
    _birthDate = user.birthDate;
  }

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
                    _buildInfoItem(
                      '이메일',
                      _isLoadingProfile ? null : _formatEmail(_email),
                      Icons.email_outlined,
                    ),
                    _buildInfoItem(
                      '전화번호',
                      _isLoadingProfile
                          ? null
                          : _formatPhoneNumber(_phoneNumber),
                      Icons.phone_outlined,
                    ),
                    _buildInfoItem(
                      '생년월일',
                      _isLoadingProfile ? null : _formatBirthDate(_birthDate),
                      Icons.cake_outlined,
                    ),

                    const SizedBox(height: 32),

                    // 보안 섹션
                    _buildSectionTitle('보안'),
                    const SizedBox(height: 12),
                    _buildActionItem('비밀번호 변경', Icons.lock_outlined, () {
                      // TODO: 비밀번호 변경 페이지로 이동
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('비밀번호 변경 기능 구현 예정')),
                      );
                    }),
                    _buildActionItem('2단계 인증', Icons.security_outlined, () {
                      // TODO: 2단계 인증 설정 페이지로 이동
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('2단계 인증 기능 구현 예정')),
                      );
                    }),

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
                      isBusy: _isLoggingOut,
                    ),
                    _buildActionItem('회원 탈퇴', Icons.person_remove_outlined, () {
                      _showDeleteAccountDialog();
                    }, isDestructive: true),

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

  Widget _buildInfoItem(String label, String? value, IconData icon) {
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
          Tooltip(
            message: '$label 아이콘',
            child: Semantics(
              label: '$label 아이콘',
              child: Icon(icon, size: 24, color: const Color(0xFF666666)),
            ),
          ),
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
                  value ?? '불러오는 중...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: value == null
                        ? const Color(0xFF999999)
                        : const Color(0xFF333333),
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
    bool isBusy = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isBusy ? null : onTap,
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
                if (isBusy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF999999)),
                    ),
                  )
                else
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
            onPressed: _isLoggingOut
                ? null
                : () {
                    Navigator.pop(context);
                    _performLogout();
                  },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      final authService = AuthService();
      await authService.signOutFromServer();
      await authService.clearTokens();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 회원 탈퇴 로직 구현
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('회원 탈퇴 기능 구현 예정')));
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

  String _formatEmail(String? rawEmail) {
    if (rawEmail == null || rawEmail.trim().isEmpty) {
      return '미등록';
    }
    return rawEmail.trim().toLowerCase();
  }

  String _formatPhoneNumber(String? rawNumber) {
    if (rawNumber == null || rawNumber.trim().isEmpty) {
      return '미등록';
    }
    final digits = rawNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    return rawNumber;
  }

  String _formatBirthDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return '미등록';
    }
    try {
      final date = DateTime.parse(rawDate);
      return '${date.year.toString().padLeft(4, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }
}
