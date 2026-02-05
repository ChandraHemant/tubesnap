import 'package:flutter/material.dart';
import 'package:tubesnap/core/utils/responsive.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: responsive.sp(14),
              fontWeight: FontWeight.w600,
              color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: responsive.rs(8)),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.enabled ? theme.colorScheme.surface : theme.colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(responsive.rs(16)),
            border: Border.all(
              color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.outline,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            enabled: widget.enabled,
            textInputAction: widget.textInputAction,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: responsive.sp(14),
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                widget.prefixIcon,
                color: _isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                size: responsive.iconSize(mobile: 20),
              )
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: Icon(
                  _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: responsive.iconSize(mobile: 20),
                ),
              )
                  : widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(responsive.rs(16)),
            ),
          ),
        ),
      ],
    );
  }
}
