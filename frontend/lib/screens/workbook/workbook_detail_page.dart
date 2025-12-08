import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';
import '../../domain/chapter/chapter_entity.dart';
import '../../domain/chapter/get_chapters_for_book_use_case.dart';
import 'dart:developer' as developer;

/// 문제집 상세 페이지
/// WorkbookPage에서 문제집을 선택하면 표시되는 페이지
///
/// 구성:
/// 1. 헤더: 뒤로가기 버튼 + 문제집 이름
/// 2. 문제집 풀이 현황 섹션 (공간만 확보, 추후 구현)
/// 3. 챕터 목록: 각 챕터의 이름과 "푼 문제 수/전체 문제 수" 표시
class WorkbookDetailPage extends StatefulWidget {
  final String workbookName;
  final String?
  thumbnailPath; // TODO(downy): workbook 썸네일을 헤더 우측에 표시 (Figma node-id=... 참조)
  final int bookId;
  final int academyUserId;
  final GetChaptersForBookUseCase getChaptersUseCase;

  const WorkbookDetailPage({
    super.key,
    required this.workbookName,
    this.thumbnailPath,
    required this.bookId,
    required this.academyUserId,
    required this.getChaptersUseCase,
  });

  @override
  State<WorkbookDetailPage> createState() => _WorkbookDetailPageState();
}

class _WorkbookDetailPageState extends State<WorkbookDetailPage> {
  // 에러 메시지 상수화 (나중에 AppStrings로 이동 가능)
  static const String _defaultChapterErrorMessage = '챕터 정보를 불러오지 못했습니다.';
  static const String _emptyChapterMessage = '등록된 챕터가 없습니다.';

  // 상태 관리
  List<ChapterEntity> _chapters = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  /// 챕터 데이터 로드
  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chapters = await widget.getChaptersUseCase.call(
        bookId: widget.bookId,
        academyUserId: widget.academyUserId,
      );

      if (!mounted) return;

      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('❌ [WorkbookDetailPage] 챕터 로드 실패: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = _defaultChapterErrorMessage;
        _isLoading = false;
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

            // 메인 콘텐츠
            Expanded(child: _buildContent()),
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
        children: [
          const CustomBackButton(),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              widget.workbookName,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF333333),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 메인 콘텐츠 (스크롤 구조 개선)
  ///
  /// CustomScrollView + SliverList로 통합하여 성능 최적화
  Widget _buildContent() {
    // 로딩 상태
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 에러 상태
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF6B6B),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
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
                onPressed: _loadChapters,
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

    // 빈 상태
    if (_chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _emptyChapterMessage,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
        ),
      );
    }

    // 정상 상태: CustomScrollView로 통합
    // padding은 horizontal만 적용하고, 세로 여백은 SliverToBoxAdapter로 관리
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildProgressSection(),
                      const SizedBox(height: 24),
                      const Text(
                        '챕터 목록',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                // 챕터 카드 (index 1부터 시작)
                final chapterIndex = index - 1;
                final chapter = _chapters[chapterIndex];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: chapterIndex < _chapters.length - 1 ? 12 : 0,
                  ),
                  child: _buildChapterCard(chapter),
                );
              },
              childCount: _chapters.length + 1, // 타이틀 섹션 + 챕터 개수
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '문제집 풀이 현황\n(추후 구현 예정)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  /// 개별 챕터 카드
  ///
  /// workbook_page.dart의 progress bar 디자인과 동일하게 구현
  Widget _buildChapterCard(ChapterEntity chapter) {
    return GestureDetector(
      onTap: () {
        // TODO: ChapterDetailPage로 이동
        Navigator.pushNamed(
          context,
          '/workbook/chapter-detail',
          arguments: {
            'chapterId': chapter.chapterId,
            'academyUserId': widget.academyUserId,
            'workbookName': widget.workbookName,
            'chapterName': chapter.formattedName,
          },
        );
      },
      child: Container(
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
            // 챕터명
            Text(
              chapter.formattedName,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),

            // 진행 상태 (workbook_page.dart와 동일한 스타일)
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 8, // workbook_page.dart와 동일
                      decoration: const BoxDecoration(color: Color(0xFFE9ECEF)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: chapter.progress,
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
                const SizedBox(width: 12),
                Text(
                  chapter
                      .problemCountDisplay, // "{studentAnswerCount} / {totalChapterQuestion}"
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
