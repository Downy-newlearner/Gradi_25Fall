import 'package:flutter/material.dart';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/user_id_card.dart';
import '../widgets/login_button.dart';

class FindIDResultPage extends StatefulWidget {
  final String userName;
  final String userId;

  const FindIDResultPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<FindIDResultPage> createState() => _FindIDResultPageState();
}

class _FindIDResultPageState extends State<FindIDResultPage> {
  String? _userName;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // arguments에서 데이터 추출
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _userName = args['userName'] as String?;
      _userId = args['userId'] as String?;
    }
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _handleLogin() {
    // Navigate to login page
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24), // Top spacing
                // Back Button
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: custom.CustomBackButton(onPressed: _handleBack),
                  ),
                ),

                const SizedBox(
                  height: 7,
                ), // Space between back button and title
                // Page Title
                const PageTitle(text: '아이디 찾기'),

                const SizedBox(
                  height: 42,
                ), // Space between title and result message
                // User ID Card
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: UserIDCard(
                      userName: _userName ?? widget.userName,
                      userId: _userId ?? widget.userId,
                      width: 193,
                      height: 58,
                    ),
                  ),
                ),

                const Spacer(), // Push everything to top
                // Login Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 29),
                  child: LoginButton(text: '로그인하기', onPressed: _handleLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
