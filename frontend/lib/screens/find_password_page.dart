import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/status_bar.dart';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/labeled_input_field.dart';
import '../widgets/next_button.dart';

class FindPasswordPage extends StatefulWidget {
  const FindPasswordPage({super.key});

  @override
  State<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends State<FindPasswordPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleNext() {
    // TODO: Implement password find logic validation
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _idController.text.isEmpty) {
      Navigator.pushNamed(context, '/find-password-error');
      return;
    }

    // Navigate to verification page
    Navigator.pushNamed(
      context,
      '/find-password-verification',
      arguments: {'userName': _nameController.text},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const StatusBar(),
              const SizedBox(height: 20),
              Row(
                children: [
                  custom.CustomBackButton(onPressed: _handleBack),
                  const SizedBox(width: 20),
                  const PageTitle(text: '비밀번호 찾기', width: 126, height: 24),
                ],
              ),
              const SizedBox(height: 20),
              LabeledInputField(
                label: '이름*',
                placeholder: '이름을 입력해주세요',
                controller: _nameController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 24),
              LabeledInputField(
                label: '이메일*',
                placeholder: '이메일 주소를 입력해주세요',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              LabeledInputField(
                label: '아이디*',
                placeholder: '아이디를 입력해주세요',
                controller: _idController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              NextButton(text: '다음', onPressed: _handleNext),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
