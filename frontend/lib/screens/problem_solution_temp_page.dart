import 'package:flutter/material.dart';

/// 임시 문제 풀이 화면
class ProblemSolutionTempPage extends StatelessWidget {
  const ProblemSolutionTempPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '문제 풀이',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1번 문제',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/temp/problem1.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0F6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '풀이',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '지문에서는 운동이 상업화되며 돈·시간을 많이 쓰게 되고, 마라톤·극한 스포츠까지 하면서 "운동은 건강에 좋다"는 압박 때문에 오히려 불안과 혼란의 원인이 되었다고 말한다. '
                    '‘be exercised about’는 ‘~때문에 불안해하다, 신경 쓰다’라는 뜻이므로, 건강을 위해 하는 운동이 오히려 스트레스를 준다는 아이러니를 말한 것이다. '
                    '따라서 운동이 웰빙을 명분으로 오히려 스트레스를 유발한다는 ①이 정답이다.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
