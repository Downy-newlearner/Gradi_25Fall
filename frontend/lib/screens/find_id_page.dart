import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/labeled_input_field.dart';
import '../widgets/next_button.dart';

class FindIDPage extends StatefulWidget {
  const FindIDPage({Key? key}) : super(key: key);

  @override
  State<FindIDPage> createState() => _FindIDPageState();
}

class _FindIDPageState extends State<FindIDPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _handleNext() {
    // TODO: Implement find ID logic validation
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      Navigator.pushNamed(context, '/find-id-error');
      return;
    }

    // Navigate to verification page with user name
    Navigator.pushNamed(
      context,
      '/find-id-verification',
      arguments: {'userName': _nameController.text},
    );
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

              const SizedBox(height: 48), // Space between title and name input
              // Name Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: LabeledInputField(
                  label: '이름*',
                  placeholder: '이름을 입력해주세요',
                  controller: _nameController,
                  keyboardType: TextInputType.text,
                ),
              ),

              const SizedBox(height: 24), // Space between name and email input
              // Email Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: LabeledInputField(
                  label: '이메일*',
                  placeholder: '이메일 주소를 입력해주세요',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),

              const SizedBox(
                height: 140,
              ), // Space between email input and next button
              // Next Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: NextButton(text: '다음', onPressed: _handleNext),
              ),

              const Spacer(), // Push everything to top
              // Keyboard placeholder (would be handled by Flutter's built-in keyboard)
              Container(
                width: 402,
                height: 336, // Approximate keyboard height
                color: Colors.grey.withOpacity(0.1),
                child: const Center(
                  child: Text(
                    'Keyboard Area',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
