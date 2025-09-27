import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import '../widgets/app_logo.dart';
import '../widgets/input_field.dart';
import '../widgets/login_button.dart';
import '../widgets/sns_button.dart';
import '../widgets/links_section.dart';
import '../widgets/sns_divider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Handle login logic here
    print('Login attempted with username: ${_usernameController.text}');
  }

  void _handleKakaoLogin() {
    // Handle Kakao login logic here
    print('Kakao login attempted');
  }

  void _handleGoogleLogin() {
    // Handle Google login logic here
    print('Google login attempted');
  }

  void _handleSignUp() {
    Navigator.pushNamed(context, '/signup');
  }

  void _handleFindID() {
    Navigator.pushNamed(context, '/find-id');
  }

  void _handleFindPW() {
    Navigator.pushNamed(context, '/find-password');
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

              const SizedBox(height: 110), // Space between status bar and logo
              // App Logo
              const AppLogo(),

              const SizedBox(height: 98), // Space between logo and input fields
              // Input Fields
              Container(
                width: 342,
                height: 120,
                child: Column(
                  children: [
                    // Username Input
                    InputField(
                      placeholder: '아이디',
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                    ),

                    const SizedBox(height: 20),

                    // Password Input
                    InputField(
                      placeholder: '비밀번호',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 35,
              ), // Space between input fields and login button
              // Login Button
              LoginButton(text: '로그인', onPressed: _handleLogin),

              const SizedBox(
                height: 157,
              ), // Space between login button and links
              // Links Section
              LinksSection(
                onSignUp: _handleSignUp,
                onFindID: _handleFindID,
                onFindPW: _handleFindPW,
              ),

              const SizedBox(height: 57), // Space between links and SNS divider
              // SNS Divider
              const SNSDivider(),

              const SizedBox(
                height: 50,
              ), // Space between divider and SNS buttons
              // SNS Buttons
              Container(
                width: 123,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kakao Button
                    SNSButton(
                      provider: SNSProvider.kakao,
                      onPressed: _handleKakaoLogin,
                    ),

                    // Google Button
                    SNSButton(
                      provider: SNSProvider.google,
                      onPressed: _handleGoogleLogin,
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
}
