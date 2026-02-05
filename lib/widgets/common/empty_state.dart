import 'package:flutter/material.dart';
import 'package:tubesnap/core/utils/responsive.dart';
import 'package:tubesnap/widgets/common/custom_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Center(
      child: Padding(
        padding: responsive.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(responsive.rs(28)),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: responsive.iconSize(mobile: 56, desktop: 72),
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            SizedBox(height: responsive.rs(24)),
            Text(
              title,
              style: TextStyle(
                fontSize: responsive.sp(20),
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: responsive.rs(8)),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: responsive.sp(14),
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: responsive.rs(24)),
              CustomButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                icon: Icons.add_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}