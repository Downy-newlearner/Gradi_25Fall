import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';

/// 학습 통계/학습 리포트 페이지
/// 상세한 학습 분석, 강점/약점 분석, 과목별 통계를 제공하는 페이지
class LearningStatisticsPage extends StatefulWidget {
  const LearningStatisticsPage({super.key});

  @override
  State<LearningStatisticsPage> createState() =>
      _LearningStatisticsPageState();
}

class _LearningStatisticsPageState extends State<LearningStatisticsPage> {
  String _selectedPeriod = '이번 주';

  // TODO: 서버에서 통계 데이터 가져오기
  final Map<String, int> _subjectProgress = {
    '수학': 75,
    '영어': 85,
    '과학': 60,
    '국어': 70,
  };

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

                    // 기간 선택
                    _buildPeriodSelector(),

                    const SizedBox(height: 24),

                    // 전체 학습 현황 카드
                    _buildOverallStatusCard(),

                    const SizedBox(height: 24),

                    // 과목별 통계
                    _buildSubjectStatistics(),

                    const SizedBox(height: 24),

                    // TODO: 강점/약점 분석
                    _buildStrengthWeaknessCard(),

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
            '학습 통계',
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

  Widget _buildPeriodSelector() {
    final periods = ['이번 주', '이번 달', '전체'];
    return Row(
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(period),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedPeriod = period;
              });
              // TODO: 기간별 데이터 조회
            },
            selectedColor: const Color(0xFFAC5BF8),
            labelStyle: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverallStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('학습 시간', '15시간'),
              _buildStatItem('푼 문제', '127개'),
              _buildStatItem('정답률', '82%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '과목별 진행률',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        ..._subjectProgress.entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9ECEF)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      '${entry.value}%',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFFAC5BF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFE9ECEF)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: entry.value / 100,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFAC5BF8), Color(0xFF7C3AED)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStrengthWeaknessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '강점/약점 분석\n(추후 구현 예정)',
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
}

