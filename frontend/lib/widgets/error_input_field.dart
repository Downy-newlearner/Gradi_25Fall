import 'package:flutter/material.dart';

class ErrorInputField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool hasError;
  final double? width;
  final double? height;

  const ErrorInputField({
    Key? key,
    required this.label,
    required this.placeholder,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.errorText,
    this.hasError = false,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 342,
      height: height ?? (hasError ? 102 : 76),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              color: Colors.white,
              border: hasError
                  ? Border.all(
                      color: const Color(
                        0xFFAC5BF8,
                      ), // Gradient color for error border
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(5),
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
                color: hasError
                    ? const Color(0xFFFF4258)
                    : const Color(0xFFA0A0A0),
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.193,
                  color: hasError
                      ? const Color(0xFFFF4258)
                      : const Color(0xFFA0A0A0),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
              ),
            ),
          ),

          // Error Text
          if (hasError && errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.193,
                color: Color(0xFFAC5BF8), // Gradient color for error text
              ),
            ),
          ],
        ],
      ),
    );
  }
}
