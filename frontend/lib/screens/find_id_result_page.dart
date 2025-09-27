import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/user_id_card.dart';
import '../widgets/login_button.dart';

class FindIDResultPage extends StatefulWidget {
  final String userName;
  final String userId;

  const FindIDResultPage({
    Key? key,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  @override
  State<FindIDResultPage> createState() => _FindIDResultPageState();
}

class _FindIDResultPageState extends State<FindIDResultPage> {
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
        child: Container(
          width: 402,
          height: 874,
          child: Column(
            children: [
              // Status Bar
              const StatusBar(),

              const SizedBox(
                height: 24,
              ), // Space between status bar and back button
              // Back Button
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: custom.CustomBackButton(onPressed: _handleBack),
                ),
              ),

              const SizedBox(height: 7), // Space between back button and title
              // Page Title
              const PageTitle(text: '아이디 찾기', width: 92, height: 24),

              const SizedBox(
                height: 42,
              ), // Space between title and result message
              // User ID Card
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: UserIDCard(
                    userName: widget.userName,
                    userId: widget.userId,
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
    );
  }
}
