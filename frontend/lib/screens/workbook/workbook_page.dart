import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_header_title.dart';
import '../../widgets/app_header_menu_button.dart';
import '../../widgets/empty_state_message.dart';
import '../../services/academy_service.dart';
import '../../services/auth_service.dart';
import '../../services/workbook_repository_impl.dart';
import '../../data/mappers/workbook_mapper.dart';
import 'models/class_data.dart';
import 'models/workbook_info.dart';
import 'models/workbook_data.dart';
import 'dart:developer' as developer;

enum WorkbookViewType {
  byClass, // 클래스 순
  byWorkbook, // 문제집 순
}

class WorkbookPage extends StatefulWidget {
  const WorkbookPage({super.key});

  @override
  State<WorkbookPage> createState() => _WorkbookPageState();
}

class _WorkbookPageState extends State<WorkbookPage> {
  WorkbookViewType _currentView = WorkbookViewType.byClass;

  final GetIt _getIt = GetIt.instance;

  // Services (DI에서 주입)
  late final AuthService _authService;
  late final AcademyService _academyService;
  late final WorkbookRepositoryImpl _workbookRepository;
  late final WorkbookMapper _workbookMapper;

  // Data
  List<ClassData> _classData = [];
  List<WorkbookData> _workbookData = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;
  bool _hasRefreshedOnReturn = false;

  @override
  void initState() {
    super.initState();
    _authService = _getIt<AuthService>();
    _academyService = _getIt<AcademyService>();
    _workbookRepository = _getIt<WorkbookRepositoryImpl>();
    _workbookMapper = _getIt<WorkbookMapper>();
    _loadWorkbooks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 다른 페이지에서 돌아올 때 강제 새로고침
    if (!_hasRefreshedOnReturn) {
      _hasRefreshedOnReturn = true;
      _loadWorkbooks(forceRefresh: true);
    }
  }

  /// 외부에서 호출 가능한 새로고침 메서드
  void refresh() {
    developer.log('🔄 [WorkbookPage] refresh() called from external');
    _hasRefreshedOnReturn = false;
    _loadWorkbooks(forceRefresh: true);
  }

