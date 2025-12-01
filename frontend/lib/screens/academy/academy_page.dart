import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../widgets/app_header.dart';
import '../../widgets/app_header_title.dart';
import '../../widgets/app_header_menu_button.dart';
import '../../services/auth_service.dart';
import '../../services/academy_service.dart';

class AcademyPage extends StatefulWidget {
  const AcademyPage({super.key});

  @override
  State<AcademyPage> createState() => _AcademyPageState();
}

class _AcademyPageState extends State<AcademyPage> {
  final List<AcademyItem> _registeredAcademies = [];
  final AuthService _authService = AuthService();
  final AcademyService _academyService = AcademyService();

  bool _isLoading = false;
  bool _hasLoadedOnce = false; // 메모리 캐싱: 이미 로드했는지 확인
  bool _hasRefreshedOnReturn = false; // didChangeDependencies에서 이미 갱신했는지 확인
  String? _errorMessage;

  static const String _cacheKeyBase = 'user_academies_cache';

  @override
  void initState() {
    super.initState();
    _loadAcademies();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 페이지에서 돌아올 때만 한 번 갱신 (과도한 API 호출 방지)
    if (!_hasRefreshedOnReturn) {
      _hasRefreshedOnReturn = true;
      _loadAcademies(forceRefresh: true);
    }
  }

  /// 외부에서 호출 가능한 새로고침 메서드
  /// 탭 전환 시 MainNavigationPage에서 호출
  void refresh() {
    _hasRefreshedOnReturn = false; // 플래그 리셋
    _loadAcademies(forceRefresh: true);
  }

