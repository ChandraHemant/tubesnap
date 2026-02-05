import 'package:flutter/material.dart';
import 'package:tubesnap/core/utils/responsive.dart';

class LoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return SizedBox(
      width: size ?? responsive.rs(40),
      height: size ?? responsive.rs(40),
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(color ?? theme.colorScheme.primary),
      ),
    );
  }
}