import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerificationCodeInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final double? width;
  final double? height;

  const VerificationCodeInput({
    Key? key,
    this.length = 4,
    this.onChanged,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  String _code = '';

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String value, int index) {
    if (value.length == 1) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else if (value.isEmpty) {
      // Move to previous field
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // Update code
    _code = _controllers.map((controller) => controller.text).join();
    widget.onChanged?.call(_code);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? 248,
      height: widget.height ?? 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (index) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _controllers[index].text.isNotEmpty
                  ? Colors.white
                  : const Color(0xFFF3F3F3),
              border: _controllers[index].text.isNotEmpty
                  ? Border.all(color: const Color(0xFF666EDE), width: 2)
                  : null,
              borderRadius: BorderRadius.circular(5),
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              maxLength: 1,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C5C5C),
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => _onTextChanged(value, index),
            ),
          );
        }),
      ),
    );
  }
}