  /// 학원 목록 로드 (캐시에서만 로드)
  /// [forceRefresh]가 true이면 API 호출하여 최신 데이터 가져오기
  Future<void> _loadAcademies({bool forceRefresh = false}) async {
    // [케이스 1] 기본: SharedPreferences에서 캐시 로드
    // [케이스 2] 같은 세션 내 재진입: 메모리 캐시 사용 (API 호출 없음)
    // [케이스 3] 강제 갱신: API 호출하여 최신 데이터 가져오기

    if (_hasLoadedOnce && !forceRefresh) {
      // 같은 세션 내 재진입: 메모리 캐시 사용
      return;
    }

    // 강제 갱신 시 _hasLoadedOnce 플래그 리셋
    if (forceRefresh) {
      _hasLoadedOnce = false;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '사용자 정보를 가져올 수 없습니다. 다시 로그인해주세요.';
        });
        return;
      }
      final cacheKey = '${_cacheKeyBase}_$userId';
      if (forceRefresh) {
        // 개발 환경에서 SSL 인증서 검증 우회 (프로덕션에서는 제거)
        HttpOverrides.global = MyHttpOverrides();

        try {
          final academies = await _academyService.getUserAcademies(userId);

          // API 응답을 AcademyItem으로 변환 (에러 처리 개선)
          final academyItems = <AcademyItem>[];
          for (var academy in academies) {
            try {
              final item = AcademyItem(
                name: academy.academyName,
                distance: '', // API 응답에 거리 정보가 없으므로 빈 문자열
                address: academy.academyRoadAddress,
                thumbnail: null,
                registerStatus: academy.registerStatus,
                academyCode: academy.academyCode,
              );
              academyItems.add(item);
            } catch (e) {
              // 에러가 발생해도 계속 진행
            }
          }

          // 메모리 및 SharedPreferences에 저장
          setState(() {
            _registeredAcademies.clear();
            _registeredAcademies.addAll(academyItems);
            _hasLoadedOnce = true;
            _isLoading = false;
          });

          await _saveToCache(academyItems, cacheKey);
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString().replaceAll('Exception: ', '');
          });
        }
      } else {
        // 기본: SharedPreferences에서 캐시 로드
        final cachedData = await _loadFromCache(cacheKey);
        if (cachedData.isNotEmpty) {
          setState(() {
            _registeredAcademies.clear();
            _registeredAcademies.addAll(cachedData);
            _hasLoadedOnce = true;
            _isLoading = false;
          });
        } else {
          // 캐시가 없으면 빈 상태 표시
          setState(() {
            _registeredAcademies.clear();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// SharedPreferences에서 캐시 로드
  Future<List<AcademyItem>> _loadFromCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) {
        if (prefs.containsKey(_cacheKeyBase)) {
          await prefs.remove(_cacheKeyBase);
        }
        return [];
      }

      final List<dynamic> data = json.decode(cachedJson);
      return data.map((item) => AcademyItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// SharedPreferences에 캐시 저장
  Future<void> _saveToCache(
    List<AcademyItem> academies,
    String cacheKey,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(
        academies.map((academy) => academy.toJson()).toList(),
      );
      await prefs.setString(cacheKey, jsonData);
      if (prefs.containsKey(_cacheKeyBase)) {
        await prefs.remove(_cacheKeyBase);
      }
    } catch (e) {
      // 캐시 저장 실패는 무시
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
            _buildHeader(),

            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    // 로딩 상태
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      )
                    // 에러 상태
                    else if (_errorMessage != null)
                      _buildErrorState()
                    // 학원 목록 또는 빈 상태
                    else if (_registeredAcademies.isEmpty)
                      _buildEmptyState()
                    else
                      _buildAcademyList(),

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
    return const AppHeader(
      title: AppHeaderTitle('학원', textAlign: TextAlign.center),
      trailing: AppHeaderMenuButton(),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            border: Border.all(color: const Color(0xFFFFCCCC)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF6B6B),
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? '오류가 발생했습니다.',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFFFF6B6B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadAcademies,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ],
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
          onTap: () async {
            // 학원 목록 페이지로 이동하고 등록 성공 여부를 받음
            final result = await Navigator.pushNamed(context, '/academy/list');
            // 등록 성공 시 캐시 갱신
            if (result == true) {
              await _loadAcademies(forceRefresh: true);
            }
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
          onTap: () async {
            // 학원 목록 페이지로 이동하고 등록 성공 여부를 받음
            final result = await Navigator.pushNamed(context, '/academy/list');
            // 등록 성공 시 캐시 갱신
            if (result == true) {
              await _loadAcademies(forceRefresh: true);
            }
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
    // registerStatus에 따라 스타일 결정
    // 'Y' (Yes): 선명하게, 'P' (Pending): 흐리게
    final bool isPending = academy.registerStatus == 'P';
    final double opacity = isPending ? 0.5 : 1.0;
    final bool isSelectable =
        academy.registerStatus == 'Y' && academy.academyCode != null;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: isSelectable
            ? () async {
                // 등록완료된 학원만 선택 가능
                if (academy.academyCode != null) {
                  await _academyService.saveDefaultAcademyCode(
                    academy.academyCode!,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${academy.name}이(가) 기본 학원으로 설정되었습니다.'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border.all(color: const Color(0xFFE1E7ED)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // 학원 썸네일
              _buildAcademyThumbnail(academy),

              const SizedBox(width: 15),

              // 학원 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 학원명 및 상태 표시
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            academy.name,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF585B69),
                            ),
                          ),
                        ),
                        // 상태 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFFF3CD)
                                : const Color(0xFFD4EDDA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPending ? '대기중' : '등록완료',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                              color: isPending
                                  ? const Color(0xFF856404)
                                  : const Color(0xFF155724),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // 거리 (있을 경우만 표시)
                    if (academy.distance.isNotEmpty) ...[
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
                    ],

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
        ),
      ),
    );
  }

  Widget _buildAcademyThumbnail(AcademyItem academy) {
    return FutureBuilder<String?>(
      future: academy.academyCode != null
          ? _academyService
                .getAcademyImages(academy.academyCode!)
                .then((response) => response.mainImageUrl)
                .catchError((e) {
                  return null;
                })
          : Future.value(null),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          width: 97,
          height: 97,
          decoration: BoxDecoration(
            color: const Color(0xFFE1E7ED),
            borderRadius: BorderRadius.circular(5),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 97,
                    height: 97,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 40,
                      );
                    },
                  ),
                )
              : const Icon(Icons.school, color: Colors.white, size: 40),
        );
      },
    );
  }
}

class AcademyItem {
  final String name;
  final String distance;
  final String address;
  final String? thumbnail;
  final String registerStatus; // 'Y' 또는 'P'
  final String? academyCode; // 학원 코드

  AcademyItem({
    required this.name,
    required this.distance,
    required this.address,
    this.thumbnail,
    required this.registerStatus,
    this.academyCode,
  });

  /// JSON으로 변환 (SharedPreferences 저장용)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'distance': distance,
      'address': address,
      'thumbnail': thumbnail,
      'registerStatus': registerStatus,
      'academyCode': academyCode,
    };
  }

  /// JSON에서 생성 (SharedPreferences 로드용)
  factory AcademyItem.fromJson(Map<String, dynamic> json) {
    return AcademyItem(
      name: json['name'] ?? '',
      distance: json['distance'] ?? '',
      address: json['address'] ?? '',
      thumbnail: json['thumbnail'],
      registerStatus: json['registerStatus'] ?? 'P',
      academyCode: json['academyCode']?.toString(),
    );
  }
}

// 개발 환경에서 SSL 인증서 검증 우회를 위한 클래스 (프로덕션에서는 제거)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
