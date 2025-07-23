import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// حقل إدخال رمز التحقق المخصص
class CodeInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isValid;
  final VoidCallback? onChanged;
  final VoidCallback? onComplete;
  final VoidCallback? onBackspace;
  final Function(String, int)? onPaste;
  final int index;

  const CodeInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.index,
    this.isValid = true,
    this.onChanged,
    this.onComplete,
    this.onBackspace,
    this.onPaste,
  });

  @override
  State<CodeInputField> createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<CodeInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade300,
      end: Colors.blue.shade400,
    ).animate(_animationController);
  }

  void _setupListeners() {
    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    widget.controller.addListener(() {
      if (widget.controller.text.length == 1) {
        widget.onComplete?.call();
      }
      widget.onChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 45.w,
            height: 55.h,
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    widget.isValid
                        ? _colorAnimation.value ?? Colors.grey.shade300
                        : Colors.red.shade400,
                width: 2.w,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color:
                  widget.controller.text.isNotEmpty
                      ? Colors.blue.shade50
                      : Colors.grey.shade50,
              boxShadow:
                  widget.focusNode.hasFocus
                      ? [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ]
                      : [],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                // كشف اللصق (إذا كان النص أطول من رقم واحد)
                if (value.length > 1) {
                  widget.onPaste?.call(value, widget.index);
                  return;
                }

                // استدعاء onComplete عند إدخال رقم
                if (value.length == 1) {
                  widget.onComplete?.call();
                } else if (value.isEmpty && widget.index > 0) {
                  // الرجوع للحقل السابق عند المسح
                  widget.onBackspace?.call();
                }

                widget.onChanged?.call();
              },
              onEditingComplete: () {
                // عدم فعل شيء لمنع التحرك غير المرغوب فيه
              },
              onSubmitted: (value) {
                // عدم فعل شيء لمنع التحرك غير المرغوب فيه
              },
              // إضافة استماع لزر المسح (backspace)
              onTap: () {
                if (widget.controller.text.isEmpty && widget.index > 0) {
                  widget.onBackspace?.call();
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
