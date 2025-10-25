import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';

/// 문제집 상세 페이지
/// WorkbookPage에서 문제집을 선택하면 표시되는 페이지
///
/// 구성:
/// 1. 헤더: 뒤로가기 버튼 + 문제집 이름
/// 2. 문제집 풀이 현황 섹션 (공간만 확보, 추후 구현)
/// 3. 챕터 목록: 각 챕터의 이름과 "푼 문제 수/전체 문제 수" 표시
class WorkbookDetailPage extends StatefulWidget {
  final String workbookName;
  final String thumbnailPath;

  const WorkbookDetailPage({
    super.key,
    required this.workbookName,
    required this.thumbnailPath,
  });

  @override
  State<WorkbookDetailPage> createState() => _WorkbookDetailPageState();
}

class _WorkbookDetailPageState extends State<WorkbookDetailPage> {
  // TODO: 서버에서 챕터 데이터 가져오기
  // 임시 데이터
  final List<ChapterInfo> _chapters = [
    ChapterInfo(chapterName: '1. 소인수분해', solvedCount: 12, totalCount: 20),
    ChapterInfo(chapterName: '2. 정수와 유리수', solvedCount: 8, totalCount: 15),
    ChapterInfo(
      chapterName: '3. 문자의 사용과 식의 계산',
      solvedCount: 0,
      totalCount: 18,
    ),
  ];

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // TODO: 문제집 풀이 현황 섹션 구현
                    // Figma: node-id=2302-2222
                    // 현재는 공간만 확보
                    _buildProgressSection(),

                    const SizedBox(height: 24),

                    // 챕터 목록 섹션
                    _buildChapterListSection(),

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

  /// 문제집 풀이 현황 섹션
  /// TODO: 추후 구현 예정
  /// - 전체 진행률 표시
  /// - 최근 학습일 표시
  /// - 정답률, 오답률 등의 통계 표시
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

  /// 챕터 목록 섹션
  Widget _buildChapterListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _chapters.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildChapterCard(_chapters[index]);
          },
        ),
      ],
    );
  }

  /// 개별 챕터 카드
  Widget _buildChapterCard(ChapterInfo chapter) {
    final progress = chapter.totalCount > 0
        ? chapter.solvedCount / chapter.totalCount
        : 0.0;

    return GestureDetector(
      onTap: () {
        // TODO: ChapterDetailPage로 이동
        Navigator.pushNamed(
          context,
          '/workbook/chapter-detail',
          arguments: {
            'workbookName': widget.workbookName,
            'chapterName': chapter.chapterName,
            'solvedCount': chapter.solvedCount,
            'totalCount': chapter.totalCount,
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
              chapter.chapterName,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),

            // 진행 상태
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFE9ECEF)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
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
                  '${chapter.solvedCount}/${chapter.totalCount}',
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

/// 챕터 정보 모델
class ChapterInfo {
  final String chapterName;
  final int solvedCount;
  final int totalCount;

  ChapterInfo({
    required this.chapterName,
    required this.solvedCount,
    required this.totalCount,
  });
}
