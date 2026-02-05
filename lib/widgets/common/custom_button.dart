import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

enum ButtonType { primary, secondary, outline, text, gradient }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final List<Color>? gradientColors;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    // Size configurations
    final sizeConfig = _getSizeConfig(responsive);

    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: sizeConfig['iconSize'],
            height: sizeConfig['iconSize'],
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_getTextColor(theme)),
            ),
          )
        else if (icon != null)
          Icon(icon, size: sizeConfig['iconSize']),
        if ((icon != null || isLoading) && text.isNotEmpty)
          SizedBox(width: responsive.rs(8)),
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              fontSize: sizeConfig['fontSize'],
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    // Gradient button
    if (type == ButtonType.gradient) {
      return Container(
        width: isFullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors ?? [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
          borderRadius: BorderRadius.circular(sizeConfig['borderRadius']),
          boxShadow: [
            BoxShadow(
              color: (gradientColors?.first ?? theme.colorScheme.primary).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: sizeConfig['padding'],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(sizeConfig['borderRadius']),
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    // Other button types
    switch (type) {
      case ButtonType.primary:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: sizeConfig['padding'],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sizeConfig['borderRadius']),
              ),
              elevation: 0,
            ),
            child: buttonChild,
          ),
        );

      case ButtonType.secondary:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: sizeConfig['padding'],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sizeConfig['borderRadius']),
              ),
              elevation: 0,
            ),
            child: buttonChild,
          ),
        );

      case ButtonType.outline:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: sizeConfig['padding'],
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sizeConfig['borderRadius']),
              ),
            ),
            child: buttonChild,
          ),
        );

      case ButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: sizeConfig['padding'],
          ),
          child: buttonChild,
        );

      default:
        return const SizedBox();
    }
  }

  Map<String, dynamic> _getSizeConfig(Responsive responsive) {
    switch (size) {
      case ButtonSize.small:
        return {
          'padding': EdgeInsets.symmetric(horizontal: responsive.rs(16), vertical: responsive.rs(8)),
          'fontSize': responsive.sp(12),
          'iconSize': responsive.rs(16),
          'borderRadius': responsive.rs(10),
        };
      case ButtonSize.medium:
        return {
          'padding': EdgeInsets.symmetric(horizontal: responsive.rs(24), vertical: responsive.rs(14)),
          'fontSize': responsive.sp(14),
          'iconSize': responsive.rs(20),
          'borderRadius': responsive.rs(14),
        };
      case ButtonSize.large:
        return {
          'padding': EdgeInsets.symmetric(horizontal: responsive.rs(32), vertical: responsive.rs(18)),
          'fontSize': responsive.sp(16),
          'iconSize': responsive.rs(24),
          'borderRadius': responsive.rs(18),
        };
    }
  }

  Color _getTextColor(ThemeData theme) {
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
      case ButtonType.gradient:
        return Colors.white;
      case ButtonType.outline:
      case ButtonType.text:
        return theme.colorScheme.primary;
    }
  }
}