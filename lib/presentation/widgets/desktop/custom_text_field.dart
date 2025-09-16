// lib/presentation/widgets/desktop/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool isSmallScreen;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final String? helperText;
  final String? errorText;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final bool autofocus;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.isSmallScreen = false,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.helperText,
    this.errorText,
    this.borderColor,
    this.focusedBorderColor,
    this.autofocus = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _focusNode.addListener(_onFocusChange);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _hasError = widget.errorText != null;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Color _getBorderColor() {
    if (_hasError || widget.errorText != null) {
      return Colors.red[400]!;
    } else if (_isFocused) {
      return widget.focusedBorderColor ?? Colors.blue[500]!;
    } else {
      return widget.borderColor ?? Colors.grey[300]!;
    }
  }

  Color _getLabelColor() {
    if (_hasError || widget.errorText != null) {
      return Colors.red[600]!;
    } else if (_isFocused) {
      return Colors.blue[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                validator: (value) {
                  final result = widget.validator?.call(value);
                  setState(() {
                    _hasError = result != null;
                  });
                  return result;
                },
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                onTap: widget.onTap,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onFieldSubmitted,
                inputFormatters: widget.inputFormatters,
                textCapitalization: widget.textCapitalization,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                style: TextStyle(
                  fontSize: widget.isSmallScreen ? 14 : 16,
                  color: widget.enabled ? Colors.grey[800] : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hintText,
                  labelStyle: TextStyle(
                    fontSize: widget.isSmallScreen ? 14 : 16,
                    color: _getLabelColor(),
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: TextStyle(
                    fontSize: widget.isSmallScreen ? 14 : 16,
                    color: Colors.grey[400],
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Transform.scale(
                          scale: _isFocused ? 1.1 : 1.0,
                          child: Icon(
                            widget.prefixIcon,
                            size: widget.isSmallScreen ? 20 : 24,
                            color: _getLabelColor(),
                          ),
                        )
                      : null,
                  suffixIcon: widget.suffixIcon,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getBorderColor(),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getBorderColor(),
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red[400]!, width: 2.0),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: widget.isSmallScreen ? 14 : 16,
                    vertical: widget.isSmallScreen ? 14 : 16,
                  ),
                  filled: true,
                  fillColor: widget.enabled
                      ? (_isFocused
                            ? Colors.blue[50]?.withOpacity(0.3)
                            : Colors.white)
                      : Colors.grey[50],
                  helperText: widget.helperText,
                  helperStyle: TextStyle(
                    fontSize: widget.isSmallScreen ? 12 : 13,
                    color: Colors.grey[600],
                  ),
                  errorText: widget.errorText,
                  errorStyle: TextStyle(
                    fontSize: widget.isSmallScreen ? 12 : 13,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
