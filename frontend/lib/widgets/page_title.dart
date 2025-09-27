import 'package:flutter/material.dart';

class PageTitle extends StatelessWidget {
  final String text;
  final double? width;
  final double? height;
  final TextAlign? textAlign;

  const PageTitle({
    Key? key,
    required this.text,
    this.width,
    this.height,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.193,
          color: Color(0xFF5C5C5C),
        ),
        textAlign: textAlign ?? TextAlign.center,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
