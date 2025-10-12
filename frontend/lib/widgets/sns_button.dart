import 'package:flutter/material.dart';

enum SNSProvider { kakao, google }

class SNSButton extends StatelessWidget {
  final SNSProvider provider;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;

  const SNSButton({
    super.key,
    required this.provider,
    this.onPressed,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: width ?? 50,
        height: height ?? 50,
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    switch (provider) {
      case SNSProvider.kakao:
        return Image.asset(
          'assets/images/social_login/Button_Kakao.png',
          width: width ?? 50,
          height: height ?? 50,
          fit: BoxFit.contain,
        );
      case SNSProvider.google:
        return Image.asset(
          'assets/images/social_login/Button_Google.png',
          width: width ?? 50,
          height: height ?? 50,
          fit: BoxFit.contain,
        );
    }
  }
}
