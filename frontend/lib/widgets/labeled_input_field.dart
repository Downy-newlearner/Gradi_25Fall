import 'package:flutter/material.dart';

class LabeledInputField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final double? width;
  final double? height;
  final bool isError;
  final String? errorMessage;

  const LabeledInputField({
    super.key,
    required this.label,
    required this.placeholder,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.width,
    this.height,
    this.isError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 342,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.193,
              color: Color(0xFF5C5C5C),
            ),
          ),

          const SizedBox(height: 8),

          // Input Field
          Container(
            width: 342,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(5),
              border: isError
                  ? Border.all(color: const Color(0xFFFF4258), width: 1)
                  : null,
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.193,
                color: isError
                    ? const Color(0xFFFF4258)
                    : const Color(0xFFA0A0A0),
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.193,
                  color: Color(0xFFA0A0A0),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
              ),
            ),
          ),

          // Error Message
          if (isError && errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.33,
                color: Color(0xFFFF4258),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
