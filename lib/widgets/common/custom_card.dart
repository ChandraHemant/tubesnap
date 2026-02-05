import 'package:flutter/material.dart';
import 'package:tubesnap/core/utils/responsive.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final double? borderRadius;
  final bool hasShadow;
  final bool hasBorder;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.gradientColors,
    this.onTap,
    this.borderRadius,
    this.hasShadow = false,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    final radius = borderRadius ?? responsive.rs(20);

    Widget cardContent = Container(
      padding: padding ?? responsive.cardPadding,
      decoration: BoxDecoration(
        color: gradientColors == null ? (color ?? theme.colorScheme.surface) : null,
        gradient: gradientColors != null
            ? LinearGradient(
          colors: gradientColors!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: hasBorder && gradientColors == null
            ? Border.all(color: theme.colorScheme.outline)
            : null,
        boxShadow: hasShadow
            ? [
          BoxShadow(
            color: (gradientColors?.first ?? theme.colorScheme.primary).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: child,
    );

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: cardContent,
      );
    }

    return cardContent;
  }
}