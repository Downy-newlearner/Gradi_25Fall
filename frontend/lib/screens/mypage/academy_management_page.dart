import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';
import '../../services/academy_service.dart';
import '../../services/auth_service.dart';

/// 학원 관리 페이지
/// 등록된 학원 관리, 학원 추가/삭제, 학원 전환 등을 관리하는 페이지
class AcademyManagementPage extends StatefulWidget {
  const AcademyManagementPage({super.key});

  @override
  State<AcademyManagementPage> createState() => _AcademyManagementPageState();
}

class _AcademyManagementPageState extends State<AcademyManagementPage> {
  final AcademyService _academyService = AcademyService();
  final AuthService _authService = AuthService();

  List<UserAcademyResponse> _academies = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _defaultAcademyCode;

  @override
  void initState() {
    super.initState();
    _loadAcademies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAcademies,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAC5BF8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    if (_academies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '등록된 학원이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '학원을 등록하면 숙제와 학습 정보를 확인할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            _buildAddAcademyButton(fullWidth: true),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
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
          _buildAddAcademyButton(),
          const SizedBox(height: 20),
        ],
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

  Widget _buildAcademyCard(UserAcademyResponse academy) {
    final isActive =
        academy.academyCode != null &&
        academy.academyCode == _defaultAcademyCode;
    final isPending = academy.registerStatus != 'Y';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isActive ? const Color(0xFFAC5BF8) : const Color(0xFFE9ECEF),
          width: isActive ? 2 : 1,
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
                  academy.academyName,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              if (isActive)
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
                  academy.academyRoadAddress.isNotEmpty
                      ? academy.academyRoadAddress
                      : '주소 정보 없음',
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
          const SizedBox(height: 12),
          Row(
            children: [
              if (isPending)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '등록 승인 대기중',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: isActive
                        ? null
                        : () => _setDefaultAcademy(academy.academyCode),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFAC5BF8),
                      side: const BorderSide(color: Color(0xFFAC5BF8)),
                    ),
                    child: Text(isActive ? '활성화됨' : '활성화'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDeleteDialog(academy),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF44336),
                      side: const BorderSide(color: Color(0xFFF44336)),
                    ),
                    child: const Text('삭제'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddAcademyButton({bool fullWidth = false}) {
    final button = OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, '/academy/list'),
      icon: const Icon(Icons.add),
      label: const Text('학원 추가하기'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: const Color(0xFFAC5BF8),
        side: const BorderSide(color: Color(0xFFAC5BF8)),
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: fullWidth ? 0 : 0),
        child: button,
      ),
    );
  }

  void _showDeleteDialog(UserAcademyResponse academy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학원 삭제'),
        content: Text('${academy.academyName}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              _removeAcademy(academy);
              Navigator.pop(context);
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

  Future<void> _loadAcademies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _defaultAcademyCode = await _academyService.getDefaultAcademyCode();

      final cached = await _academyService.loadAcademiesFromCache();
      if (cached != null) {
        setState(() {
          _academies = cached;
        });
      }

      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('사용자 정보를 확인할 수 없습니다.');
      }

      final academies = await _academyService.getUserAcademies(userId);
      await _academyService.saveAcademiesToCache(academies);
      setState(() {
        _academies = academies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '학원 정보를 불러오지 못했습니다.\n$e';
      });
    }
  }

  Future<void> _setDefaultAcademy(String? academyCode) async {
    if (academyCode == null) return;
    await _academyService.saveDefaultAcademyCode(academyCode);
    setState(() {
      _defaultAcademyCode = academyCode;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('활성 학원이 변경되었습니다')));
  }

  Future<void> _removeAcademy(UserAcademyResponse academy) async {
    final academyUserId = academy.academy_user_id;
    if (academyUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학원 정보를 확인할 수 없습니다.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _academyService.leaveAcademy(academyUserId);
      await _loadAcademies();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴 요청이 처리 중입니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('학원 탈퇴에 실패했습니다.\n$e')),
      );
    }
  }
}