  /// 문제집 데이터 로드
  Future<void> _loadWorkbooks({bool forceRefresh = false}) async {
    if (_hasLoadedOnce && !forceRefresh) {
      return; // 메모리 캐시 사용
    }

    if (forceRefresh) {
      _hasLoadedOnce = false;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. UserId로 academyUserIds 조회
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다.');
      }

      final academies = await _academyService.getUserAcademies(userId);
      final academyUserIds = academies
          .where((a) => a.registerStatus == 'Y')
          .map((a) => a.academy_user_id)
          .whereType<int>()
          .toList();

      if (academyUserIds.isEmpty) {
        setState(() {
          _classData = [];
          _workbookData = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Repository 호출 (className은 Repository 내부에서 처리)
      final summariesMap = await _workbookRepository
          .getWorkbookSummariesByAcademyUserIds(academyUserIds);

      // 3. Mapper로 UI 모델 변환
      final classData = _workbookMapper.convertToClassData(summariesMap);
      final workbookData = _workbookMapper.convertToWorkbookData(summariesMap);

      // 4. UI 업데이트
      setState(() {
        _classData = classData;
        _workbookData = workbookData;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      developer.log('❌ [WorkbookPage] 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
            _buildHeader(),

            // 메인 콘텐츠 (스크롤 가능 + Pull-to-refresh)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadWorkbooks(forceRefresh: true);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(), // Pull-to-refresh를 위해 항상 스크롤 가능하도록
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.032,
                      ),

                      // 토글 버튼
                      _buildToggle(),

                      Container(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),

                      // 메인 콘텐츠
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _errorMessage != null
                          ? _buildErrorState()
                          : _currentView == WorkbookViewType.byClass
                          ? _buildClassView()
                          : _buildWorkbookView(),
                    ],
                  ),
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
      title: AppHeaderTitle('문제집'),
      trailing: AppHeaderMenuButton(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadWorkbooks(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    final screenWidth = MediaQuery.of(context).size.width;
    // 토글 크기 계산 (Figma 비율: 28:17 유지)
    final toggleWidth = screenWidth * 0.07;
    final toggleHeight = toggleWidth * (17 / 28); // 비율 유지
    final circleSize = toggleWidth * (13 / 28); // 비율 유지
    final circlePadding = toggleWidth * (2 / 28); // 비율 유지

    return Row(
      children: [
        // 토글 스위치
        GestureDetector(
          onTap: () {
            setState(() {
              _currentView = _currentView == WorkbookViewType.byClass
                  ? WorkbookViewType.byWorkbook
                  : WorkbookViewType.byClass;
            });
          },
          child: Container(
            width: toggleWidth,
            height: toggleHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _currentView == WorkbookViewType.byClass
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: circleSize,
                height: circleSize,
                margin: EdgeInsets.all(circlePadding),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        Container(width: screenWidth * 0.03),
        // 토글 라벨
        Text(
          _currentView == WorkbookViewType.byClass ? '최근 클래스 순' : '최근 문제집 순',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildClassView() {
    if (_classData.isEmpty) {
      final screenHeight = MediaQuery.of(context).size.height;
      return SizedBox(
        height: screenHeight * 0.6,
        child: const Center(
          child: EmptyStateMessage.classRoom(
            title: '등록된 클래스가 없어요.',
            description: '학원에서 클래스를 배정해주면 이곳에 표시돼요.',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _classData.length,
          separatorBuilder: (context, index) =>
              Container(height: MediaQuery.of(context).size.height * 0.02),
          itemBuilder: (context, index) {
            final classItem = _classData[index];
            return _buildClassCard(classItem);
          },
        ),
      ],
    );
  }

  Widget _buildClassCard(ClassData classData) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
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
          // 클래스명
          Text(
            classData.className,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),

          Container(height: MediaQuery.of(context).size.height * 0.02),

          // 문제집 썸네일과 진행률 리스트
          classData.workbooks.isEmpty
              ? const SizedBox.shrink()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(classData.workbooks.length, (index) {
                    final workbook = classData.workbooks[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < classData.workbooks.length - 1
                            ? MediaQuery.of(context).size.width * 0.04
                            : 0,
                      ),
                      child: _buildWorkbookProgress(workbook),
                    );
                  }),
                ),
        ],
      ),
    );
  }

  Widget _buildWorkbookProgress(WorkbookInfo workbook) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = screenWidth * 0.15; // 화면 너비의 15%
    final thumbnailHeight = thumbnailWidth * 1.33; // 3:4 비율 유지

    return GestureDetector(
      onTap: () {
        if (workbook.bookId == null) {
          // bookId가 없으면 이동하지 않음
          return;
        }
        // WorkbookDetailPage로 이동
        Navigator.pushNamed(
          context,
          '/workbook/detail',
          arguments: {
            'workbookName': workbook.name,
            'thumbnailPath': workbook.thumbnailPath,
            'bookId': workbook.bookId,
            'academyUserId': workbook.academyUserId,
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문제집 썸네일
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: thumbnailWidth,
              height: thumbnailHeight,
              color: const Color(0xFFE9ECEF),
              child: _buildThumbnailImage(workbook.thumbnailPath),
            ),
          ),
          Container(height: MediaQuery.of(context).size.height * 0.01),
          // 진행률 바
          SizedBox(
            width: thumbnailWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFFE9ECEF)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: workbook.progress / 100,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkbookView() {
    if (_workbookData.isEmpty) {
      return const Center(
        child: EmptyStateMessage.workbook(
          title: '현재 등록된 문제집이 없어요.',
          description: '선생님이 문제집을 배정하면 이곳에 표시돼요.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _workbookData.length,
          separatorBuilder: (context, index) =>
              Container(height: MediaQuery.of(context).size.height * 0.02),
          itemBuilder: (context, index) {
            return _buildWorkbookCard(_workbookData[index]);
          },
        ),
      ],
    );
  }

  Widget _buildWorkbookCard(WorkbookData workbookData) {
    return GestureDetector(
      onTap: () {
        if (workbookData.bookId == null) {
          // bookId가 없으면 이동하지 않음
          return;
        }
        // WorkbookDetailPage로 이동
        Navigator.pushNamed(
          context,
          '/workbook/detail',
          arguments: {
            'workbookName': workbookData.workbookName,
            'thumbnailPath': workbookData.thumbnailPath,
            'bookId': workbookData.bookId,
            'academyUserId': workbookData.academyUserId,
          },
        );
      },
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 문제집 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.18,
                  minWidth: 60,
                  maxHeight: MediaQuery.of(context).size.width * 0.23,
                  minHeight: 80,
                ),
                color: const Color(0xFFE74C3C),
                child: _buildThumbnailImage(workbookData.thumbnailPath),
              ),
            ),

            Container(width: MediaQuery.of(context).size.width * 0.04),

            // 문제집 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 문제집명
                  Text(
                    workbookData.workbookName,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.01),

                  // 학습 정보
                  Text(
                    '${workbookData.className}에서 진행 중',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.005),

                  // 마지막 학습일
                  Text(
                    '마지막 학습 일 ${workbookData.lastStudyDate}',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.015),

                  // 진행률
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9ECEF),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: workbookData.progress / 100,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFAC5BF8),
                                    Color(0xFF7C3AED),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
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

  /// 썸네일 이미지 로드 분기 처리
  ///
  /// 네트워크 URL인 경우 Image.network 사용,
  /// asset 경로인 경우 Image.asset 사용
  Widget _buildThumbnailImage(String thumbnailPath) {
    if (thumbnailPath.startsWith('http')) {
      return Image.network(
        thumbnailPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.book, color: Color(0xFF999999)),
          );
        },
      );
    } else {
      return Image.asset(
        thumbnailPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.book, color: Color(0xFF999999)),
          );
        },
      );
    }
  }
}
